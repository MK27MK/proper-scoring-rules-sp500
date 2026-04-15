brier_score <- function(prob, outcome) (prob - outcome)^2

log_score <- function(prob, outcome, eps = 1e-6) {
    prob <- pmin(pmax(prob, eps), 1 - eps)
    -(outcome * log(prob) + (1 - outcome) * log(1 - prob))
}