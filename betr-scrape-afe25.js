const puppeteer = require('puppeteer');
const fs = require('fs');

// Simple delay function for older Puppeteer versions that lack page.waitForTimeout
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

  // 1) Navigate to Betr’s main Electorate Betting page
  const url = 'https://www.betr.com.au/sports/Politics/142/Australian-Elections/Electorate-Betting/193349';
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 120000 });
  await delay(3000);

  // 2) Look for anchor tags whose `href` contains "/Electorate-Betting/"
  //    These should correspond to clickable links for states, seats, etc.
  await page.waitForSelector('a[href*="/Electorate-Betting/"]', { timeout: 60000 });

  // 3) Extract link text and href from each such anchor
  //    Then filter them to find those that appear to be "State Electorates."
  //    (In your screenshot, e.g. "NSW Electorates," "QLD Electorates," etc.)
  const rawLinks = await page.$$eval('a[href*="/Electorate-Betting/"]', anchors =>
    anchors.map(a => ({
      text: a.innerText.trim(),
      href: a.href
    }))
  );

  // 4) Filter the set of links to keep only "state-level" ones.
  //    For example, you might look for link text that ends with "Electorates."
  //    Adjust the check below based on the actual text you see in DevTools or the UI.
  const stateLinks = rawLinks.filter(link =>
    link.text.toLowerCase().includes('electorates')
  );

  console.log("Found these potential state links:", stateLinks);

  // 5) Save the final set of links to a JSON file
  fs.writeFileSync('state_links.json', JSON.stringify(stateLinks, null, 2));
  console.log("Saved state links to state_links.json");

  await browser.close();
})();
