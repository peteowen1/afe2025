library(tidyverse)
devtools::load_all()

aef_weight <- 0.6
yg_weight <- 0.2
rb_weight <- 0.2

sportsbet_df <- read_csv('./data/sportsbet_wide.csv')  %>%
  separate_wider_delim (electorate,'(',names = c('seat','state')) %>%
  janitor::clean_names() %>%
  mutate(
    state = gsub(")","",state),
    seat = str_to_lower(str_trim(seat)),
    seat = gsub(" ","-",seat),
    lab_p = round(1/labor,3),
    coa_p = round(1/coalition,3)
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
    tp = alp + coa,
    seat = gsub(" ","-",seat)
  )

yougov_df <- readr::read_csv('./data/yougov_mrp.csv') %>%
  janitor::clean_names() %>%
  mutate(
    lab_range = labor_hi - labor_lo,
    lab_mrp_yg = round(1 - pnorm(0, (labor_tcp_share - 50) , lab_range^0.7), 3),
    coa_range = coalition_hi - coalition_lo,
    coa_mrp_yg = round(1 - pnorm(0, (coalition_tcp_share - 50) , coa_range^0.7), 3),
    seat = gsub(" ","-",str_to_lower(str_trim(ced)))
  )

redbridge_df <- readr::read_csv('./data/redbridge_mrp.csv') %>%
  janitor::clean_names() %>%
  mutate(
    lab_range = 9, #labor_hi - labor_lo,
    lab_mrp_rb = round(1 - pnorm(0, (tcp_labor - 50) , lab_range^0.7), 3),
    coa_range = 9, #coalition_hi - coalition_lo,
    coa_mrp_rb = round(1 - pnorm(0, (tcp_coalition - 50) , coa_range^0.7), 3),
    seat = gsub(" ","-",str_to_lower(str_trim(division)))
  )

###
sb_bet_df <-
  sportsbet_df %>% select(seat,state,labor,lab_p,coalition, coa_p) %>%
  left_join(
    aef_df %>% select(seat, alp, coa, tp)
  ) %>%
  left_join(
    yougov_df %>% select(seat, lab_tp_yg = labor_tcp_share, lab_mrp_yg, coa_mrp_yg)
  ) %>%
  left_join(
    redbridge_df %>% select(seat, lab_tp_rb = tcp_labor, lab_mrp_rb, coa_mrp_rb)
  ) %>%
  mutate(
    labor = pmax(labor,1.001),
    lab_prob = pmax(replace_na(alp*aef_weight + lab_mrp_yg*yg_weight + lab_mrp_rb*rb_weight,0.001),0.001),
    coa_prob = pmax(replace_na(coa*aef_weight + coa_mrp_yg*yg_weight + coa_mrp_rb*rb_weight,0.001),0.001),
    lab_diff = round(lab_prob - lab_p,3),
    coa_diff = round(coa_prob - coa_p,3),
    kelly_lab = kelly_proportion(lab_prob,labor)
    ) %>%
  arrange(-kelly_lab)

View(sb_bet_df)

###
tab_bet_df <-
  tab_df %>% select(seat,labor,lab_p,coalition, coa_p) %>%
  left_join(
    aef_df %>% select(seat, alp, coa, tp)
  ) %>%
  left_join(
    yougov_df %>% select(seat, lab_tp_yg = labor_tcp_share, lab_mrp_yg, coa_mrp_yg)
  ) %>%
  left_join(
    redbridge_df %>% select(seat, lab_tp_rb = tcp_labor, lab_mrp_rb, coa_mrp_rb)
  ) %>%
  mutate(
    lab_prob = pmax(replace_na(alp*aef_weight + lab_mrp_yg*yg_weight + lab_mrp_rb*rb_weight,0.001),0.001),
    coa_prob = pmax(replace_na(coa*aef_weight + coa_mrp_yg*yg_weight + coa_mrp_rb*rb_weight,0.001),0.001),
    lab_diff = round(lab_prob - lab_p,3),
    coa_diff = round(coa_prob - coa_p,3),
    kelly_lab = kelly_proportion(lab_prob,labor)
  ) %>%
  arrange(-kelly_lab)

View(tab_bet_df)

###
betr_bet_df <-
  betr_df %>% select(seat,state,labor,lab_p,coalition, coa_p) %>%
  left_join(
    aef_df %>% select(seat, alp, coa, tp)
  ) %>%
  left_join(
    yougov_df %>% select(seat, lab_tp_yg = labor_tcp_share, lab_mrp_yg, coa_mrp_yg)
  ) %>%
  left_join(
    redbridge_df %>% select(seat, lab_tp_rb = tcp_labor, lab_mrp_rb, coa_mrp_rb)
  ) %>%
  mutate(
    lab_prob = pmax(replace_na(alp*aef_weight + lab_mrp_yg*yg_weight + lab_mrp_rb*rb_weight,0.001),0.001),
    coa_prob = pmax(replace_na(coa*aef_weight + coa_mrp_yg*yg_weight + coa_mrp_rb*rb_weight,0.001),0.001),
    lab_diff = round(lab_prob - lab_p,3),
    coa_diff = round(coa_prob - coa_p,3),
    kelly_lab = kelly_proportion(lab_prob,labor)
  ) %>%
  arrange(-kelly_lab)

View(betr_bet_df)
