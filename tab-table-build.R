library(jsonlite)
library(tibble)
library(dplyr)
library(stringr)

# Read the JSON file into R
raw_data <- fromJSON("tab_politics.json")

# Convert to a tibble and transform the data
df <- as_tibble(raw_data) %>%
  mutate(
    # Extract party (everything before the parenthesis) and trim whitespace.
    party = str_trim(str_remove(party_seat, "\\s*\\(.*"), side = "right"),
    # Extract seat (the text inside the parentheses)
    seat  = tolower(str_extract(party_seat, "(?<=\\().*(?=\\))")),
    # Choose odds from odds_primary if available, otherwise odds_secondary.
    odds  = as.numeric(if_else(is.na(odds_primary), odds_secondary, odds_primary)),
    odds  = replace_na(odds,1),
    # Convert party to lowercase; if it contains "ind" (case-insensitive), set it as "ind"
    party = if_else(str_detect(party, regex("ind", ignore_case = TRUE)), "ind", str_to_lower(party))
  ) %>%
  select(seat, party, odds)

print(df)


wider_data <- df %>%
  filter(!is.na(seat)) %>%
  # select(-id,-electorate_podds, -podds, -candidate) %>%  # Remove the 'id' column
  pivot_wider(
    names_from = party,  # Each candidate becomes a column
    values_from = odds,      # The price values fill those columns
    values_fn = ~max(., na.rm=T)
  )

wider_data[is.na(wider_data)] <- 999

# View(wider_data)

write_csv(wider_data, './data/tab_wide.csv')

