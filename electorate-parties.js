const puppeteer = require('puppeteer');
const fs = require('fs');

// Helper function: auto-scroll to load lazy-loaded content
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
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  // Realistic user agent
  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  );

  // Navigate to electorate betting page
  await page.goto(
    'https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-8866861',
    { waitUntil: 'networkidle2', timeout: 120000 }
  );

  await delay(5000); // Increased initial delay

  // 1) Expand all states
  try {
    await page.waitForSelector('.IconInteractiveNormalDefault_f19gfjg6', { timeout: 60000 });
    let stateArrows = await page.$$('.IconInteractiveNormalDefault_f19gfjg6');
    for (const arrow of stateArrows) {
      await arrow.click();
      await delay(1000);
    }
  } catch (error) {
    console.error("Error expanding states:", error);
  }

  await autoScroll(page);
  await delay(2000);

  // 2) Expand all electorates
  try {
    await page.waitForSelector('.IconInteractiveNormalDefault_f19gfjg6', { timeout: 60000 }); // Re-wait in case of dynamic loading
    let electorateArrows = await page.$$('.IconInteractiveNormalDefault_f19gfjg6');
    for (const arrow of electorateArrows) {
      await arrow.click();
      await delay(500);
    }
  } catch (error) {
    console.error("Error expanding electorates:", error);
  }

  await autoScroll(page);
  await delay(2000);


  // 3) Scrape candidate data using your NSW-working selectors
  const rawMarkets = await page.$$eval('[data-automation-id]', elements => {
    return Array.from(elements)
      .filter(el => el.querySelector('.threeOutcomes_flpw9cb') || el.querySelector('.SF_PRO_REG_14_16_fopsgmj'))
      .map(el => {
        const dataAutomationId = el.getAttribute('data-automation-id') || 'unknown';
        let candidates = [];
        if (el.querySelector('.threeOutcomes_flpw9cb')) {
          candidates = Array.from(el.querySelectorAll('.threeOutcomes_flpw9cb .TextNormal_f1vshw8n'))
            .map(candidateEl => candidateEl.innerText.trim());
        } else if (el.querySelector('.SF_PRO_REG_14_16_fopsgmj')) {
          candidates = Array.from(el.querySelectorAll('.SF_PRO_REG_14_16_fopsgmj'))
            .map(candidateEl => candidateEl.innerText.trim());
        }
        return { dataAutomationId, candidates };
      });
  });

  // 4) Filter results to include only market items
  const filteredMarkets = rawMarkets.filter(item => item.dataAutomationId.includes('-market-item'));

  // 5) Save filtered candidate data to JSON file
  fs.writeFileSync('candidates_filtered.json', JSON.stringify(filteredMarkets, null, 2));
  console.log("Filtered candidate data saved to candidates_filtered.json");

  await browser.close();
})();