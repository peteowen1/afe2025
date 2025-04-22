const puppeteer = require('puppeteer');
const fs = require('fs');

// Helper function to auto-scroll the page so that all lazy-loaded content appears.
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

// Manual delay helper
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  // Launch Puppeteer (headless:false for debugging)
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  // Set a realistic user agent.
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
  await delay(3000);

  // Expand state containers by clicking each arrow.
  await page.waitForSelector('.IconInteractiveNormalDefault_f19gfjg6', { timeout: 60000 });
  let arrows = await page.$$('.IconInteractiveNormalDefault_f19gfjg6');
  for (const arrow of arrows) {
    await arrow.click();
    await delay(1000);
  }

  // Auto-scroll to load all content.
  await autoScroll(page);
  await delay(2000);

  // Optionally, click again to expand each electorate if needed.
  arrows = await page.$$('.IconInteractiveNormalDefault_f19gfjg6');
  for (const arrow of arrows) {
    await arrow.click();
    await delay(500);
  }
  await autoScroll(page);
  await delay(2000);

  // Extract market odds from each market container (data-automation-id includes "-market-item").
  const marketsOdds = await page.$$eval('[data-automation-id]', elements => {
    return Array.from(elements)
      .filter(el => {
        const id = el.getAttribute('data-automation-id') || "";
        return id.includes('-market-item');
      })
      .map(el => {
        const id = el.getAttribute('data-automation-id');
        const priceEls = el.querySelectorAll('.priceTextSize_frw9zm9');
        const prices = Array.from(priceEls).map(pe => pe.innerText.trim());
        return { id, prices };
      });
  });

  fs.writeFileSync('market_odds.json', JSON.stringify(marketsOdds, null, 2));
  console.log("Market odds data saved to market_odds.json");

  await browser.close();
})();
