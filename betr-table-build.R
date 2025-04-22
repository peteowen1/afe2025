library(jsonlite)
library(dplyr)

# Load the Betr electorate data from the JSON file
betr_data <- fromJSON("betr_electorate_data.json")

# Convert the data to a tibble and select the columns we need
betr_table <- as_tibble(betr_data) %>%
  select(seat, party, odds)

# Print the table
print(betr_table)

# Process the tibble:
final_table <- betr_table %>%
  # First, isolate the portion before the newline for further processing.
  mutate(seat_full = str_split_fixed(seat, "\n", 2)[,1]) %>%
  # Extract the state abbreviation from the seat_full using a regex.
  mutate(state = str_extract(seat_full, "(NSW|VIC|QLD|WA|SA|ACT|TAS|NT)")) %>%
  # Clean up the seat: take text before " - ", convert to lower case, replace spaces with dashes.
  mutate(seat = str_split_fixed(seat_full, " - ", 2)[,1] %>% tolower() %>% str_replace_all(" ", "-")) %>%
  # Optionally, drop the intermediate column.
  select(seat, state, party, odds)


final_table <- final_table %>%
  mutate(
    # Convert to lowercase, replace spaces with underscores
    party = tolower(party),
    party = str_replace_all(party, "\\s+", "_"),
    # If the party string starts with "independent", force it to "independent"
    party = if_else(str_detect(party, "^independent"), "independent", party),
    odds = as.numeric(odds)
  )

print(final_table)

wider_data <- final_table %>%
  # select(odds, -candidate) %>%  # Remove the 'id' column
  pivot_wider(
    names_from = party,  # Each candidate becomes a column
    values_from = odds,      # The price values fill those columns
    values_fn = ~max(., na.rm=T)
  )

wider_data[is.na(wider_data)] <- 999


write_csv(wider_data, './data/betr_wide.csv')
