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
//   screenshot, generate_video, job_start, job_cancel

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

// ── Debug Mode ─────────────────────────────────────────────────────────────
const DEBUG = process.env.VEOX_DEBUG === '1' || process.env.VEOX_DEBUG === 'true';
if (DEBUG) info('DEBUG mode enabled — artifacts will be saved on failure.');

// ── State ───────────────────────────────────────────────────────────────────
/** @type {Map<string, import('playwright').BrowserContext>} */
const contexts = new Map();  // profileId → BrowserContext

/** @type {Map<string, import('playwright').Page>} */
const pages = new Map();     // profileId → active Page

/** @type {Map<string, boolean>} */
const activeJobs = new Map(); // taskId → isCancelled

/** @type {Map<string, AbortController>} */
const activeControllers = new Map(); // taskId → AbortController

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
    send({
      id,
      type: 'result',
      status: 'error',
      error: e.message,
      retryable: e.retryable !== false // Default to true unless explicitly false
    });
  }
});

// ── Dispatch ────────────────────────────────────────────────────────────────
async function dispatch(command, params, taskId) {
  switch (command) {

    // Connectivity
    case 'ping':
      return { pong: true, time: Date.now() };

    // Diagnostics
    case 'engine.doctor': return engineDoctor();

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

    // VEOX Background Jobs
    case 'job_start': return jobStart(params, taskId);
    case 'job_cancel': return jobCancel(params, taskId);

    default:
      throw new Error(`Unknown command: ${command}`);
  }
}

// ── VEOX Background Jobs ─────────────────────────────────────────────────────

async function jobCancel(params, taskId) {
  const targetId = params.taskId;
  if (!targetId) throw new Error('"taskId" param required for job_cancel.');
  activeJobs.set(targetId, true);

  const controller = activeControllers.get(targetId);
  if (controller) {
    controller.abort(new Error(`Job ${targetId} was cancelled.`));
    info(`Aborted controller for job ${targetId}`);
  }

  info(`Job cancel requested for ${targetId}`);
  return { cancelled: true, targetId };
}

async function jobStart(params, taskId) {
  const { type, taskId: jobId } = params;
  if (!type) throw new Error('"type" param required for job_start.');
  if (!jobId) throw new Error('"taskId" param required for job_start.');

  // Reset cancellation flag
  activeJobs.set(jobId, false);
  const controller = new AbortController();
  activeControllers.set(jobId, controller);

  try {
    switch (type) {
      case 'browser_screenshot':
        return await _runBrowserScreenshot(params, jobId, controller.signal);
      case 'browser_generate_video':
        return await _runBrowserVideo(params, jobId, controller.signal);
      case 'open_browser_test':
        return await _runOpenBrowserTest(params, jobId, controller.signal);
      default:
        throw new Error(`Unknown job type: ${type}`);
    }
  } catch (e) {
    const isRetryable = e.retryable !== undefined ? e.retryable : true;
    throw Object.assign(e, { retryable: isRetryable });
  } finally {
    activeJobs.delete(jobId);
    activeControllers.delete(jobId);
  }
}

function _checkCancel(jobId) {
  if (activeJobs.get(jobId)) {
    throw Object.assign(
      new Error(`Job ${jobId} was cancelled.`),
      { retryable: false }
    );
  }
}

function emitProgress(jobId, stage, data = {}) {
  info(`[state] ${jobId} → ${stage}`);
  send({ type: 'event', id: jobId, stage, ...data });
}

/**
 * Captures a screenshot + page HTML for debugging when DEBUG is enabled.
 * Safe to call — errors are swallowed so they never mask the real failure.
 */
async function debugCapture(page, outputPath, jobId, stage) {
  if (!DEBUG || !page) return;
  try {
    const dir = path.join(path.dirname(outputPath), 'debug');
    fs.mkdirSync(dir, { recursive: true });
    const base = `${jobId}_${stage}`;
    await page.screenshot({ path: path.join(dir, `${base}.png`), fullPage: true });
    const html = await page.content();
    fs.writeFileSync(path.join(dir, `${base}.html`), html, 'utf8');
    info(`[debug] saved artifacts for ${base}`);
  } catch (e) {
    warn(`[debug] capture failed: ${e.message}`);
  }
}

// ── Engine Doctor ─────────────────────────────────────────────────────────────

/**
 * Diagnostics command: callable as engine.doctor from Flutter.
 * Returns Node/Playwright/chromium info and a brief headed canary launch.
 */
