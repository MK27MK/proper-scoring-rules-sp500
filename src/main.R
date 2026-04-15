# ======================================================================
# Proper Scoring Rules - S&P 500 Directional forecast
# ======================================================================
source("src/market_data.R")
source("src/strategies.R")
source("src/scoring_rules.R")

returns <- get_sp_returns()

# Binary outcome: was the day's return positive?
# 1 if the return is strictly positive, 0 otherwise.
return_labels <- as.numeric(returns > 0)
num_of_days <- length(return_labels)

strategies <- list(
  "Naive" = naive_strategy(num_of_days),
  "Cumulative" = cumulative_frequency_strategy(return_labels),
  "MovingAvg10" = moving_average_strategy(return_labels, window_len = 10)
  # "Momentum" = momentum_strategy(return_labels),
  # "Contrarian" = contrarian_strategy(return_labels)
)

cum_score <- function(score_vec) cumsum(ifelse(is.na(score_vec), 0, score_vec))

brier_cumulative <- lapply(strategies, function(prob) cum_score(brier_score(prob, return_labels)))
brier_mean_cumulative <- lapply(brier_cumulative, function(s) s / seq_along(s))
log_cumulative <- lapply(strategies, function(prob) cum_score(log_score(prob, return_labels)))
log_mean_cumulative <- lapply(log_cumulative, function(s) s / seq_along(s))

# Summary table --------------------------------------------------------

cat("\n============================================================\n")
cat("  RESULTS - Proper Scoring Rules on S&P 500 (2020-2024)\n")
cat("============================================================\n\n")
cat(sprintf("%-16s %12s %12s\n", "Strategy", "Mean Brier", "Mean Log"))
cat(paste(rep("-", 53), collapse = ""), "\n")

for (name in names(strategies)) {
  prob <- strategies[[name]]
  mean_brier <- mean(brier_score(prob, return_labels), na.rm = TRUE)
  mean_log <- mean(log_score(prob, return_labels), na.rm = TRUE)
  cat(sprintf("%-16s %12.5f %12.5f\n", name, mean_brier, mean_log))
}

# Plots ----------------------------------------------------------------

strategy_names <- names(strategies)
SAVE_PLOTS <- TRUE
colors <- c("gray40", "steelblue", "seagreen", "darkorange", "firebrick")

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
