const puppeteer = require('puppeteer');
const fs = require('fs');

// Helper: manual delay
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  // Set a realistic user agent
  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  );

  // Navigate to the TAB Federal Election page
  await page.goto(
    'https://www.tab.com.au/sports/betting/Politics/competitions/Australian%20Federal%20Politics/matches/Federal%20Election',
    { waitUntil: 'networkidle2', timeout: 120000 }
  );

  // Wait for state containers to appear
  await page.waitForSelector('._97shmn', { timeout: 60000 });
  const stateEls = await page.$$('._97shmn');
  let finalResults = [];

  for (const stateEl of stateEls) {
    // Extract the state name
    const stateName = await stateEl.evaluate(el => el.innerText.trim());

    // Expand all state containers by clicking each arrow (.icon-down-arrow)
    let stateArrows = await stateEl.$$('.icon-down-arrow');
    for (const arrow of stateArrows) {
      await arrow.click();
      await delay(1000);
    }

    // Wait a little for content to expand.
    await delay(2000);

    // Get all tables of interest
    const tables = await stateEl.$$('._1dae5j');
    for (const table of tables) {
      // Expand the table if there's an arrow inside (.icon-down-arrow)
      const tableArrow = await table.$('.icon-down-arrow');
      if (tableArrow) {
        await tableArrow.click();
        await delay(500);
      }

      // Wait briefly for expansion.
      await delay(1000);

      // Get each row that represents a market row (party/seat info is in element with class _zpgstj)
      const rowEls = await table.$$('._zpgstj');
      for (const rowEl of rowEls) {
        const partySeat = await rowEl.evaluate(el => el.innerText.trim());
        
        // Get the closest parent <tr> which should contain both the party/seat and odds info.
        const parentRowHandle = await rowEl.evaluateHandle(el => el.closest('tr'));
        
        // Try to capture the primary odds within the parent row
        let oddsPrimary = await parentRowHandle.$eval('._1eqo91h', el => el.innerText.trim()).catch(() => null);
        if (!oddsPrimary) {
          oddsPrimary = await parentRowHandle.$eval('._gvwxlh', el => el.innerText.trim()).catch(() => null);
        }
        
        // Try to capture a secondary odds value within the parent row
        let oddsSecondary = await parentRowHandle.$eval('._njbycu', el => el.innerText.trim()).catch(() => null);
        if (!oddsSecondary) {
          oddsSecondary = await parentRowHandle.$eval('._1qj0i3z', el => el.innerText.trim()).catch(() => null);
        }

        finalResults.push({
          state: stateName,
          party_seat: partySeat,
          odds_primary: oddsPrimary,
          odds_secondary: oddsSecondary
        });
      }
    }
  }

  fs.writeFileSync('tab_politics.json', JSON.stringify(finalResults, null, 2));
  console.log("Data saved to tab_politics.json");

  await browser.close();
})();
