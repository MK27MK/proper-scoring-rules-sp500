get_sp_returns <- function() {
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

    returns
}
