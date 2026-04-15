# Naive - flat 50% probability to every day
# Returns a constant p=0.5 vector of length = num_of_days
naive_strategy <- function(num_of_days) {
    rep(0.5, num_of_days)
}

# Shifted by one day to avoid look-ahead bias: probs[t] uses labels[1:(t-1)].
cumulative_frequency_strategy <- function(return_labels) {
    num_of_days <- length(return_labels)
    trimmed_returns <- return_labels[1:(num_of_days - 1)]

    c(NA_real_, cumsum(trimmed_returns) / 1:(num_of_days - 1))
}

# Shifted window: probs[t] uses labels[(t - window_len):(t - 1)].
moving_average_strategy <- function(return_labels, window_len = 10) {
    num_of_days <- length(return_labels)
    probs <- rep(NA_real_, num_of_days)

    for (t in seq(from = window_len + 1, to = num_of_days)) {
        probs[t] <- mean(return_labels[(t - window_len):(t - 1)])
    }
    probs
}

# Dishonest - exaggerate the probability estimate.
dishonest_strategy <- function(prob_freq) ifelse(prob_freq > 0.5, 0.9, 0.1)

contrarian_strategy <- function(return_labels) {
    num_of_days <- length(return_labels)
    c(NA_real_, 1 - return_labels[-num_of_days])
}

momentum_strategy <- function(return_labels) {
    num_of_days <- length(return_labels)
    c(NA_real_, return_labels[-num_of_days])
}
