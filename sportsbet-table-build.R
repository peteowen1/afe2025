# Install packages if needed
# install.packages("jsonlite")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("purrr")

library(jsonlite)
library(tidyverse)
library(implied)

# Read the three JSON files
electorates <- fromJSON("electorates.json")
market_odds <- fromJSON("market_odds.json")
candidates <- fromJSON("candidates_filtered.json")

# Rename common key fields for joining
electorates <- electorates %>% rename(id = dataAutomationId)
candidates <- candidates %>% rename(id = dataAutomationId)

# Join market_odds and candidates by id
joined <- inner_join(market_odds, candidates, by = "id")

# Check that the length of the candidate and prices arrays match for each market.
joined <- joined %>% 
  mutate(
    n_candidates = map_int(candidates, length),
    n_prices = map_int(prices, length)
  )

if(any(joined$n_candidates != joined$n_prices)) {
  warning("Some rows have unequal numbers of candidates and prices!")
}

# Combine candidates and prices into a single outcomes tibble per market.
# This assumes that the i-th candidate corresponds to the i-th price.
joined <- joined %>% 
  mutate(outcomes = map2(candidates, prices, ~ tibble(candidate = .x, price = .y)))

# Unnest the outcomes so each outcome is its own row.
joined_long <- joined %>% unnest(outcomes)

# Join with electorates to add the electorate name for each market id.
final_data <- inner_join(joined_long, electorates, by = "id")

# Rearrange columns as desired.
final_data <- final_data %>% 
  select(id, electorate, candidate, price)

final_data <- 
  final_data %>%
  mutate(
    price = as.numeric(price),
    podds = 1/price #implied_probabilities(price, method = 'power')
  ) %>%
group_by(electorate) %>%
  mutate(
    electorate_podds = sum(podds)
  ) %>%
  ungroup() %>%
  mutate(candidate_adj = stringr::str_replace(candidate, "^Independent \\(.*\\)", "Independent"))

final_data <- final_data %>%
  mutate(candidate = stringr::str_replace(candidate, "^Independent \\(.*\\)", "Independent"))


wider_data <- final_data %>%
  select(-id,-electorate_podds, -podds, -candidate) %>%  # Remove the 'id' column
  pivot_wider(
    names_from = candidate_adj,  # Each candidate becomes a column
    values_from = price,      # The price values fill those columns
    values_fn = ~max(., na.rm=T)
  ) 

wider_data[is.na(wider_data)] <- 999

# Print or view the pivoted data
# View(wider_data)
# 
# lst <- list()
# 
# for (i in 1:nrow(wider_data)) {
#   lst[i] <- implied_probabilities(wider_data[i,2:ncol(wider_data)], method = 'power')
# }
# 
# df <- do.call(rbind, lst)
# colnames(df) <- paste0(colnames(df), "_padj")
# 
# wider_data <- 
#   bind_cols(wider_data, df)
# 
# wider_data %>% 
#   select(contains("_padj")) %>% 
#   summarise(across(everything(), sum))
# 
# View(wider_data)

write_csv(wider_data, './data/sportsbet_wide.csv')

# # Write the merged data to a JSON file.
# write_json(final_data, "merged_data.json", pretty = TRUE)
# cat("Merged data saved to merged_data.json\n")
