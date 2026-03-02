const { log } = require('../logger');
const browserHandler = require('./browserHandler');

class VeoHandler {
    async login({ email, password }) {
        const page = browserHandler.getPage();
        if (!page) throw new Error("Browser not initialized");

        log('info', 'Executing Veo Login sequence', { email: email.split('@')[0] + '@...' });

        // Step 1: Google Login (if needed)
        await page.goto('https://accounts.google.com', { waitUntil: 'networkidle' });

        try {
            // Check if already logged in or needs email
            const emailInput = await page.$('input[type="email"]');
            if (emailInput) {
                await page.fill('input[type="email"]', email);
                await page.click('#identifierNext');
                await page.waitForSelector('input[type="password"]', { state: 'visible', timeout: 10000 });
                await page.fill('input[type="password"]', password);
                await page.click('#passwordNext');
                await page.waitForNavigation({ waitUntil: 'networkidle' });
            } else {
                log('info', 'Likely already logged into Google');
            }
        } catch (e) {
            log('warn', `Google login step might have been skipped or failed: ${e.message}`);
        }

        // Step 2: Verify Veo access
        await page.goto('https://labs.google/veo', { waitUntil: 'networkidle' });
        log('info', 'Navigated to Veo dashboard');
    }

    async generate({ prompt }) {
        const page = browserHandler.getPage();
        if (!page) throw new Error("Browser not initialized");

        log('info', 'Starting Video Generation', { promptSnippet: prompt.substring(0, 30) + '...' });

        // Ensure we are on the right page
        if (!page.url().includes('labs.google/veo')) {
            await page.goto('https://labs.google/veo', { waitUntil: 'networkidle' });
        }

        // Selector Strategy: Robust waiting
        const promptSelector = 'textarea[placeholder*="Describe"], [contenteditable="true"]';
        await page.waitForSelector(promptSelector, { state: 'visible', timeout: 30000 });

        // Clear and Fill
        await page.click(promptSelector);
        await page.keyboard.press('Control+A');
        await page.keyboard.press('Backspace');
        await page.fill(promptSelector, prompt);

        log('info', 'Prompt entered, clicking generate');
        const generateBtn = 'button:has-text("Generate"), button[aria-label="Generate"]';
        await page.waitForSelector(generateBtn, { state: 'enabled' });
        await page.click(generateBtn);

        return {
            status: 'generating',
            message: 'Video generation task sent to Veo engine',
            timestamp: new Date().toISOString()
        };
    }
}

module.exports = new VeoHandler();