async function engineDoctor() {
  const result = {
    node_version: process.version,
    platform: process.platform,
    arch: process.arch,
    cwd: process.cwd(),
    env_PLAYWRIGHT_BROWSERS_PATH: process.env.PLAYWRIGHT_BROWSERS_PATH || '(not set)',
    playwright_version: null,
    chromium_executable_path: null,
    canLaunchHeaded: false,
    errors: [],
  };

  // 1. Playwright version
  try {
    const pw = require('playwright/package.json');
    result.playwright_version = pw.version;
  } catch (e) {
    result.errors.push(`playwright version check: ${e.message}`);
  }

  // 2. Chromium executable path
  try {
    const { chromium: rawChromium } = require('playwright');
    result.chromium_executable_path = rawChromium.executablePath();
  } catch (e) {
    result.errors.push(`executablePath: ${e.message}`);
  }

  // 3. Attempt headed canary launch (10s timeout)
  let testCtx = null;
  try {
    const { chromium: rawChromium } = require('playwright');
    testCtx = await rawChromium.launchPersistentContext(
      path.join(os.tmpdir(), 'veox_doctor_profile'),
      {
        headless: false,
        args: ['--no-first-run', '--no-default-browser-check', '--disable-dev-shm-usage'],
        timeout: 10000,
      }
    );
    result.canLaunchHeaded = true;
    info('[doctor] ✅ Headed browser launched successfully.');
  } catch (e) {
    result.errors.push(`canLaunchHeaded failed: ${e.message}`);
    err(`[doctor] ❌ Headed launch failed: ${e.message}`);
  } finally {
    if (testCtx) { try { await testCtx.close(); } catch (_) { } }
  }

  return result;
}

// ── Open Browser Test Workflow ─────────────────────────────────────────────────

/**
 * Minimal repro: opens a URL in a headed browser for N seconds.
 * Use to verify browser visibility independently of any target site.
 */
async function _runOpenBrowserTest(params, jobId, signal) {
  const testProfileId = `__browser_test_${jobId}`;
  const testUrl = params.url || 'https://labs.google/fx/tools/flow';
  const durationMs = (params.durationSeconds || 30) * 1000;

  emitProgress(jobId, 'open');
  info(`[browser_test] Opening ${testUrl} in headed mode for ${durationMs / 1000}s...`);

  await openBrowser({
    profileId: testProfileId,
    headless: false,
    userDataDir: path.join(os.tmpdir(), 'veox_browser_test'),
  });
  _checkCancel(jobId);

  emitProgress(jobId, 'navigate');
  const page = await getPage({ profileId: testProfileId });
  await page.goto(testUrl, { waitUntil: 'load', timeout: 15000 });
  const title = await page.title();
  info(`[browser_test] ✅ Browser visible — title: "${title}"`);

  emitProgress(jobId, 'waiting', { message: `Browser open for ${durationMs / 1000}s. Close it or wait.` });

  // Wait for duration or cancellation
  const waitPromise = page.waitForTimeout(durationMs);
  const abortPromise = new Promise((_, reject) => {
    if (!signal) return;
    if (signal.aborted) return reject(signal.reason);
    signal.addEventListener('abort', () => reject(signal.reason), { once: true });
  });
  try {
    await Promise.race([waitPromise, abortPromise]);
  } catch (_) {
    info('[browser_test] Test cancelled early.');
  }

  emitProgress(jobId, 'done');
  await closeBrowser({ profileId: testProfileId });
  return { status: 'success', url: testUrl, title };
}

async function _runBrowserScreenshot(params, jobId, signal) {
  const FLOW_URL = 'https://labs.google/fx/tools/flow';
  const { profileId = 'default', url = FLOW_URL, outputPath } = params;
  if (!outputPath) throw Object.assign(new Error('"outputPath" required for browser_screenshot.'), { retryable: false });

  // 1. Open
  emitProgress(jobId, 'open');
  await openBrowser({ profileId, headless: false, userDataDir: path.join(os.homedir(), 'Documents', 'VEOX', 'profiles', profileId) });
  _checkCancel(jobId);

  // 2. Navigate
  const targetUrl = url || FLOW_URL;
  emitProgress(jobId, 'navigate', { url: targetUrl });
  const page = await getPage({ profileId });
  try {
    await page.goto(targetUrl, { waitUntil: 'load', timeout: 30000 });
  } catch (e) {
    throw Object.assign(new Error(`Navigation failed: ${e.message}`), { retryable: true });
  }
  _checkCancel(jobId);

  // 3. Login Check
  emitProgress(jobId, 'login_check');
  const needsLogin = await page.evaluate(() => {
    return document.querySelector('input[type="email"]') !== null ||
      document.body.innerText.includes('Sign in');
  });

  if (needsLogin) {
    send({ type: 'event', action: 'needs_login', profileId, id: jobId });
    info(`[${jobId}] Browser paused at ${targetUrl}, waiting for manual login...`);
    return { status: 'paused_needs_login', profileId };
  }

  // 4. Screenshot
  emitProgress(jobId, 'screenshot');
  await page.waitForTimeout(2000); // Let UI settle
  _checkCancel(jobId);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  await page.screenshot({ path: outputPath, fullPage: true });

  // 5. Done
  emitProgress(jobId, 'done', { outputPath });
  return { status: 'success', outputPath };
}

