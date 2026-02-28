const readline = require('readline');
const { chromium } = require('playwright-extra');
const stealth = require('puppeteer-extra-plugin-stealth');
const { v4: uuidv4 } = require('uuid');

// Setup Stealth Plugin
chromium.use(stealth());

// IPC Setup
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

// Helper to send JSON back to Flutter
const send = (data) => console.log(JSON.stringify(data));

// State
let browser = null;
let context = null;

rl.on('line', async (line) => {
  if (!line) return;
  
  try {
    const msg = JSON.parse(line);
    const { id, command, params } = msg;

    send({ id, type: 'log', msg: `Received command: ${command}` });

    try {
      let result;
      switch (command) {
        case 'ping':
          result = { pong: true, time: Date.now() };
          break;
          
        case 'open_browser':
          result = await openBrowser(params);
          break;
          
        case 'close_browser':
          result = await closeBrowser();
          break;
          
        default:
          throw new Error(`Unknown command: ${command}`);
      }

      send({ id, type: 'result', status: 'success', data: result });
    } catch (err) {
      send({ id, type: 'result', status: 'error', error: err.message });
    }

  } catch (e) {
    console.error("JSON Error", e);
  }
});

// Handlers
async function openBrowser(params) {
  if (browser) return { status: 'already_open' };
  
  const { headless = true, userDataDir } = params || {};
  
  // Use persistent context for profile management
  // If userDataDir is provided, use it. Otherwise, ephemeral.
  if (userDataDir) {
    context = await chromium.launchPersistentContext(userDataDir, {
      headless: headless,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
      viewport: { width: 1280, height: 720 }
    });
  } else {
    browser = await chromium.launch({
      headless: headless,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    context = await browser.newContext();
  }
  
  return { status: 'opened', pid: process.pid };
}

async function closeBrowser() {
  if (context) await context.close();
  if (browser) await browser.close();
  context = null;
  browser = null;
  return { status: 'closed' };
}

send({ type: 'system', msg: 'Node Engine Ready' });
