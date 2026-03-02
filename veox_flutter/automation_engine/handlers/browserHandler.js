const { chromium } = require('playwright-extra');
const stealth = require('puppeteer-extra-plugin-stealth');
const path = require('path');
const { log } = require('../logger');

chromium.use(stealth());

class BrowserHandler {
    constructor() {
        this.browser = null;
        this.context = null;
        this.page = null;
    }

    async launch(config) {
        if (this.context) {
            log('info', 'Reusing existing browser context');
            return this.page;
        }

        const userDataDir = path.join(__dirname, 'user_data', config.profileId || 'default');
        log('info', `Launching browser with profile: ${config.profileId || 'default'}`);

        this.context = await chromium.launchPersistentContext(userDataDir, {
            headless: config.headless === true,
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-blink-features=AutomationControlled'
            ],
            channel: 'chrome',
            viewport: { width: 1280, height: 800 }
        });

        this.page = this.context.pages().length > 0 ? this.context.pages()[0] : await this.context.newPage();
        return this.page;
    }

    async close() {
        if (this.context) {
            await this.context.close();
            this.context = null;
            this.page = null;
        }
    }

    async screenshot() {
        if (!this.page) throw new Error("No active page for screenshot");
        const screenshotPath = path.join(__dirname, 'user_data', `screenshot_${Date.now()}.png`);
        await this.page.screenshot({ path: screenshotPath });
        return screenshotPath;
    }

    getPage() {
        return this.page;
    }
}

module.exports = new BrowserHandler();
