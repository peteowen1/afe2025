# https://stackoverflow.com/q/67021563/10527496
# https://www.r-bloggers.com/2021/04/using-rselenium-to-scrape-a-paginated-html-table/

# java -jar selenium-server-standalone-3.9.1.jar -port 4447

# source("powershell_scraping_setup.sh")
# nsw = .header_fa0934g
# tas .headerContent_feb23nm
# vic = .headerContent_feb23nm
# qld = .headerContent_feb23nm

library(RSelenium)
library(tidyverse)
library(rvest)
library(httr)
library(furrr)

tictoc::tic()

url <- "https://www.sportsbet.com.au/betting/politics/australian-federal-politics"
links <- read_html(url) %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  str_subset("/australian-federal-politics/") %>% # /electorate
  unique()
# str_subset("seats") %>%
# str_subset("independent", negate = TRUE)

links

remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4447L, # change port according to terminal
  browserName = "firefox"
)

####################################### nsw,vic,qld,wa,sa,tas,act,nt
state <- c("act", "nsw", "nt", "qld", "sa", "tas", "vic", "wa")
for (j in state) {
  # state <- "nt"
  number <- grep(paste0("-", j, "-"), links)
  final_df <- tibble()
  
  remDr$open()
  # remDr$getStatus()
  
  remDr$navigate(paste0("https://www.sportsbet.com.au/betting/politics/australian-federal-politics"))
  remDr$findElements("css selector", ".eventName_f1pe3eym")[[number]]$clickElement()
  remDr$refresh()
  # remDr$navigate(paste0("https://www.sportsbet.com.au/",url))
  
  names <-
    remDr$findElements(
      using = "css selector",
      value = ".chevronBottom_felu1so"
    )
  obs <- length(names)
  obs
  
  expander <- remDr$findElements(
    using = "css selector",
    value = ".exited_f1ln79gx .chevronBottom_felu1so"
  )
  
  if (length(expander) > 0) {
    expander[[1]]$clickElement()
    
    Sys.sleep(5)
    #####
    names2 <-
      remDr$findElements(
        using = "css selector",
        value = ".chevronBottom_felu1so"
      )
    length(names2)
    for (i in (obs + 1):length(names2)) {
      names2[[i]]$clickElement()
    }
  }
  ###########################################################
  
  # .headerContent_feb23nm , .chevronBottom_felu1so
  tables <-
    remDr$findElements(
      using = "css selector",
      value =
        paste0(".headerContent_feb23nm , .outcomeDetails_f1t3f12")
    )
  
  ######
  temp_df <-
    unlist(lapply(tables, function(x) {
      x$getElementText()
    })) %>%
    tibble() %>%
    janitor::clean_names() %>%
    # slice(-1) %>%
    # mutate(location = .[[1, 1]]) %>%
    separate(x, c("party", "odds"), sep = "\n") # %>%
  # separate(location, c("electorate", "state"), sep = " \\(") %>%
  # slice(2:(n()-1)) %>%
  # mutate(state = substr(state, 1, nchar(state) - 1))
  
  wherena <- which(is.na(temp_df$odds))
  elec <- temp_df[wherena, "party"]
  temp_df[wherena, "location", ] <- elec
  temp_df <-
    temp_df %>%
    fill(location) %>%
    separate(location, c("electorate", "state"), sep = " \\(") %>%
    mutate(state = j) # substr(state, 1, nchar(state) - 1))
  ##########################################################################
  ####################################
  state_df <- temp_df %>% filter(!is.na(odds)) # %>% bind_rows(temp_df2)
  remDr$close()
  #############################
  state_df <-
    state_df %>%
    # mutate(
    #   party =
    #     case_when(
    #       str_detect(party,"Independent") ~ "Independent",
    #       party == "Liberal" ~ "Coalition",
    #       TRUE ~ party
    #     )
    # ) %>%
    group_by(electorate) %>%
    mutate(
      odds = as.numeric(odds),
      min_odds = min(odds),
      bookie_p = 1 / odds,
      overround = sum(bookie_p),
      exponent = pmax(((1 + (((pmin(overround, 1.15)^4) - 1) / (min_odds)^4))^1), overround),
      adj_odds = odds^exponent,
      adj_p = 1 / adj_odds,
      adj_overround = sum(adj_p),
      final_odds = adj_odds * adj_overround,
      win_prob = 1 / final_odds
    ) %>%
    ungroup()
  
  summary(state_df$adj_overround)
  
  
  assign(j, state_df)
  print(j)
}

