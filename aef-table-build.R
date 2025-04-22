library(jsonlite)
library(tidyverse)

# Load the JSON file
json_data <- fromJSON("all_seats_parsed.json", flatten = TRUE)

# Flatten and tidy the structure
tibble_data <- json_data %>%
  mutate(seat = map_chr(url, ~ str_extract(.x, "[^/]+$"))) %>%
  select(seat, data) %>%
  unnest(data) %>%
  mutate(probability = as.numeric(probability)) %>%
  as_tibble()

# View the tibble
print(tibble_data)

aef_wide <- tibble_data %>%
  # select(-id,-electorate_podds, -podds, -candidate) %>%  # Remove the 'id' column
  pivot_wider(
    names_from = party,  # Each candidate becomes a column
    values_from = probability,     # The price values fill those columns
    values_fn = ~max(.)/100
  ) %>%
  janitor::clean_names()

# View(aef_wide)

write_csv(aef_wide, './data/aef_wide.csv')
