source("src/market_data.R")

get_streaks <- function(returns) {
    signs <- sign(returns)
    signs <- signs[signs != 0] # remove 0s
    r <- rle(signs)
    r$lengths * r$values
}

returns <- get_sp_returns()
streaks <- get_streaks(returns)

hist(returns, breaks = 50, col="blue", title="Streaks of pos/neg returns")
barplot(table(streaks))
