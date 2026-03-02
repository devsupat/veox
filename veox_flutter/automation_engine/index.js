const readline = require('readline');
const { log, sendResponse } = require('./logger');
const browserHandler = require('./handlers/browserHandler');
const veoHandler = require('./handlers/veoHandler');

// Input Reader
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

log('info', 'Automation Engine Modular Dispatcher Started');

rl.on('line', async (line) => {
  if (!line.trim()) return;

  try {
    const msg = JSON.parse(line);
    await handleCommand(msg);
  } catch (e) {
    log('error', `Invalid JSON or Command Execution: ${e.message}`);
  }
});

async function handleCommand(msg) {
  const { id, command, payload } = msg;

  try {
    let result;
    switch (command) {
      case 'browser.launch':
        await browserHandler.launch(payload);
        sendResponse(id, 'success', { message: 'Browser launched' });
        break;

      case 'browser.close':
        await browserHandler.close();
        sendResponse(id, 'success', { message: 'Browser closed' });
        break;

      case 'browser.screenshot':
        const screenshotPath = await browserHandler.screenshot();
        sendResponse(id, 'success', { path: screenshotPath });
        break;

      case 'page.goto':
        const page = browserHandler.getPage();
        if (!page) throw new Error("No active page");
        await page.goto(payload.url, { waitUntil: 'networkidle' });
        sendResponse(id, 'success', { url: page.url() });
        break;

      case 'veo.login':
        await veoHandler.login(payload);
        sendResponse(id, 'success', { message: 'Veo Login Flow Completed' });
        break;

      case 'veo.generate':
        result = await veoHandler.generate(payload);
        sendResponse(id, 'success', result);
        break;

      case 'veo.auth_guided':
        result = await veoHandler.authGuided();
        sendResponse(id, 'success', result);
        break;

      default:
        throw new Error(`Unknown command: ${command}`);
    }
  } catch (e) {
    log('error', `Command [${command}] failed: ${e.message}`, { stack: e.stack });
    sendResponse(id, 'error', null, e.message);
  }
}

// Global error handling for unexpected crashes
process.on('uncaughtException', (err) => {
  log('error', 'Uncaught Exception', { message: err.message, stack: err.stack });
});

process.on('unhandledRejection', (reason, promise) => {
  log('error', 'Unhandled Rejection', { reason: reason?.toString() });
});
