const puppeteer = require('puppeteer');
const fs = require('fs');

// Simple delay helper
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Auto-scroll helper to load lazy content
async function autoScroll(page) {
  await page.evaluate(async () => {
    await new Promise((resolve) => {
      let totalHeight = 0;
      const distance = 200;
      const timer = setInterval(() => {
        window.scrollBy(0, distance);
        totalHeight += distance;
        if(totalHeight >= document.body.scrollHeight) {
          clearInterval(timer);
          resolve();
        }
      }, 300);
    });
  });
}

(async () => {
  // Load state links from JSON
  const stateLinks = JSON.parse(fs.readFileSync('state_links.json', 'utf8'));
  let finalResults = [];

  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  );

  // Process each state link one by one.
  for (const state of stateLinks) {
    console.log(`Processing state: ${state.text}`);
    await page.goto(state.href, { waitUntil: 'networkidle2', timeout: 120000 });
    await delay(3000);
    await autoScroll(page);
    await delay(2000);

    // 1) Expand state containers by clicking all expand buttons (.icon-down-arrow)
    let arrows = await page.$$('.icon-down-arrow');
    for (const arrow of arrows) {
      await arrow.click();
      await delay(500);
    }
    await autoScroll(page);
    await delay(2000);

    // 2) Now, gather all seat containers.
    //    We use a broad selector to capture any container that is part of a list.
    const seatContainers = await page.$$('[class*="MuiList-root"]');
    console.log(`Found ${seatContainers.length} seat containers in state: ${state.text}`);

    for (const container of seatContainers) {
      // Extract the seat name using the more specific selector for detailed seat info.
      // We target an element with classes including "MuiTypography-root" and "MuiTypography-body1".
      const seatName = await container.$eval('.MuiTypography-root.MuiTypography-body1', el => el.innerText.trim()).catch(() => null);
      if (!seatName) continue; // Skip if not found.

      // 3) Within each container, assume each candidate is in an <li> element.
      const rows = await container.$$('li');
      for (const row of rows) {
        // Extract party text from an element with class containing "MuiListItemText-root".
        const party = await row.$eval('[class*="MuiListItemText-root"]', el => el.innerText.trim()).catch(() => null);
        // Extract odds from the row using row-level querying for ".MuiButton-label".
        const odds = await row.$$eval('.MuiButton-label', els => (els.length ? els[0].innerText.trim() : null)).catch(() => null);

        if (party) {
          finalResults.push({
            state: state.text,
            seat: seatName,
            party: party,
            odds: odds
          });
        }
      }
    }
  }

  // Filter results: keep only rows where the seat contains the detailed descriptive text.
  // Adjust the substring below as needed to match exactly the text that indicates a real seat.
  finalResults = finalResults.filter(item => item.seat.includes("Settled on the nominated seat winner"));

  fs.writeFileSync('betr_electorate_data.json', JSON.stringify(finalResults, null, 2));
  console.log("Data saved to betr_electorate_data.json");

  await browser.close();
})();
