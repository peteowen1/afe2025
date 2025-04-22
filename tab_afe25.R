# https://stackoverflow.com/q/67021563/10527496
# https://www.r-bloggers.com/2021/04/using-rselenium-to-scrape-a-paginated-html-table/

# java -jar selenium-server-standalone-3.9.1.jar -port 4447

#setwd("C:/Users/peteo/OneDrive/Documents")

library(RSelenium)
library(tidyverse)
library(rvest)
library(httr)
library(furrr)

remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4447L, # change port according to terminal
  browserName = "firefox"
)

remDr$open()
# remDr$getStatus()

remDr$navigate(paste0("https://www.tab.com.au/sports/betting/Politics/competitions/Australian%20Federal%20Politics"))
#remDr$findElements("css selector", "._97shmn:nth-child(4) ._p1oke7")[[1]]$clickElement()

#3 nsw
#4 vic
#4 
# remDr$navigate(paste0("https://www.sportsbet.com.au/",url))

tables <-
  remDr$findElements(
    using = "css selector",
    value =
      paste0(".proposition-wrapper div")#._csxsld , ._1eqo91h:nth-child(40) ._1qj0i3z")
  )

temp_df <-
  unlist(lapply(tables, function(x) {
    x$getElementText()
  })) %>%
  tibble() #%>%
  janitor::clean_names() %>%
  # slice(-1) %>%
  # mutate(location = .[[1, 1]]) %>%
  separate(x, c("party", "odds"), sep = "\n") # %>%
# separate(location, c("electorate", "state"), sep = " \\(") %>%
# slice(2:(n()-1)) %>%
# mutate(state = substr(state, 1, nchar(state) - 1))

colnames(temp_df)  <- "x"
  
temp_df2 <- temp_df %>%
  separate(x, c("party", "location"), sep = ".\\(") 
temp_df2$location <- substr(temp_df2$location,1,nchar(temp_df2$location)-1)  

temp_df2 <- temp_df2 %>% filter(party != "")

temp_df2 <- temp_df2 %>% mutate(odds = lead(party)) 
temp_df2 <- temp_df2 %>% filter(!is.na(location))
temp_df2 <- temp_df2 %>% mutate(odds = as.numeric(ifelse(odds == "SUSP",999,odds))) 

saveRDS(temp_df2, paste0(Sys.Date(), "_tab_afe22.rds"))

##########################
tab_df <- readRDS(paste0(Sys.Date(), "_tab_afe22.rds"))

tab_df <- tab_df %>% mutate(odds = ifelse(odds == 999,1.01,odds))

tab_df <- tab_df %>% mutate(party = tolower(party)) %>%
  mutate(party = case_when(
  str_detect(party,"any other") ~ "any_other",
  str_detect(party,"any other") ~ "any_other",
  str_detect(party,"centre all") ~ "centre_alliance",
  str_detect(party,"green") ~ "greens",
  str_detect(party,"indep") ~ "independent",
  str_detect(party,"uap") ~ "uap",
  str_detect(party,"united") ~ "uap",
  str_detect(party,"utd") ~ "uap",
  str_detect(party,"one nation") ~ "one_nation",
  TRUE ~ party
))

tab_pivot <- tab_df %>%
  select(location,party,odds) %>%
  pivot_wider(names_from = party, values_from = odds, values_fn = {
    min
  })

colnames(tab_pivot) <- paste(colnames(tab_pivot), "tab", sep  = "_")
tab_pivot <- tab_pivot %>% janitor::clean_names()


#######
saveRDS(tab_pivot, paste0(Sys.Date(), "_tab_piv_afe22.rds"))
##########################
tab_pivot <- readRDS(paste0(Sys.Date(), "_tab_piv_afe22.rds"))


