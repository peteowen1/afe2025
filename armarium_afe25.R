library(RSelenium)
library(tidyverse)
library(rvest)
library(httr)
library(furrr)

#############################################

url <- paste0("https://armariuminterreta.com/projects/2022-australian-federal-election-forecast/")
  
armarium_df <- read_html(url) %>%
  html_table()
armarium_df <- armarium_df[[4]] %>% janitor::clean_names() %>% 
  janitor::remove_empty(c("rows", "cols")) %>% janitor::remove_constant()

armarium_df <- armarium_df %>%
  mutate(across(.cols = 2:8, .fns = ~str_replace_all(., "[^[:alnum:]]", ""))) %>%
  mutate(across(.cols = 2:8, .fns = ~as.numeric(.)/100))

colnames(armarium_df) <- paste(colnames(armarium_df), "armarium", sep = "_")

##################### labor
lab_odd_check <- final_odds %>%
  left_join(armarium_df, by = c('electorate'='division_armarium')) %>%
  left_join(aef_df, by = c('electorate'='electorate_aef')) %>%
  left_join(supervoter, by = c('electorate'='name_supervoter')) %>%
  left_join(tab_pivot, by = c('electorate'='location_tab')) %>%
  select(order(colnames(.))) %>% 
  #select(electorate,state,coalition_4,coalition_13,l_nc,lnp,independent_6) %>%
  select(electorate,state,labor_3,labor_12,labor_tab,labor_armarium,alp_aef,labor_supervoter,independent_6) %>%
  mutate(adj_p = 3/(1/labor_armarium + 1/alp_aef + 100/labor_supervoter),
         mx_odds = pmax(labor_tab,labor_3),
         edge = round(adj_p - (1/mx_odds),3),
         kelly = round(adj_p - ((1-adj_p)/(mx_odds-1)),3)) %>%
  # group_by(state) %>%
  # summarise(sum(adj_p),
  #           sum(labor_12),
  #           sum(labor),
  #           sum(alp))
  view()
###################### coalition 
lib_odd_check <- final_odds %>%
  left_join(armarium_df, by = c('electorate'='division_armarium')) %>%
  left_join(aef_df, by = c('electorate'='electorate_aef')) %>%
  left_join(supervoter, by = c('electorate'='name_supervoter')) %>%
  left_join(tab_pivot, by = c('electorate'='location_tab')) %>%
  select(order(colnames(.))) %>%
  select(electorate,state,coalition_4,coalition_13,coalition_tab,l_nc_armarium,lnp_aef,coalition_supervoter,independent_6) %>%
  #select(electorate,state,labor_3,labor_12,labor,alp,independent_6) %>%
  mutate(adj_p = 3/(1/l_nc_armarium + 1/lnp_aef + 100/coalition_supervoter),
         mx_odds = pmax(coalition_tab,coalition_4),
         edge = round(adj_p - (1/mx_odds),3),
         kelly = round(adj_p - (1-adj_p)/(mx_odds-1),3)) %>%
  # group_by(state) %>%
  # summarise(adj_p = sum(adj_p, na.rm = T),
  #           sum(coalition_13),
  #           sum(l_nc),
  #           lnp = sum(lnp, na.rm = T))
  view()

####
# final_odds %>%
#   left_join(armarium_df, by = c('electorate'='division')) %>%
#   left_join(aef_df, by = c('electorate'='electorate')) %>%
#   select(order(colnames(.))) %>%
#   view()

###
state_sims[is.na(state_sims)] <- 0
1/mean(ifelse(state_sims$coalition_nsw<20.5,1,0))
1/mean(ifelse(state_sims$coalition_qld<20.5,1,0))
1/mean(ifelse(state_sims$coalition_sa<3.5,1,0))
1/mean(ifelse(state_sims$coalition_vic>11.5,1,0))
1/mean(ifelse(state_sims$coalition_wa>7.5,1,0))

1/mean(ifelse(state_sims$labor_nsw<23.5,1,0))
1/mean(ifelse(state_sims$labor_qld>7.5,1,0))
1/mean(ifelse(state_sims$labor_sa>5.5,1,0))
1/mean(ifelse(state_sims$labor_vic<23.5,1,0))
1/mean(ifelse(state_sims$labor_wa<7.5,1,0))
#################
final_odds %>% left_join(tab_pivot, by = c('electorate'='location_tab')) %>% filter(state=="wa") %>% view()
