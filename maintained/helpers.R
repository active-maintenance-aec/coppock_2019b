# coppock_2019b/maintained/helpers.R
# Shared packages and helper functions sourced by every script in maintained/.

library(here)
library(tidyverse)
library(estimatr)
library(rsample)

here::i_am("maintained/helpers.R")

# Zhang and Rubin (2003) trimming bounds ----
# Bounds on the average effect among subjects whose outcome is observed under either
# assignment. fail indicates that the outcome is missing, which here means no response.
# The share of failures under each arm sets how far into each observed outcome
# distribution to trim, and the bounds are the differences in trimmed means at the two
# extremes. This reimplements bounds_estimator() from the archive's
# aec_replication_JEPS.R, which the archive in turn adapted from the source code of
# Aronow, Baron and Pinson (2019).
bounds_estimator <- function(y, z, fail, weight) {
  f0 <- sum(weight[fail == 1 & z == 0]) / sum(weight[z == 0])
  f1 <- sum(weight[fail == 1 & z == 1]) / sum(weight[z == 1])

  trim0 <- f1 / (1 - f0)
  trim1 <- f0 / (1 - f1)

  sorted <- tibble(y, z, fail, weight) |> arrange(y)

  observed_0 <- sorted |>
    filter(fail == 0, z == 0) |>
    mutate(weight = weight / sum(weight), cdf = cumsum(weight))
  observed_1 <- sorted |>
    filter(fail == 0, z == 1) |>
    mutate(weight = weight / sum(weight), cdf = cumsum(weight))

  upper_0 <- with(observed_0, weighted.mean(y[cdf > trim0], weight[cdf > trim0]))
  lower_0 <- with(observed_0, weighted.mean(y[cdf < (1 - trim0)], weight[cdf < (1 - trim0)]))
  upper_1 <- with(observed_1, weighted.mean(y[cdf > trim1], weight[cdf > trim1]))
  lower_1 <- with(observed_1, weighted.mean(y[cdf < (1 - trim1)], weight[cdf < (1 - trim1)]))

  tibble(low_est = lower_1 - upper_0, high_est = upper_1 - lower_0)
}

# The bounds applied to the analysis frame's own column names ----
# Every bootstrap replicate calls the estimator on a resampled copy of the same frame,
# so the mapping from column to argument is written once here.
bounds_on_frame <- function(dat) {
  bounds_estimator(
    y = dat$friendly_no_na,
    z = dat$first_name_latino,
    fail = 1 - dat$response_no_na,
    weight = rep(1, nrow(dat))
  )
}
