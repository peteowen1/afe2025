library(tidyverse)
devtools::load_all()

aef_weight <- 0.7

sportsbet_df <- read_csv('./data/sportsbet_wide.csv')  %>%
  separate_wider_delim (electorate,'(',names = c('seat','state')) %>%
  janitor::clean_names() %>%
  mutate(
    state = gsub(")","",state),
    seat = str_to_lower(str_trim(seat)),
    seat = gsub(" ","-",seat),
    lab_p = 1/labor,
    coa_p = 1/coalition
    )

tab_df <- read_csv('./data/tab_wide.csv')  %>%
  # separate_wider_delim (electorate,'(',names = c('seat','state')) %>%
  janitor::clean_names() %>%
  mutate(
    # state = gsub(")","",state),
    # seat = str_to_lower(str_trim(seat)),
    seat = gsub(" ","-",seat),
    lab_p = 1/labor,
    coa_p = 1/coalition
  )

betr_df <- read_csv('./data/betr_wide.csv')  %>%
  # separate_wider_delim (electorate,'(',names = c('seat','state')) %>%
  janitor::clean_names() %>%
  mutate(
    # state = gsub(")","",state),
    # seat = str_to_lower(str_trim(seat)),
    seat = gsub(" ","-",seat),
    lab_p = 1/labor,
    coa_p = 1/coalition
  )

aef_df <- read_csv('./data/aef_wide.csv') %>%
  mutate(
    coa = replace_na(nat,0) + replace_na(lib,0),
    two_party = alp + coa,
    seat = gsub(" ","-",seat)
  )

yougov_df <- readxl::read_xlsx('./data/Publication-Version-SeatLevel-Resultsmarch30.xlsx') %>%
  janitor::clean_names() %>%
  mutate(
    lab_range = labor_hi - labor_lo,
    labor_mrp = round(1 - pnorm(0, (labor_tcp_share - 50) , lab_range^0.7), 3),
    coa_range = coalition_hi - coalition_lo,
    coalition_mrp = round(1 - pnorm(0, (coalition_tcp_share - 50) , coa_range^0.7), 3),
    seat = gsub(" ","-",str_to_lower(str_trim(ced)))
  )

###
sb_bet_df <-
  sportsbet_df %>% select(seat,state,labor,lab_p,coalition, coa_p) %>%
  left_join(
    aef_df %>% select(seat, alp, coa, two_party)
  ) %>%
  left_join(
    yougov_df %>% select(seat, labor_mrp, coalition_mrp)
  ) %>%
  mutate(
    labor = pmax(labor,1.001),
    lab_prob = pmax(replace_na(alp*aef_weight+labor_mrp*(1-aef_weight),0.001),0.001),
    coa_prob = pmax(replace_na(coa*aef_weight+coalition_mrp*(1-aef_weight),0.001),0.001),
    lab_diff = round(lab_prob - lab_p,3),
    coa_diff = round(coa_prob - coa_p,3),
    kelly_lab = kelly_proportion(lab_prob,labor)
    )

View(sb_bet_df)

###
tab_bet_df <-
  tab_df %>% select(seat,labor,lab_p,coalition, coa_p) %>%
  left_join(
    aef_df %>% select(seat, alp, coa, two_party)
  ) %>%
  left_join(
    yougov_df %>% select(seat, labor_mrp, coalition_mrp)
  ) %>%
  mutate(
    lab_prob = pmax(replace_na(alp*aef_weight+labor_mrp*(1-aef_weight),0.001),0.001),
    coa_prob = pmax(replace_na(coa*aef_weight+coalition_mrp*(1-aef_weight),0.001),0.001),
    lab_diff = round(lab_prob - lab_p,3),
    coa_diff = round(coa_prob - coa_p,3),
    kelly_lab = kelly_proportion(lab_prob,labor)
  )

View(tab_bet_df)

###
betr_bet_df <-
  betr_df %>% select(seat,state,labor,lab_p,coalition, coa_p) %>%
  left_join(
    aef_df %>% select(seat, alp, coa, two_party)
  ) %>%
  left_join(
    yougov_df %>% select(seat, labor_mrp, coalition_mrp)
  ) %>%
  mutate(
    lab_prob = pmax(replace_na(alp*aef_weight+labor_mrp*(1-aef_weight),0.001),0.001),
    coa_prob = pmax(replace_na(coa*aef_weight+coalition_mrp*(1-aef_weight),0.001),0.001),
    lab_diff = round(lab_prob - lab_p,3),
    coa_diff = round(coa_prob - coa_p,3),
    kelly_lab = kelly_proportion(lab_prob,labor)
  )

View(betr_bet_df)
