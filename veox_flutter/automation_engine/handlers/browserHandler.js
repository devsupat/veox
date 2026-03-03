'use strict';

const { chromium } = require('playwright-extra');
const stealth = require('puppeteer-extra-plugin-stealth');
const path = require('path');
const fs = require('fs');
const { log } = require('../logger');

chromium.use(stealth());

class BrowserHandler {
    constructor() {
        this.browser = null;
        this.context = null;
        this.page = null;
    }

    /**
     * Launches a persistent browser context.
     *
     * IMPORTANT: headless defaults to FALSE so that login flows always show a
     * visible browser window. Pass { headless: true } only for non-interactive tasks.
     *
     * channel:'chrome' is intentionally NOT used here — it requires a system Chrome
     * installation. We always use the Playwright-bundled chromium for reliability.
     */
    async launch(config = {}) {
        if (this.context) {
            log('info', 'Reusing existing browser context');
            return this.page;
        }

        const profileId = config.profileId || 'default';
        // Default headless to FALSE — login flows need a visible window.
        const headless = config.headless === true;

        const userDataDir = config.userDataDir ||
            path.join(path.dirname(__dirname), 'user_data', profileId);

        // Ensure the profile directory exists before Playwright tries to use it.
        fs.mkdirSync(userDataDir, { recursive: true });

        log('info', `Launching browser: headless=${headless}, profile="${profileId}", userDataDir=${userDataDir}`);

        try {
            this.context = await chromium.launchPersistentContext(userDataDir, {
                headless,
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-blink-features=AutomationControlled',
                    '--disable-dev-shm-usage', // Stability on low-end / VM machines
                    '--no-first-run',
                    '--no-default-browser-check',
                ],
                // Do NOT set channel:'chrome' — use bundled Playwright chromium.
                viewport: { width: 1280, height: 800 },
            });
        } catch (e) {
            log('error', `Browser launch failed: ${e.message}`);
            log('error', 'FIX: Run `cd automation_engine && npx playwright install chromium` to install the bundled browser.');
            throw e;
        }

        this.page = this.context.pages().length > 0
            ? this.context.pages()[0]
            : await this.context.newPage();

        if (!headless) {
            log('info', `✅ Browser launched HEADED (visible window) for profile "${profileId}" — user can now interact.`);
        }

        return this.page;
    }

    async close() {
        if (this.context) {
            await this.context.close();
            this.context = null;
            this.page = null;
            this.browser = null;
        }
    }

    async screenshot() {
        if (!this.page) throw new Error('No active page for screenshot');
        const screenshotPath = path.join(
            path.dirname(__dirname), 'user_data', `screenshot_${Date.now()}.png`
        );
        await this.page.screenshot({ path: screenshotPath });
        return screenshotPath;
    }

    getPage() {
        return this.page;
    }
}

module.exports = new BrowserHandler();
