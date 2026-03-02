const { chromium } = require('playwright-extra');
const stealth = require('puppeteer-extra-plugin-stealth')();
chromium.use(stealth);
const fs = require('fs');

async function runAutomation(configJSON) {
    const config = JSON.parse(configJSON);
    const { email, password, profilePath, outputPath, action } = config;

    // Launch browser dengan persistent context agar session tersimpan
    const context = await chromium.launchPersistentContext(profilePath, {
        headless: false, // Set false untuk memantau proses login pertama kali
        viewport: { width: 1280, height: 720 },
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox'
        ]
    });

    const page = await context.newPage();

    try {
        await page.goto('https://veo.google.com/', { waitUntil: 'load' });

        // Logika Login jika belum login (berdasarkan adanya tombol sign in)
        const signInButton = await page.$('text=Sign in');
        if (signInButton) {
            console.log("Melakukan login...");
            await signInButton.click();
            await page.waitForTimeout(2000);

            // Wait for email input
            await page.fill('input[type="email"]', email);
            await page.click('button:has-text("Next"), button:has-text("Selanjutnya")');
            await page.waitForTimeout(3000);

            // Wait for password input
            await page.fill('input[type="password"]', password);
            await page.click('button:has-text("Next"), button:has-text("Selanjutnya")');
            await page.waitForNavigation({ waitUntil: 'networkidle' }).catch(() => { });
        } else {
            console.log("Sudah login, session valid.");
        }

        if (action === 'screenshot') {
            const outPath = `${outputPath}/veo_capture_${Date.now()}.png`;
            await page.screenshot({ path: outPath, fullPage: true });
            console.log(JSON.stringify({ status: 'success', path: outPath }));
        } else if (action === 'generate') {
            // Simplified logic for Veo generation
            console.log("Tugas generate diterima (simulasi 10s)...");
            await page.waitForTimeout(10000);
            const outPath = `${outputPath}/veo_output_${Date.now()}.mp4`;
            fs.writeFileSync(outPath, "DUMMY VIDEO DATA"); // Simulation
            console.log(JSON.stringify({ status: 'success', path: outPath }));
        }

    } catch (error) {
        console.log(JSON.stringify({ status: 'error', message: error.message }));
    } finally {
        console.log("Menutup browser context...");
        await context.close();
    }
}

// Menerima input dari Flutter lewat argumen command line
const inputJson = process.argv[2];
if (inputJson) {
    runAutomation(inputJson);
} else {
    console.error("Missing JSON argument");
    process.exit(1);
}
