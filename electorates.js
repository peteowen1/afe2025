const puppeteer = require('puppeteer');
const fs = require('fs');

// Helper function to auto-scroll the page so lazy-loaded content appears.
async function autoScroll(page) {
  await page.evaluate(async () => {
    await new Promise((resolve) => {
      let totalHeight = 0;
      const distance = 200;
      const timer = setInterval(() => {
        window.scrollBy(0, distance);
        totalHeight += distance;
        if (totalHeight >= document.body.scrollHeight) {
          clearInterval(timer);
          resolve();
        }
      }, 300);
    });
  });
}

(async () => {
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  );

  // Navigate to the Sportsbet electorate betting page.
  await page.goto(
    'https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-8866861',
    { waitUntil: 'networkidle2', timeout: 120000 }
  );

  // Wait for the page to settle.
  await new Promise(resolve => setTimeout(resolve, 3000));

  // Click each arrow to expand state containers.
  await page.waitForSelector('.IconInteractiveNormalDefault_f19gfjg6', { timeout: 60000 });
  const arrowEls = await page.$$('.IconInteractiveNormalDefault_f19gfjg6');
  for (let arrow of arrowEls) {
    await arrow.click();
    // Manual delay instead of waitForTimeout.
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  // Auto-scroll to ensure all content is loaded.
  await autoScroll(page);
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Extract market containers whose data-automation-id includes "-market-item".
  // For each, find the electorate name inside the descendant with data-automation-id "event-accordion-title".
  const electorates = await page.$$eval('[data-automation-id]', elements => {
    return Array.from(elements)
      .filter(el => {
        const id = el.getAttribute('data-automation-id') || '';
        return id.includes('-market-item');
      })
      .map(el => {
        const marketId = el.getAttribute('data-automation-id');
        const nameEl = el.querySelector('[data-automation-id="event-accordion-title"]');
        const electorateName = nameEl ? nameEl.innerText.trim() : "Unknown Electorate";
        return { dataAutomationId: marketId, electorate: electorateName };
      });
  });

  fs.writeFileSync('electorates.json', JSON.stringify(electorates, null, 2));
  console.log('Electorates with IDs scraped and saved to electorates.json');

  await browser.close();
})();
