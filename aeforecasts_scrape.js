const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  // Launch the headless browser
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  // Navigate to the target URL
  await page.goto('https://www.aeforecasts.com/forecast/2025fed/regular', { waitUntil: 'networkidle0' });

  // Wait for the seat links to appear
  await page.waitForSelector('.Seats_seatsLink__UXYgj');

  // Scrape all seat links, looking for the nearest <a> element for each
  const seatLinks = await page.evaluate(() => {
    // Get all elements that match the selector
    const elements = Array.from(document.querySelectorAll('.Seats_seatsLink__UXYgj'));
    
    return elements.map(el => {
      // Try finding an anchor element within or closest to the element
      let anchor = el.closest('a');
      if (!anchor) {
        anchor = el.querySelector('a');
      }
      return {
        href: anchor ? anchor.href : null,
        text: el.innerText.trim()
      };
    });
  });

  // Save the scraped data to a JSON file
  fs.writeFileSync('seat_links.json', JSON.stringify(seatLinks, null, 2), 'utf-8');
  console.log('Scraped seat links saved to seat_links.json');

  // Close the browser
  await browser.close();
})();
