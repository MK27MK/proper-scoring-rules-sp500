# ======================================================================
# Proper Scoring Rules - S&P 500 Directional Forecasts
# ======================================================================

# Data -----------------------------------------------------------------
# Read OHLC data from CSV (downloaded from Yahoo Finance, 2015-2024)
sp500 <- read.csv("sp500_ohlc.csv", stringsAsFactors = FALSE)
sp500$Date <- as.Date(sp500$Date)

# Daily simple returns on the closing price
closes <- sp500$Close
returns <- diff(closes) / closes[-length(closes)] # (P_t - P_{t-1}) / P_{t-1}

# Having N closing price observations, we can calculate N-1 returns, since
# close_1 and close_2 contribute to the first one at date_2,
# close_2 and close_3 to the second at date_3, and so on,
# we need to remove date_1.
dates <- sp500$Date[-1]

# Binary outcome: was the day's return positive?
# 1 if the return is strictly positive, 0 otherwise.
return_labels <- as.numeric(returns > 0)

# A simple 50/50 split: training (2015-2019), test (2020-2024)
train_indices <- which(dates <= as.Date("2019-12-31"))
test_indices <- which(dates > as.Date("2019-12-31"))

# Positive and non-positive (they could be = 0) days during training and
# testing periods
return_labels_train <- return_labels[train_indices]
return_labels_test <- return_labels[test_indices]
returns_test <- returns[test_indices]
dates_test <- dates[test_indices]
num_test_days <- length(return_labels_test)

# forecasting strategies -----------------------------------------------

# Naive - flat 50% probability to every day
prob_naive <- rep(0.5, num_test_days)

# Frequentist - use the historical proportion of positive days observed
# in the training set as a constant forecast. p=(positive_days/all_days)
hist_frequency <- mean(return_labels_train)
prob_freq <- rep(hist_frequency, num_test_days)

# Dishonest - exaggerate the frequentist's estimate.
prob_dishonest <- ifelse(prob_freq > 0.5, 0.9, 0.1)

# scoring rules --------------------------------------------------------

brier_score <- function(prob, outcome) (prob - outcome)^2

log_score <- function(prob, outcome) {
  -(outcome * log(prob) + (1 - outcome) * log(1 - prob))
}

strategies <- list(
  "Naive" = prob_naive,
  "Frequentist" = prob_freq,
  "Dishonest" = prob_dishonest
)

# Cumulative and running-mean scores for each strategy
brier_cumulative <- lapply(strategies, function(prob) {
  cumsum(brier_score(prob, return_labels_test))
})
brier_mean_cumulative <- lapply(strategies, function(prob) {
  cumsum(brier_score(prob, return_labels_test)) / (1:num_test_days)
})
log_cumulative <- lapply(strategies, function(prob) {
  cumsum(log_score(prob, return_labels_test))
})
log_mean_cumulative <- lapply(strategies, function(prob) {
  cumsum(log_score(prob, return_labels_test)) / (1:num_test_days)
})

# Summary table --------------------------------------------------------

cat("\n============================================================\n")
cat("  RESULTS - Proper Scoring Rules on S&P 500 (2020-2024)\n")
cat("============================================================\n\n")
cat(sprintf("%-16s %12s %12s\n", "Strategy", "Mean Brier", "Mean Log"))
cat(paste(rep("-", 53), collapse = ""), "\n")

for (name in names(strategies)) {
  prob <- strategies[[name]]
  mean_brier <- mean(brier_score(prob, return_labels_test))
  mean_log <- mean(log_score(prob, return_labels_test))
  cat(sprintf("%-16s %12.5f %12.5f\n", name, mean_brier, mean_log))
}

# Plots ----------------------------------------------------------------

strategy_names <- names(strategies)
SAVE_PLOTS <- TRUE
colors <- c("gray40", "steelblue", "darkorange")

# Plot helper function: draws one score series per strategy on the same
# axes, with a legend and grid. Saves PNG to results/.
plot_scores <- function(data_list, ylab, main, legend_pos = "topleft",
                        filename = NULL, ylim_zero = FALSE) {
  if (SAVE_PLOTS && !is.null(filename)) {
    png(file.path("results", filename), width = 10, height = 6, units = "in", res = 150)
  }

  if (ylim_zero) {
    ylim <- c(0, max(sapply(data_list, max)) * 1.05)
  } else {
    ylim <- range(sapply(data_list, range))
  }

  plot(data_list[[1]],
    type = "l", col = colors[1], lwd = 2,
    xlab = "Trading day", ylab = ylab, main = main, ylim = ylim
  )
  for (i in 2:length(data_list)) {
    lines(data_list[[i]], col = colors[i], lwd = 2)
  }
  legend(legend_pos, legend = strategy_names, col = colors, lwd = 2, cex = 0.8)
  grid()

  if (SAVE_PLOTS && !is.null(filename)) invisible(dev.off())
}

# ----------------------------------------------------------------------

plot_scores(brier_cumulative, "Cumulative Brier Score",
  "Cumulative Brier Score - S&P 500 (2020-2024)",
  "topleft", "brier_cumulative.png",
  ylim_zero = TRUE
)

plot_scores(
  brier_mean_cumulative, "Running Mean Brier Score",
  "Running Mean Brier Score - S&P 500 (2020-2024)",
  "topright", "brier_mean_cumulative.png"
)

plot_scores(log_cumulative, "Cumulative Log Score",
  "Cumulative Log Score - S&P 500 (2020-2024)",
  "topleft", "log_cumulative.png",
  ylim_zero = TRUE
)

plot_scores(
  log_mean_cumulative, "Running Mean Log Score",
  "Running Mean Log Score - S&P 500 (2020-2024)",
  "topright", "log_mean_cumulative.png"
)