###########################
all_states <- bind_rows(act, nsw, nt, qld, tas, sa, vic, wa)

all_states <- all_states %>% separate(party, c("candidate", "party"), sep = "\\s*[()]")
all_states <- all_states %>% mutate(
  party =
    case_when(
      str_detect(party, "Independent") ~ "Independent",
      str_detect(party, "Liberal") ~ "Coalition",
      str_detect(party, "National") ~ "Coalition",
      party == "Labor" ~ "Labor",
      party == "Greens" ~ "Greens",
      party == "One Nation" ~ "One Nation",
      party == "United Australia Party" ~ "United Australia Party",
      party == "Katter's Australia Party" ~ "Katter's Australia Party",
      party == "Centre Alliance" ~ "Centre Alliance",
      party == "Coalition" ~ "Coalition",
      party == "Independent" ~ "Independent",
      TRUE ~ "Other"
    ),
  odds_ls = ifelse(odds>50,odds*2,odds)
)

all_states <- 
  all_states %>% 
  mutate(electorate = ifelse(electorate=="Capriconia","Capricornia",electorate))

saveRDS(all_states, paste0(Sys.Date(), "_sb_afe22.rds"))
################################
tictoc::toc()

all_states <- readRDS(paste0(Sys.Date(), "_sb_afe22.rds"))
######################
elec_list <- tibble()
election_date <- as.Date('2022-05-21')
days_to_election <- as.numeric(election_date) - as.numeric(Sys.Date())
sigma <- 0.8 + days_to_election/200

simulate_elec <- function(i,sigma) {
  swing <- rlnorm(1, 0, sigma)
  all_states <-
    all_states %>%
    mutate(swing_adj_win_prob = ifelse(party == "Labor", win_prob * swing, win_prob))
  elec_list <- all_states %>%
    group_by(electorate) %>%
    sample_n(1, weight = swing_adj_win_prob) %>%
    group_by(party
             ,state
             ) %>%
    summarise(count = n()) %>%
    pivot_wider(names_from = c('party'
                               ,'state'
                               ), values_from = count)
  
  return(elec_list)
}

########## SIMULATE
sims <- 500
elec_list <- tibble()
tictoc::tic()
elec_list <- furrr::future_map_dfr(1:sims, ~ simulate_elec(.,sigma), .options = furrr_options(seed = 1234))
tictoc::toc()
elec_list <- elec_list %>% janitor::clean_names()

#######################################################################
# saveRDS(elec_list,paste0(Sys.Date(), "_sb_state_afe22_sims.rds"))
# state_sims <- readRDS(paste0(Sys.Date(), "_sb_state_afe22_sims.rds"))
saveRDS(elec_list,paste0(Sys.Date(), "_sb_afe22_sims.rds"))
###
###
elec_list <- readRDS(paste0(Sys.Date(), "_sb_afe22_sims.rds"))
###################################################################
summary(pmax(elec_list$labor, elec_list$coalition))
summary(elec_list$coalition)
summary(elec_list$labor)
summary(elec_list$coalition + elec_list$labor)
all_states %>%
  group_by(party,state) %>%
  summarise(sum(win_prob)) %>%
  view()
#######################################################
summary(elec_list %>% replace(is.na(.), 0))

