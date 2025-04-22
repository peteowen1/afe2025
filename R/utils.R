#' Kelly Criterion Proportion Calculator (Vectorized)
#'
#' Calculates the optimal proportion of bankroll to wager using the Kelly criterion.
#'
#' @param prob_win Numeric vector. The probability of winning the bet (between 0 and 1).
#' @param odds Numeric vector. The decimal odds offered by the bookmaker (must be > 0).
#'
#' @return Numeric vector. The recommended fraction of the bankroll to wager.
#' If the result is <= 0, no bet should be placed.
#'
#' @examples
#' kelly_proportion(c(0.6, 0.55), c(2.5, 1.91))
#'
#' @export
kelly_proportion <- function(prob_win, odds) {
  if (any(prob_win < 0 | prob_win > 1, na.rm = TRUE)) {
    stop("All probabilities must be between 0 and 1.")
  }
  if (any(odds <= 0, na.rm = TRUE)) {
    stop("All odds must be greater than 0.")
  }

  b <- odds - 1
  q <- 1 - prob_win
  kelly <- (b * prob_win - q) / b

  # Set negative or NA values to 0
  kelly[is.na(kelly) | kelly < 0] <- 0

  return(kelly)
}
