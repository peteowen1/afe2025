library(RSelenium)
library(tidyverse)
library(rvest)
library(httr)
library(furrr)
library(curl)
library(readxl)
#############################################
supervoter <- read_excel("yougov_polls_afe22.xlsx",sheet = "supervoter") %>% janitor::clean_names()
colnames(supervoter) <- paste(colnames(supervoter), "supervoter", sep  = "_")
supervoter <- supervoter %>% mutate(coalition_supervoter = 
                                      ifelse(is.na(nationals_supervoter),0,nationals_supervoter)+
                                      ifelse(is.na(liberal_supervoter),0,liberal_supervoter)
                                    )
yougov_polls <- read_excel("yougov_polls_afe22.xlsx",sheet = "yougov") %>% janitor::clean_names()
colnames(yougov_polls) <- paste(colnames(yougov_polls), "yougov", sep = "_")

# url <- paste0("https://www.theaustralian.com.au/federal-election-2022/results")
# 
# download.file(url, destfile = "scrapedpage.html", quiet=TRUE)
# content <- read_html("scrapedpage.html")
# 
# read_html(curl(url, handle = curl::new_handle("useragent" = "Mozilla/5.0")))%>%
#   html_text()
# 
# yougov_df <- read_html(x) %>%
#   html_table()
# armarium_df <- armarium_df[[4]] %>% janitor::clean_names() %>% 
#   janitor::remove_empty(c("rows", "cols")) %>% janitor::remove_constant()
# 
# armarium_df <- armarium_df %>%
#   mutate(across(.cols = 2:8, .fns = ~str_replace_all(., "[^[:alnum:]]", ""))) %>%
#   mutate(across(.cols = 2:8, .fns = ~as.numeric(.)/100))