elec_list %>%
  mutate(
    most_votes = pmax(labor, coalition),
    majority = ifelse(most_votes >= ceiling(n_distinct(all_states$electorate) / 2), 1, 0),
    labor_win = ifelse(labor > coalition, 1, 0),
    lab_maj = ifelse(labor >= ceiling(n_distinct(all_states$electorate) / 2), 1, 0),
    lib_maj = ifelse(coalition >= ceiling(n_distinct(all_states$electorate) / 2), 1, 0),
    lab_min = ifelse(labor < ceiling(n_distinct(all_states$electorate) / 2) & labor > coalition, 1, 0),
    lib_min = ifelse(coalition < ceiling(n_distinct(all_states$electorate) / 2) & coalition > labor, 1, 0),
    hung = ifelse(labor == coalition, 1, 0)
  ) %>%
  summarise(
    maj = mean(majority), lab_win = mean(labor_win), lab_seats = mean(labor), lib_seats = mean(coalition),
    lab_maj = mean(lab_maj), lib_maj = mean(lib_maj), lab_min = mean(lab_min), lib_min = mean(lib_min),
    hung = mean(hung)
  )

n_distinct(all_states$electorate)

######################
sims <- 3000


test <- all_states %>%
  select(electorate,state,party,odds_ls) %>%
  pivot_wider(names_from = party, values_from = odds_ls, values_fn = {
    min
  })

test[which(test$electorate=="Nicholls"),"Coalition"] <- 1.4

########################
library(implied)

my_odds <- test %>%
  ungroup() %>%
  select(-c(1:2)) %>%
  replace(is.na(.), 9999)

# my_probs <- 1/my_odds
# my_probs %>% mutate(sumVar = rowSums(.[1:9])) %>% view()

res1 <- implied_probabilities(my_odds, method = "power")
# colSums(res1$probabilities)
summary(1 / res1$exponents)

final_odds <- bind_cols(test, as_tibble(res1$probabilities)) %>% janitor::clean_names()
final_odds %>%
  select((ncol(test)+1):ncol(final_odds)) %>%
  colSums()
#library(openxlsx)
#write.xlsx(final_odds %>% select(1:5, 9, 15:17, 21), paste0(Sys.Date(), "_aus_fed_election_2022_odds.xlsx"))
#################################
# elec %>% left_join(tibble(party  = unique(all_states$electorate)),keep = TRUE) %>% view()
###################################

elec_list <- elec_list %>%
  mutate(lab_bin = 
           as.factor(case_when(
             labor <= 10 ~ "<= 10",
             labor <= 20 ~ "011-20",
             labor <= 30 ~ "021-30",
             labor <= 40 ~ "031-40",
             labor <= 45 ~ "041-45",
             labor <= 50 ~ "046-50",
             labor <= 55 ~ "051-55",
             labor <= 60 ~ "056-60",
             labor <= 65 ~ "061-65",
             labor <= 70 ~ "066-70",
             labor <= 75 ~ "071-75",
             labor <= 80 ~ "076-80",
             labor <= 85 ~ "081-85",
             labor <= 90 ~ "086-90",
             labor <= 95 ~ "091-95",
             labor <= 100 ~ "096-100",
             labor <= 110 ~ "101-110",
             labor <= 120 ~ "111-120",
             labor <= 130 ~ "121-130",
             labor <= 140 ~ "131-140",
             labor <= 151 ~ "141-151",
             TRUE ~ "NULL"
           )),
         lib_bin = 
           as.factor(case_when(coalition <= 10 ~ "<= 10",
                               coalition <= 20 ~ "011-20",
                               coalition <= 30 ~ "021-30",
                               coalition <= 40 ~ "031-40",
                               coalition <= 45 ~ "041-45",
                               coalition <= 50 ~ "046-50",
                               coalition <= 55 ~ "051-55",
                               coalition <= 60 ~ "056-60",
                               coalition <= 65 ~ "061-65",
                               coalition <= 70 ~ "066-70",
                               coalition <= 75 ~ "071-75",
                               coalition <= 80 ~ "076-80",
                               coalition <= 85 ~ "081-85",
                               coalition <= 90 ~ "086-90",
                               coalition <= 95 ~ "091-95",
                               coalition <= 100 ~ "096-100",
                               coalition <= 110 ~ "101-110",
                               coalition <= 120 ~ "111-120",
                               coalition <= 130 ~ "121-130",
                               coalition <= 140 ~ "131-140",
                               coalition <= 151 ~ "141-151",
                               TRUE ~ "NULL"
           ))
  )

#######################
elec_list %>% group_by(lib_bin) %>% summarise(sims/n()) %>% view()

###