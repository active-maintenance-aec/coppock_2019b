# coppock_2019b/maintained/text_bootstrap_sampler.R
# Output: output/text_bootstrap_sampler.csv
# Depends on: clean_voterID.R output, helpers.R
# Description: Why the published bootstrap confidence interval on the bounds does not
#   come back exactly on current R. R 3.6.0 changed how sample() turns uniform draws
#   into integers, so the same seed selects different resamples than it did in 2018.
#   This script recomputes the interval three ways: the way the maintained rewrite does
#   it, the way the archive draws its resamples under the current sampler, and the way
#   the archive drew them under the pre-3.6 sampler. Only the third reproduces the
#   published interval, which locates the drift in R rather than in the deposit.
source(here::here("maintained", "helpers.R"))

wnf_subset <- read_rds(here::here("maintained", "output", "wnf_subset.rds"))

summarize_bounds <- function(replicates) {
  tibble(
    conf_low = quantile(replicates$low_est, 0.025),
    conf_high = quantile(replicates$high_est, 0.975)
  )
}

# The maintained rewrite: rsample, current sampler ----
set.seed(343)
rewrite_ci <- bootstraps(wnf_subset, times = 1000)$splits |>
  map(\(split) bounds_on_frame(analysis(split))) |>
  list_rbind() |>
  summarize_bounds()

# The archive's own resampling scheme ----
# broom::bootstrap() draws each replicate as sample(n, replace = TRUE). Reproducing that
# draw directly, rather than calling the deprecated function, is what lets the two
# samplers be compared on identical code.
archive_ci <- function(sample_kind) {
  previous <- RNGkind()
  suppressWarnings(RNGkind(sample.kind = sample_kind))
  on.exit(suppressWarnings(RNGkind(sample.kind = previous[3])), add = TRUE)

  set.seed(343)
  n <- nrow(wnf_subset)
  map(1:1000, \(i) bounds_on_frame(wnf_subset[sample(n, replace = TRUE), ])) |>
    list_rbind() |>
    summarize_bounds()
}

comparison <- bind_rows(
  rewrite_ci |> mutate(method = "Maintained rewrite: rsample::bootstraps(), R 3.6+ sampler"),
  archive_ci("Rejection") |> mutate(method = "Archive resampling scheme, R 3.6+ sampler"),
  archive_ci("Rounding") |> mutate(method = "Archive resampling scheme, pre-3.6 sampler")
) |>
  select(method, conf_low, conf_high)

write_csv(comparison, here::here("maintained", "output", "text_bootstrap_sampler.csv"))
