library(RSelenium)
library(tidyverse)
library(rvest)
library(httr)
library(furrr)

#############################################
# java -jar selenium-server-standalone-3.9.1.jar -port 4447

# https://www.aeforecasts.com/seat/2022fed/regular/casey
# https://www.aeforecasts.com/forecast/2022fed/regular/

remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4447L, # change port according to terminal
  browserName = "firefox"
)

#######################################
tictoc::tic()
remDr$open()
# remDr$getStatus()

url <- paste0("https://www.aeforecasts.com/forecast/2022fed/regular/")

remDr$navigate(url)
Sys.sleep(5)
remDr$refresh()
names <-
  remDr$findElements(
    using = "css selector",
    value = ".Seats_seatsLeft__2YDaB > strong"
  )
obs <- length(names)
obs

names_df  <-
  unlist(lapply(names, function(x) {
    x$getElementText()
  })) %>%
  tibble() %>%
  janitor::clean_names()

electorates <- names_df %>% pull()
###
tot_df <- tibble()

for (i in electorates) {

url <- paste0("https://www.aeforecasts.com/seat/2022fed/regular/",gsub(" ","-",tolower(i)))
remDr$navigate(url)

tables <-
  remDr$findElements(
    using = "css selector",
    value = ".SeatDetailBody_seatsWinStatement__2C40Q span"
  )
obs <- length(tables)
obs

###
tables_df <-
  unlist(lapply(tables, function(x) {
    x$getElementText()
  })) %>%
  tibble() %>%
  janitor::clean_names()
  
party <- tables_df %>% filter(row_number() %% 3 == 1)
prob <- tables_df %>% filter(row_number() %% 3 == 0)
elec_df <- bind_cols(party,prob,i) 
colnames(elec_df) <- c('party','prob','electorate')

#assign(i, elec_df)
print(i)

tot_df <- bind_rows(tot_df,elec_df)
}
remDr$close()
tictoc::toc()

tot_df <- 
  tot_df %>% 
  mutate(prob = readr::parse_number(prob)/100)

saveRDS(tot_df,'aef22_tot_df.rds')
tot_df <- readRDS('aef22_tot_df.rds')

library(dplyr)
aef_df <- 
  tot_df %>%
  tidyr::pivot_wider(names_from = party, values_from = prob) %>%
  janitor::clean_names()

colnames(aef_df) <- paste(colnames(aef_df), "aef", sep = "_")

saveRDS(aef_df,'aef22_aef_df.rds')
aef_df <- readRDS('aef22_aef_df.rds')

###