async function _runBrowserVideo(params, jobId, signal) {
  const FLOW_URL = 'https://labs.google/fx/tools/flow';
  const { profileId = 'default', url = FLOW_URL, prompt, outputPath } = params;
  if (!prompt) throw Object.assign(new Error('"prompt" required.'), { retryable: false });
  if (!outputPath) throw Object.assign(new Error('"outputPath" required.'), { retryable: false });

  // 1. Open
  emitProgress(jobId, 'open');
  await openBrowser({ profileId, headless: false, userDataDir: path.join(os.homedir(), 'Documents', 'VEOX', 'profiles', profileId) });
  _checkCancel(jobId);
  if (signal?.aborted) throw signal.reason;

  // 2. Navigate
  emitProgress(jobId, 'navigate', { url });
  let page = await getPage({ profileId });
  try {
    await page.goto(url, { waitUntil: 'load', timeout: 30000 });
  } catch (e) {
    throw Object.assign(new Error(`Navigation failed: ${e.message}`), { retryable: true });
  }
  _checkCancel(jobId);
  if (signal?.aborted) throw signal.reason;

  // 3. Login Check
  emitProgress(jobId, 'login_check');
  const needsLogin = await page.evaluate(() => {
    return document.querySelector('input[type="email"]') !== null ||
      document.body.innerText.includes('Sign in') ||
      document.body.innerText.includes('Sign In');
  });

  if (needsLogin) {
    send({ type: 'event', action: 'needs_login', profileId, id: jobId });
    info(`[${jobId}] Browser paused, waiting for manual login...`);
    return { status: 'paused_needs_login', profileId };
  }

  // 4. Prompt Fill
  emitProgress(jobId, 'prompt_fill');
  try {
    // Robust selector: try placeholder, then generic textarea
    let promptInput = page.getByPlaceholder(/Describe/i).first();
    if (await promptInput.count() === 0) {
      promptInput = page.locator('textarea').first();
    }
    await promptInput.waitFor({ state: 'visible', timeout: 15000 });
    await promptInput.fill(prompt);
  } catch (e) {
    await debugCapture(page, outputPath, jobId, 'prompt_fill_error');
    throw Object.assign(new Error(`Failed to find/fill prompt input: ${e.message}`), { retryable: true });
  }
  _checkCancel(jobId);
  if (signal?.aborted) throw signal.reason;

  // 5. Submit
  emitProgress(jobId, 'submit');
  try {
    // Robust selector: role button Generate, or text Generate, or a common generate button class
    let generateBtn = page.getByRole('button', { name: /Generate/i }).first();
    if (await generateBtn.count() === 0) {
      generateBtn = page.locator('button:has-text("Generate")').first();
    }
    await generateBtn.waitFor({ state: 'visible', timeout: 5000 });
    await generateBtn.click();
  } catch (e) {
    await debugCapture(page, outputPath, jobId, 'submit_error');
    throw Object.assign(new Error(`Failed to click generate: ${e.message}`), { retryable: true });
  }

  // 6. Poll for completion
  emitProgress(jobId, 'poll');

  const pollPromise = (async () => {
    let attempts = 0;
    while (attempts < 60) { // 60 * 5s = 5 mins max
      if (signal?.aborted) throw signal.reason;

      // Check for policy block or error
      const errorText = await page.locator('text=/Policy|Blocked|Error/i').count();
      if (errorText > 0) {
        throw Object.assign(new Error('Generation blocked by platform policy or general error.'), { retryable: false });
      }

      // Check for download button
      const downloadBtnRole = page.getByRole('button', { name: /Download/i }).first();
      const downloadBtnText = page.locator('button:has-text("Download")').first();
      const downloadBtnAria = page.locator('button[aria-label*="Download" i]').first();

      if (await downloadBtnRole.isVisible() || await downloadBtnText.isVisible() || await downloadBtnAria.isVisible()) {
        break; // Ready!
      }

      await page.waitForTimeout(5000);
      attempts++;
    }
    if (attempts >= 60) {
      throw Object.assign(new Error('Timed out waiting for generation to complete.'), { retryable: true });
    }
  })();

  const abortPromise = new Promise((_, reject) => {
    if (!signal) return;
    if (signal.aborted) return reject(signal.reason);
    signal.addEventListener('abort', () => reject(signal.reason), { once: true });
  });

  try {
    await Promise.race([pollPromise, abortPromise]);
  } catch (e) {
    if (e === signal?.reason) throw e;
    throw e;
  }
  if (signal?.aborted) throw signal.reason;

  // 7. Download
  emitProgress(jobId, 'download');
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  const partialPath = outputPath + '.partial';

  try {
    const downloadPromise = page.waitForEvent('download', { timeout: 30000 });

    // Find valid download btn again
    let validDownloadBtn;
    if (await page.getByRole('button', { name: /Download/i }).first().isVisible()) {
      validDownloadBtn = page.getByRole('button', { name: /Download/i }).first();
    } else if (await page.locator('button:has-text("Download")').first().isVisible()) {
      validDownloadBtn = page.locator('button:has-text("Download")').first();
    } else {
      validDownloadBtn = page.locator('button[aria-label*="Download" i]').first();
    }

    await validDownloadBtn.click();

    const downloadEvent = await Promise.race([downloadPromise, abortPromise]);
    if (signal?.aborted) throw signal.reason;

    await downloadEvent.saveAs(partialPath);
    fs.renameSync(partialPath, outputPath);
  } catch (e) {
    if (fs.existsSync(partialPath)) fs.unlinkSync(partialPath);
    if (e === signal?.reason) throw e;
    throw Object.assign(new Error(`Download failed: ${e.message}`), { retryable: true });
  }

  // 8. Done
  emitProgress(jobId, 'done', { outputPath });
  return { status: 'success', outputPath };
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

/**
 * Change headless default to FALSE so that any login flow shows a browser window.
 * Workflows that need truly headless can pass headless:true explicitly.
 */
async function openBrowser({ headless = false, profileId = 'default', userDataDir, proxyServer } = {}) {
  if (contexts.has(profileId)) {
    info(`Browser already open for profile "${profileId}", reusing.`);
    return { status: 'already_open', profileId };
  }

  const launchArgs = [
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-blink-features=AutomationControlled',
    '--disable-dev-shm-usage',          // Stability on low-end machines
    '--disable-extensions-except=',     // Prevent extensions from blocking
  ];
  if (proxyServer) launchArgs.push(`--proxy-server=${proxyServer}`);

  const options = {
    headless,
    args: launchArgs,
    viewport: { width: 1280, height: 720 },
    // Do NOT specify channel here — always use bundled Playwright chromium.
    // Specifying channel:'chrome' requires system Chrome to be installed.
  };

  info(`Launching browser: headless=${headless}, profile=${profileId}, userDataDir=${userDataDir || '(none)'}`);

  let ctx;
  try {
    if (userDataDir) {
      // Persistent context preserves cookies, localStorage, and login state.
      fs.mkdirSync(userDataDir, { recursive: true }); // Ensure dir exists
      ctx = await chromium.launchPersistentContext(userDataDir, options);
    } else {
      const browser = await chromium.launch(options);
      ctx = await browser.newContext();
    }
  } catch (e) {
    err(`Browser launch failed for profile "${profileId}": ${e.message}`);
    err('TIP: Run `npx playwright install chromium` in the engine directory to install the browser.');
    throw Object.assign(
      new Error(`Browser launch failed: ${e.message}. Run 'npx playwright install chromium' to fix.`),
      { retryable: false }
    );
  }

  contexts.set(profileId, ctx);
  if (!headless) {
    info(`✅ Browser launched HEADED (visible window) for profile "${profileId}" — user can now interact.`);
  }
  info(`Browser opened for profile "${profileId}" (headless=${headless}, pid=${process.pid})`);
  return { status: 'opened', profileId, pid: process.pid, headless };
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

const VEO3_URL = 'https://labs.google/fx/tools/flow';

async function generateVeo3(prompt, profileId, outputDir, taskId, maxWaitMs) {
  const page = await getPage({ profileId });

  // Step 1: Navigate (skip if already there)
  if (!page.url().includes('labs.google')) {
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
