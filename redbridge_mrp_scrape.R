library(tabulapdf)
library(tidyverse)

# 1. Download the PDF
pdf_url  <- "https://b86980f8-eefa-4834-a649-9fbe8b8b3922.usrfiles.com/ugd/b86980_b7c3c1e7e83b4ebfbb4f8c6e7b824f73.pdf"
pdf_file <- tempfile(fileext = ".pdf")
download.file(pdf_url, pdf_file, mode = "wb")

# 2. Draw the box around your Table 1 once on page 28
area_box <- locate_areas(pdf_file, pages = 28)[[1]]
# (draw tightly around the tabular region and click Done)

# 3. Extract that same box on pages 28–33
pages <- 28:33
tabs_raw <- extract_tables(
  file   = pdf_file,
  pages  = pages,
  method = "lattice",
  guess  = FALSE,
  area   = rep(list(area_box), length(pages)),
  output = "tibble"
)

# 4. Normalize each fragment to 11 columns
tabs_norm <- lapply(tabs_raw, function(df) {
  if (ncol(df) == 11) {
    # pages 28–32
    names(df) <- c(
      "state", "division",
      paste0("fp_",  c("coalition","labor","greens","other")),
      paste0("tcp_", c("coalition","labor","greens","other")),
      "outcome"
    )
    df
  } else if (ncol(df) == 10) {
    # page 33: missing state column
    names(df) <- c(
      "division",
      paste0("fp_",  c("coalition","labor","greens","other")),
      paste0("tcp_", c("coalition","labor","greens","other")),
      "outcome"
    )
    df %>%
      mutate(state = NA_character_) %>%
      select(state, everything())
  } else {
    stop("Unexpected number of columns: ", ncol(df))
  }
})

# 5. Bind them all
raw <- bind_rows(tabs_norm)

# 6. Correct any mis‑labeled “state” entries
real_states <- c("ACT","NSW","NT","QLD","SA","TAS","VIC","WA")

cleaned <- raw %>%
  mutate(
    # 6a. Pull any row where state ∉ real_states back into division
    division = if_else(
      !state %in% real_states,
      # if state isn't a real code, and division is NA, use state
      if_else(is.na(division), state, division),
      division
    ),
    # 6b. Only keep genuine state codes in state; drop the rest
    state = if_else(state %in% real_states, state, NA_character_)
  ) %>%
  fill(state) %>%
  filter(division != "Division")   # drop the repeated header row

# 7. Final snake‑case table with all numeric columns typed
table1 <- cleaned %>%
  mutate(across(starts_with("fp_"),  as.integer),
         across(starts_with("tcp_"), as.integer)) %>%
  select(
    state, division,
    fp_coalition, fp_labor, fp_greens, fp_other,
    tcp_coalition, tcp_labor, tcp_greens, tcp_other,
    outcome
  )

# Inspect
print(table1)

write_csv(table1, './data/redbridge_mrp.csv')
