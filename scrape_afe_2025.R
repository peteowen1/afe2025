library(processx)
library(jsonlite)

##### Run Puppeteer scraper
tictoc::tic('scrape Sportsbet electorates')
run("node", args = "electorates.js", wd = ".", echo = TRUE)
tictoc::toc()
#################################

##### Run Puppeteer scraper
tictoc::tic('scrape Sportsbet parties')
run("node", args = "electorate-parties.js", wd = ".", echo = TRUE)
tictoc::toc()
#################################

##### Run Puppeteer scraper
tictoc::tic('scrape Sportsbet odds')
run("node", args = "electorate-odds.js", wd = ".", echo = TRUE)
tictoc::toc()
#################################

##### Run Puppeteer scraper
tictoc::tic('scrape TAB odds')
run("node", args = "tab-scrape-afe25.js", wd = ".", echo = TRUE)
tictoc::toc()
#################################

##### Run Puppeteer scraper
tictoc::tic('scrape Betr state links')
run("node", args = "betr-scrape-afe25.js", wd = ".", echo = TRUE)
tictoc::toc()
###############

##### Run Puppeteer scraper
tictoc::tic('scrape Betr odds')
run("node", args = "betr-electorates-scrape.js", wd = ".", echo = TRUE)
tictoc::toc()
###############

##### Run Puppeteer scraper
tictoc::tic('scrape aef electorates')
run("node", args = "aeforecasts_scrape.js", wd = ".", echo = TRUE)
tictoc::toc()
#################################

##### Run Puppeteer scraper
tictoc::tic('scrape aef odds')
run("node", args = "seat-aeforecast.js", wd = ".", echo = TRUE)
tictoc::toc()
###############
