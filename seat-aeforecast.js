const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  // Load seat_links.json (ensure this file is in the same folder)
  const seatLinks = JSON.parse(fs.readFileSync('seat_links.json', 'utf8'));
  
  // Filter to include only records with a valid URL in href
  const validLinks = seatLinks.filter(link => link.href);
  
  // Launch the headless browser
  const browser = await puppeteer.launch({ headless: true });
  const results = []; // This will hold results for each seat
  
  // Loop through each valid seat URL
  for (const seat of validLinks) {
    console.log(`Processing ${seat.href}...`);
    const page = await browser.newPage();
    
    try {
      // Navigate to the seat page
      await page.goto(seat.href, { waitUntil: 'networkidle0' });
      
      // Wait for the win statement elements to load (adjust timeout as needed)
      await page.waitForSelector('.Seats_seatsWinStatement__6yKgA', { timeout: 10000 });
      
      // Scrape win statements from the page
      const winStatements = await page.evaluate(() => {
        const elements = Array.from(document.querySelectorAll('.Seats_seatsWinStatement__6yKgA'));
        return elements.map(el => el.innerText.trim());
      });
      
      // Parse each win statement into party and probability
      const parsedResults = winStatements.map(statement => {
        let party, probability;
        
        // Regex to capture a party code (e.g., "ALP", "LIB", "GRN", "IND*", "ON")
        // and the probability at the end (e.g., "34.4")
        const regex = /^([A-Z]{2,4}(?:\*)?)(?:\s+\(.*?\))?.*\(([\d.]+)%\)$/;
        let match = statement.match(regex);
        
        if (match) {
          party = match[1];
          probability = match[2];
        } else {
          // For lines not matching the regex, check for specific keywords
          if (statement.includes("an emerging party")) {
            party = "emerging party";
          } else if (statement.includes("any other candidate")) {
            party = "other candidate";
          } else {
            party = "unknown";
          }
          // Extract the probability from the end of the statement
          const probMatch = statement.match(/\(([\d.]+)%\)$/);
          probability = probMatch ? probMatch[1] : null;
        }
        return { party, probability };
      });
      
      // Save results for this seat URL
      results.push({ url: seat.href, data: parsedResults });
      
    } catch (err) {
      console.error(`Error processing ${seat.href}: ${err.message}`);
      results.push({ url: seat.href, error: err.message });
    }
    
    // Close the page after processing
    await page.close();
  }
  
  // Close the browser once all pages have been processed
  await browser.close();
  
  // Save the combined results to a JSON file
  fs.writeFileSync('all_seats_parsed.json', JSON.stringify(results, null, 2), 'utf8');
  console.log('Parsed results saved to all_seats_parsed.json');
})();
