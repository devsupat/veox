// engine/main.js
//
// Node.js sidecar — the browser automation heart of Veox Studio.
//
// Protocol: newline-delimited JSON over stdin/stdout.
//   Flutter → Node: { id, command, params }
//   Node    → Flutter (result): { id, type: 'result', status: 'success'|'error', data, error }
//   Node    → Flutter (log):    { type: 'log',    level, msg }
//   Node    → Flutter (system): { type: 'system', msg }
//
// Commands:
//   ping, open_browser, close_browser, navigate_to, fill_input,
//   click_element, wait_for_element, run_script, get_cookies, set_cookies,
//   screenshot, generate_video

'use strict';

const readline = require('readline');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { chromium } = require('playwright-extra');
const stealth = require('puppeteer-extra-plugin-stealth');
const { v4: uuidv4 } = require('uuid');

// Apply stealth before any browser launch.
chromium.use(stealth());

// ── IPC Setup ──────────────────────────────────────────────────────────────
const rl = readline.createInterface({
  input: process.stdin,
  terminal: false,
});

const send = (data) => {
  process.stdout.write(JSON.stringify(data) + '\n');
};

const log = (level, msg) => send({ type: 'log', level, msg });
const info = (msg) => log('info', msg);
const warn = (msg) => log('warn', msg);
const err = (msg) => log('error', msg);

// ── State ───────────────────────────────────────────────────────────────────
/** @type {Map<string, import('playwright').BrowserContext>} */
const contexts = new Map();  // profileId → BrowserContext

/** @type {Map<string, import('playwright').Page>} */
const pages = new Map();     // profileId → active Page

// ── Command Router ──────────────────────────────────────────────────────────
rl.on('line', async (line) => {
  if (!line || !line.trim()) return;

  let msg;
  try {
    msg = JSON.parse(line);
  } catch (e) {
    err(`JSON parse error: ${e.message}`);
    return;
  }

  const { id, command, params = {} } = msg;

  info(`Received [${id}] ${command}`);

  try {
    const data = await dispatch(command, params, id);
    send({ id, type: 'result', status: 'success', data });
  } catch (e) {
    err(`[${id}] ${command} failed: ${e.message}`);
    send({ id, type: 'result', status: 'error', error: e.message });
  }
});

