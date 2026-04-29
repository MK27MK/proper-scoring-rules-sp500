# Proper Scoring Rules — S&P 500 directional forecasts

> This README is an AI generated translation of the [original Italian version](README-IT.md), written by me.

## How to run

From the project directory:

```bash
Rscript src/main.R
```

---

## Introduction

Before introducing the definition of a **scoring rule**, let us recall the definition of a **probability space**:

> [!IMPORTANT]
> A probability space is a triple $(\Omega, \mathcal{F}, \mathcal{P})$ that models a random experiment.
> In particular:
>
> - $\Omega$ is the sample space, the set of elementary outcomes.
> - $\mathcal{F}$ is a collection of events forming a $\sigma$-algebra over $\Omega$.
> - $P$ is a probability function that assigns to each event $E \in \mathcal{F}$ a probability $p \in [0,1]$.

## Definition of a Scoring rule

Now, suppose we do not have a single probability function $P$, but rather a set $\mathcal{P}$ of probability functions defined on $(\Omega, \mathcal{F})$. We can then define a generic **scoring rule** $s$ as:

$$s: \mathcal{P}\times\Omega \rightarrow \mathbb{R}$$

$s$ is therefore a function that assigns a penalty to a probabilistic forecast, determined by a probability function $P \in \mathcal{P}$, based on the actually observed outcome.

### Properness

A scoring rule is said to be **proper** if the expected score is **minimized** when the probability distribution evaluated by the forecaster matches the one they choose to announce.

In other words, the forecaster is encouraged to report their actual **degree of belief** in order to minimize the penalty.

> [!WARNING]
> Remember that scoring rules are penalty functions with negative orientation; therefore, the lower the expected score $\mathbb{E}[s(P, \omega)]$, the better.

Formally, let $P$ be the distribution the forecaster evaluates ($P$ is honest), and $Q$ any alternative distribution that the forecaster announces. The scoring rule $s$ is **proper** if:

$$
\mathbb{E}_{P}[s(P, \omega)] \leq \mathbb{E}_{P}[s(Q, \omega)] \quad \text{for all } P, Q \in \mathcal{P}
$$

That is, the average penalty under the true distribution $P$ is **at most** equal to that under the distribution $Q$.

#### Strict Properness

If the equality:

$$\mathbb{E}_{P}[s(P, \omega)] = \mathbb{E}_{P}[s(Q, \omega)]$$

holds only for $P=Q$, then the scoring rule is **strictly proper**.

---

## Scoring rules used

### Brier Score

#### General case

Suppose an event can fall into $R$ mutually exclusive classes. Let $p_i$ denote the forecast probability for class $i$, and $o_i$ the observed outcome, where $o_i = 1$ if class $i$ occurred, $0$ otherwise. The Brier score for a single observation is defined as:

$$
\text{BS} =\sum_{i=1}^{R}(p_i - o_i)^2
$$

#### Binary case

In the binary case ($R = 2$), there are two classes: event $E$ occurs ($i = 1$), or it does not ($i = 2$). We can therefore write a simplified formulation using the indicator $|E|$:

$$
\text{BS} = (p - |E|)^2
$$

> [!TIP]
> Suppose we want to forecast the event R="It will rain tomorrow", assigning it a probability $p$:
>
> - $p = 1 \text{ and it rains} \Rightarrow \text{BS} = (1-1)^2 = 0$. The best possible score.
> - $p = 1 \text{ and it does not rain} \Rightarrow \text{BS} = (0-1)^2 = 1$. The worst possible score.
> - $p = 0.5 \text{ and (it rains or not)} \Rightarrow \text{BS} = (1 - 0.5)^2=(0-0.5)^2=0.25$. In this case the score is $0.25$ regardless of the observed outcome.

> [!IMPORTANT]
> When applying the general formula to the binary case, the result will be **twice** that obtained via the simplified formulation.

Note that the Brier score, in the best case — i.e., when the forecast probability **matches** the observed outcome — equals $0$. Keeping this in mind will be useful when defining a **proper scoring rule**.

### Logarithmic Score

#### General case

As with the Brier score, suppose an event can fall into $R$ mutually exclusive classes, with $p_i$ the forecast probability and $o_i$ the observed outcome for class $i$. The Logarithmic score for a single observation is defined as:

$$
\text{LS} = -\sum_{i=1}^{R} o_i\log(p_i)
$$

#### Binary case

In the binary case ($R = 2$), the formula reduces to:

$$
\text{LS} = -\left[|E| \cdot\log(p) + (1 - |E|)\cdot\log(1 - p)\right]
$$

> [!TIP]
> Consider again the event R="It will rain tomorrow", with forecast probability $p$:
>
> - $p = 1 \text{ and it rains} \Rightarrow \text{LS} = -\left[1 \cdot \log(1) + 0  \cdot \log(0) \right]=-\log(1) = 0$. The best possible score.
> - $p = 0.5 \text{ and it rains} \Rightarrow \text{LS} = -\log(0.5) \approx 0.693$.
> - $p = 0.01 \text{ and it rains} \Rightarrow \text{LS} = -\log(0.01) \approx 4.605$. Very high penalty.

> [!IMPORTANT]
> Unlike the Brier score, the Logarithmic score is **not bounded above**: a forecast $p \to 0$ for an event that actually occurs yields $\text{LS} \to +\infty$. This makes the log score particularly harsh towards "dishonest" forecasts.

---

## Experimental setup

### Data

The data, daily OHLC aggregations for the S&P 500 index, are contained in the file [`sp500_ohlc.csv`](sp500_ohlc.csv), downloaded from Yahoo Finance. The file covers the period 2015-2024.

Daily arithmetic returns are computed from closing prices:

$$r_t = \frac{P_t - P_{t-1}}{P_{t-1}}$$

Strategies are evaluated over the entire time series: each forecast $p_t$ is produced using only information available up to day $t-1$, thereby avoiding *look-ahead bias*.

### Binary event

$$Y_t = \begin{cases} 1 & \text{if the return on day } t \text{ is positive} \\ 0 & \text{otherwise} \end{cases}$$

### Forecasting strategies

Each strategy produces a probability $p_t \in (0, 1)$ of an upward move on day $t$:

1. **Naive**: $p_t = 0.5$ constant, serves as a benchmark.

2. **Cumulative** (cumulative frequency): cumulative mean of past outcomes.
3. **MovingAvg10** (moving average): frequency of upward moves in the window of the last $10$ days.

---

## Output and results

The code produces a summary table in the terminal and four PNG plots in the [`results/`](results/) folder.

### Summary table

| Strategy    | Mean Brier | Mean Log |
| ----------- | ---------- | -------- |
| Naive       | 0.25000    | 0.69315  |
| Cumulative  | 0.24951    | 0.69676  |
| MovingAvg10 | 0.27196    | 0.74583  |

### Cumulative Brier Score

![Cumulative Brier Score](results/brier_cumulative.png)

### Cumulative mean Brier Score

![Cumulative mean Brier Score](results/brier_mean_cumulative.png)

### Cumulative Log Score

![Cumulative Log Score](results/log_cumulative.png)

### Cumulative mean Log Score

![Cumulative mean Log Score](results/log_mean_cumulative.png)

## Conclusions

Since the cumulative frequency of upward moves $p_t^{\text{Cum}}$ stabilizes very close to $0.5$, the **Cumulative** and **Naive** strategies achieve nearly equivalent scores, with a slight penalization of the Cumulative strategy on the log score due to greater variability in the earliest observations.

The **MovingAvg10**, despite being more reactive, pays the price of the short window's noise: it produces estimates further from $0.5$ and is punished by the scoring rules.
