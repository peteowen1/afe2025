# ──────────────────────────────────────────────────────────────────────────────
# 0. Install & load packages
# ──────────────────────────────────────────────────────────────────────────────
# install.packages(c("httr","jsonlite","dplyr","tidyr","purrr","tibble","stringr","glue"))
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(tibble)
library(stringr)
library(glue)

# ──────────────────────────────────────────────────────────────────────────────
# 1. Fetch & parse JSON
# ──────────────────────────────────────────────────────────────────────────────
url <- "https://d2qblwfsxsgzx.cloudfront.net/au_election_2025/versions/9547879f204b43f28d788cdfd167c35d/constituency_data.json"
res <- GET(url)
stop_for_status(res)
js  <- fromJSON(content(res, as="text", encoding="UTF-8"),
                simplifyVector=FALSE)

# ──────────────────────────────────────────────────────────────────────────────
# 2. Build a helper tibble of raw list-elements
# ──────────────────────────────────────────────────────────────────────────────
df2 <- enframe(js, name="constituency", value="content") %>%
  transmute(
    constituency,
    fp_data      = map(content, "data"),       # list of 6 rows: id/share/low/high
    tpp_data     = map(content, "data_tpp"),   # list of 2 rows: id/share
    winner_tpp   = map_chr(content, "winner_tpp"),
    swing_amount = map_dbl(content, "swing_amount")
  )

# ──────────────────────────────────────────────────────────────────────────────
# 3. First-prefs → wide (one row per seat, 6 parties × (share, lo, hi))
# ──────────────────────────────────────────────────────────────────────────────
wide_fp <- df2 %>%
  select(constituency, fp_data) %>%
  mutate(
    # turn each fp_data[[i]] (a list of 6) into a tiny 6×4 tibble
    tbl = map(fp_data, ~ map_df(.x, ~ tibble(
      party = .x$id,
      share = .x$share,
      low   = .x$low,
      high  = .x$high
    )))
  ) %>%
  select(-fp_data) %>%
  unnest(tbl) %>%
  pivot_wider(
    id_cols     = constituency,
    names_from  = party,
    values_from = c(share, low, high),
    names_glue  = "{party}_{.value}"
  ) %>%
  # rename low→lo, high→hi
  rename_with(~ str_replace(.x, "_low$",  "_lo"), ends_with("_low")) %>%
  rename_with(~ str_replace(.x, "_high$", "_hi"), ends_with("_high"))

# ──────────────────────────────────────────────────────────────────────────────
# 4. Two-party prefs → wide (labor_tcp_share, coalition_tcp_share)
# ──────────────────────────────────────────────────────────────────────────────
wide_tpp <- df2 %>%
  select(constituency, tpp_data) %>%
  mutate(
    tbl = map(tpp_data, ~ map_df(.x, ~ tibble(
      party = .x$id,
      share = .x$share
    )))
  ) %>%
  select(-tpp_data) %>%
  unnest(tbl) %>%
  pivot_wider(
    id_cols     = constituency,
    names_from  = party,
    values_from = share,
    names_glue  = "{party}_tcp_share"
  ) %>%
  # ensure the other two TPP columns exist (will be NA)
  mutate(
    greens_tcp_share      = coalesce(greens_tcp_share, NA_real_),
    other_tcp_share       = coalesce(other_tcp_share,  NA_real_)
  )

# ──────────────────────────────────────────────────────────────────────────────
# 5. Join & compute the extra columns
# ──────────────────────────────────────────────────────────────────────────────
final_df <- wide_fp %>%
  left_join(wide_tpp,       by="constituency") %>%
  left_join(df2,            by="constituency") %>%  # brings in winner_tpp & swing_amount
  mutate(
    # standardized winner
    tpp_winner25              = str_to_title(winner_tpp),
    # rounded absolute swing
    lab_coalition_tpp_swing25 = round(abs(swing_amount)),
    # margin = winner’s TPP minus loser’s
    margin                    = case_when(
      winner_tpp == "labor"     ~ labor_tcp_share   - coalition_tcp_share,
      TRUE                       ~ coalition_tcp_share - labor_tcp_share
    ),
    # call based on margin
    you_gov_call = case_when(
      margin > 10 ~ glue("Safe {tpp_winner25}"),
      margin >  3 ~ glue("Likely {tpp_winner25}"),
      TRUE        ~ glue("Marginal {tpp_winner25}")
    ),
    # ranges & “margin of error” (MRP = half the width)
    lab_range      = labor_hi   - labor_lo,
    coa_range      = coalition_hi - coalition_lo,
    labor_mrp = round(1 - pnorm(0, (labor_tcp_share - 50) , lab_range^0.7), 3),
    coalition_mrp = round(1 - pnorm(0, (coalition_tcp_share - 50) , lab_range^0.7), 3),
    # duplicate constituency in both ced & seat
    ced            = constituency,
    seat           = constituency
  ) %>%
  # rename “onenation” → “one_nation” to match your example
  rename(
    one_nation_share = onenation_share,
    one_nation_lo    = onenation_lo,
    one_nation_hi    = onenation_hi
  ) %>%
  # final column order
  select(
    ced,
    tpp_winner25,
    you_gov_call,
    lab_coalition_tpp_swing25,

    coalition_share, coalition_lo, coalition_hi,
    greens_share,    greens_lo,    greens_hi,
    independent_share, independent_lo, independent_hi,
    labor_share,     labor_lo,     labor_hi,
    one_nation_share, one_nation_lo, one_nation_hi,
    other_share,     other_lo,      other_hi,

    labor_tcp_share,    coalition_tcp_share,
    greens_tcp_share,   other_tcp_share,

    lab_range,         labor_mrp,
    coa_range,         coalition_mrp,

    seat
  )

# ──────────────────────────────────────────────────────────────────────────────
# 6. View & save
# ──────────────────────────────────────────────────────────────────────────────
glimpse(final_df)
write_csv(final_df, "./data/yougov_mrp.csv")
# saveRDS(final_df, "yougov_wide.rds")