// ── Dispatch ────────────────────────────────────────────────────────────────
async function dispatch(command, params, taskId) {
  switch (command) {

    // Connectivity
    case 'ping':
      return { pong: true, time: Date.now() };

    // Browser lifecycle
    case 'open_browser': return openBrowser(params);
    case 'close_browser': return closeBrowser(params);

    // Navigation & interaction
    case 'navigate_to': return navigateTo(params);
    case 'fill_input': return fillInput(params);
    case 'click_element': return clickElement(params);
    case 'wait_for_element': return waitForElement(params);
    case 'run_script': return runScript(params);

    // Session persistence
    case 'get_cookies': return getCookies(params);
    case 'set_cookies': return setCookies(params);

    // Capture
    case 'screenshot': return screenshot(params, taskId);

    // High-level automation
    case 'generate_video': return generateVideo(params, taskId);

    default:
      throw new Error(`Unknown command: ${command}`);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function profileKey(params) {
  return params.profileId || 'default';
}

function getContext(params) {
  const key = profileKey(params);
  const ctx = contexts.get(key);
  if (!ctx) throw new Error(`No browser open for profile "${key}". Call open_browser first.`);
  return ctx;
}

async function getPage(params) {
  const key = profileKey(params);
  if (!pages.has(key)) {
    const ctx = getContext(params);
    const page = await ctx.newPage();
    pages.set(key, page);
    page.on('close', () => pages.delete(key));
  }
  return pages.get(key);
}

// ── Browser Lifecycle ────────────────────────────────────────────────────────

async function openBrowser({ headless = true, profileId = 'default', userDataDir, proxyServer } = {}) {
  if (contexts.has(profileId)) {
    return { status: 'already_open', profileId };
  }

  const launchArgs = [
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-blink-features=AutomationControlled',
  ];
  if (proxyServer) launchArgs.push(`--proxy-server=${proxyServer}`);

  const options = {
    headless,
    args: launchArgs,
    viewport: { width: 1280, height: 720 },
  };

  let ctx;
  if (userDataDir) {
    // Persistent context preserves cookies, localStorage, and login state.
    ctx = await chromium.launchPersistentContext(userDataDir, options);
  } else {
    const browser = await chromium.launch(options);
    ctx = await browser.newContext();
  }

  contexts.set(profileId, ctx);
  info(`Browser opened for profile "${profileId}" (headless=${headless})`);
  return { status: 'opened', profileId, pid: process.pid };
}

async function closeBrowser({ profileId = 'default' } = {}) {
  const ctx = contexts.get(profileId);
  if (!ctx) return { status: 'not_open' };

  const page = pages.get(profileId);
  if (page && !page.isClosed()) await page.close();
  pages.delete(profileId);

  await ctx.close();
  contexts.delete(profileId);
  info(`Browser closed for profile "${profileId}"`);
  return { status: 'closed', profileId };
}

// ── Navigation ───────────────────────────────────────────────────────────────

async function navigateTo({ url, profileId, waitUntil = 'domcontentloaded', timeout = 30000 } = {}) {
  if (!url) throw new Error('"url" param required.');
  const page = await getPage({ profileId });
  await page.goto(url, { waitUntil, timeout });
  return { url: page.url(), title: await page.title() };
}

// ── Interaction ──────────────────────────────────────────────────────────────

async function fillInput({ selector, value, profileId, clear = true } = {}) {
  if (!selector || value === undefined) throw new Error('"selector" and "value" required.');
  const page = await getPage({ profileId });
  if (clear) await page.fill(selector, '');
  await page.fill(selector, value);
  return { selector, filled: true };
}

async function clickElement({ selector, profileId, timeout = 5000 } = {}) {
  if (!selector) throw new Error('"selector" required.');
  const page = await getPage({ profileId });
  await page.click(selector, { timeout });
  return { selector, clicked: true };
}

async function waitForElement({ selector, profileId, timeout = 30000, state = 'visible' } = {}) {
  if (!selector) throw new Error('"selector" required.');
  const page = await getPage({ profileId });
  try {
    await page.waitForSelector(selector, { timeout, state });
    return { found: true, selector };
  } catch (_) {
    return { found: false, selector };
  }
}

async function runScript({ script, profileId } = {}) {
  if (!script) throw new Error('"script" required.');
  const page = await getPage({ profileId });
  const result = await page.evaluate(script);
  return { result };
}

// ── Session ──────────────────────────────────────────────────────────────────

async function getCookies({ profileId, url } = {}) {
  const ctx = getContext({ profileId });
  const cookies = url
    ? await ctx.cookies([url])
    : await ctx.cookies();
  return { cookies };
}

async function setCookies({ profileId, cookies } = {}) {
  if (!Array.isArray(cookies)) throw new Error('"cookies" must be an array.');
  const ctx = getContext({ profileId });
  await ctx.addCookies(cookies);
  return { set: cookies.length };
}

// ── Screenshot ───────────────────────────────────────────────────────────────

async function screenshot({ profileId, outputDir } = {}, taskId) {
  const page = await getPage({ profileId });
  const dir = outputDir || path.join(os.homedir(), 'Documents', 'VEOX', 'screenshots');
  fs.mkdirSync(dir, { recursive: true });
  const filePath = path.join(dir, `${taskId || uuidv4()}.png`);
  await page.screenshot({ path: filePath, fullPage: false });
  return { outputPath: filePath };
}

// ── High-level: Video Generation ─────────────────────────────────────────────

/**
 * Orchestrates the full prompt → video generation flow.
 * Currently supports Veo3 via Google Labs.
 */
async function generateVideo({ prompt, platform = 'veo3', profileId = 'default',
  outputDir, maxWaitMs = 300000 } = {}, taskId) {
  if (!prompt) throw new Error('"prompt" required.');

  info(`generate_video [${platform}]: "${prompt.slice(0, 60)}…"`);

  switch (platform.toLowerCase()) {
    case 'veo3':
      return generateVeo3(prompt, profileId, outputDir, taskId, maxWaitMs);
    case 'grok':
      return generateGrok(prompt, profileId, outputDir, taskId, maxWaitMs);
    default:
      throw new Error(`Unknown platform: ${platform}`);
  }
}

// ── Veo3 ─────────────────────────────────────────────────────────────────────

const VEO3_URL = 'https://labs.google.com/veo';

async function generateVeo3(prompt, profileId, outputDir, taskId, maxWaitMs) {
  const page = await getPage({ profileId });

  // Step 1: Navigate (skip if already there)
  if (!page.url().includes('labs.google.com')) {
    info('Navigating to Veo3…');
    await page.goto(VEO3_URL, { waitUntil: 'networkidle', timeout: 30000 });
  }

  // Step 2: Check login
  const isLoggedIn = await _checkGoogleLogin(page);
  if (!isLoggedIn) {
    // Signal to Flutter that manual login is required.
    send({ type: 'system', msg: 'needs_login', profileId });
    info('Awaiting login…');
    // Wait up to 3 minutes for the user to log in.
    await page.waitForFunction(
      () => document.querySelector('[data-email]') !== null ||
        document.cookie.includes('SID='),
      { timeout: 180000 }
    );
    info('Login detected, resuming.');
  }

  // Step 3: Fill prompt
  await page.waitForSelector('textarea, [data-testid="prompt-input"]',
    { timeout: 10000 });
  const promptSelector = 'textarea, [data-testid="prompt-input"]';
  await page.fill(promptSelector, prompt);

  // Step 4: Submit
  const submitSel = '[data-testid="generate-button"], button[aria-label*="Generate"]';
  await page.waitForSelector(submitSel, { timeout: 5000 });
  await page.click(submitSel);
  info('Generation submitted. Polling…');

  // Step 5: Poll for result
  const outputPath = await _pollForVideo(page, outputDir, taskId, maxWaitMs, 'veo3');
  return { outputPath, platform: 'veo3' };
}

// ── Grok ─────────────────────────────────────────────────────────────────────

const GROK_URL = 'https://grok.x.ai';

async function generateGrok(prompt, profileId, outputDir, taskId, maxWaitMs) {
  const page = await getPage({ profileId });

  if (!page.url().includes('grok.x.ai')) {
    await page.goto(GROK_URL, { waitUntil: 'networkidle', timeout: 30000 });
  }

  await page.waitForSelector('textarea', { timeout: 10000 });
  await page.fill('textarea', prompt);

  const submitSel = 'button[type="submit"], button[aria-label*="send"]';
  await page.click(submitSel);
  info('Grok prompt submitted. Polling…');

  const outputPath = await _pollForVideo(page, outputDir, taskId, maxWaitMs, 'grok');
  return { outputPath, platform: 'grok' };
}

// ── Polling ───────────────────────────────────────────────────────────────────

/**
 * Generic video result poller. Watches DOM for a downloadable video element.
 * Saves the video to disk and returns the local path.
 */
async function _pollForVideo(page, outputDir, taskId, maxWaitMs, platform) {
  const pollInterval = 5000;
  const deadline = Date.now() + maxWaitMs;

  const dir = outputDir || path.join(os.homedir(), 'Documents', 'VEOX', 'videos');
  fs.mkdirSync(dir, { recursive: true });

  while (Date.now() < deadline) {
    // Look for a download link or a <video> element with a src
    const videoUrl = await page.evaluate(() => {
      const video = document.querySelector('video[src]');
      if (video) return video.src;
      const link = document.querySelector('a[download][href*=".mp4"], a[href*="output"]');
      if (link) return link.href;
      return null;
    });

    if (videoUrl) {
      info(`Video found: ${videoUrl}`);
      const filename = `${taskId || uuidv4()}.mp4`;
      const outputPath = path.join(dir, filename);

      // Download via fetch inside the page context (avoids CORS on same-origin)
      await page.evaluate(async ({ url, fp }) => {
        const res = await fetch(url);
        const buffer = await res.arrayBuffer();
        const arr = new Uint8Array(buffer);
        // Write signal — actual file write is below via CDP
      }, { url: videoUrl, fp: outputPath });

      // Use CDP to download the file properly
      const client = await page.context().newCDPSession(page);
      await client.send('Page.setDownloadBehavior', {
        behavior: 'allow',
        downloadPath: dir,
      });
      await page.evaluate((url) => { window.location.href = url; }, videoUrl);
      await page.waitForTimeout(3000); // Give the file time to download

      return outputPath;
    }

    // Check for error state
    const hasError = await page.evaluate(() => {
      return document.body.innerText.includes('generation failed') ||
        document.body.innerText.includes('Error generating');
    });
    if (hasError) throw new Error(`${platform} reported a generation error.`);

    info(`Still generating… (${Math.round((deadline - Date.now()) / 1000)}s remaining)`);
    await page.waitForTimeout(pollInterval);
  }

  throw new Error(`Video generation timed out after ${maxWaitMs / 1000}s.`);
}

async function _checkGoogleLogin(page) {
  return page.evaluate(() => {
    return document.querySelector('[data-email]') !== null ||
      document.cookie.split(';').some(c => c.trim().startsWith('SID='));
  }).catch(() => false);
}

// ── Startup ───────────────────────────────────────────────────────────────────
send({ type: 'system', msg: 'Node Engine Ready', version: '2.0.0' });
