# coppock_2019b/maintained/table_2_reanalysis.R
# Output: output/table_2_reanalysis.csv
# Depends on: clean_voterID.R output, helpers.R
# Description: Table 2, the four estimators of the effect of a putatively Latino sender
#   name on the friendliness of an election official's reply: the naive difference in
#   means, the difference in means on the redefined outcome, the difference in means
#   among matched-pair Always-Responders, and the Zhang and Rubin trimming bounds with
#   a bootstrap confidence interval. Values are written at full precision; the report
#   rounds them to the three decimal places the article prints.
source(here::here("maintained", "helpers.R"))

set.seed(343)

wnf_subset <- read_rds(here::here("maintained", "output", "wnf_subset.rds"))
wnf_always_responders <- read_rds(here::here("maintained", "output", "wnf_always_responders.rds"))

# Three difference-in-means estimators ----
# The naive estimator conditions on response, which is post-treatment, so the estimand
# it targets does not exist. It is reported to show what the conditioning costs.
fits <- list(
  naive = lm_robust(friendly ~ first_name_latino, data = wnf_subset),
  redefined = lm_robust(friendly_no_na ~ first_name_latino, data = wnf_subset),
  always_responder = lm_robust(friendly ~ first_name_latino, data = wnf_always_responders)
)

difference_in_means <- fits |>
  map(\(fit) tidy(fit) |> filter(term == "first_name_latino")) |>
  list_rbind(names_to = "estimator_id") |>
  transmute(estimator_id, estimate, std_error = std.error, conf_low = conf.low,
            conf_high = conf.high, p_value = p.value,
            n = map_int(fits, \(fit) as.integer(fit$nobs)))

# Bounds and their bootstrap confidence interval ----
bounds_point <- bounds_on_frame(wnf_subset)

boot_bounds <- bootstraps(wnf_subset, times = 1000)$splits |>
  map(\(split) bounds_on_frame(analysis(split))) |>
  list_rbind()

bounds_ci <- boot_bounds |>
  summarize(
    conf_low = quantile(low_est, 0.025),
    conf_high = quantile(high_est, 0.975)
  )

# Assemble ----
labels <- tribble(
  ~estimator_id, ~estimand, ~estimator,
  "naive",
  "Undefined",
  "Naive difference-in-means",
  "redefined",
  "ATE on redefined outcome",
  "Difference-in-means",
  "always_responder",
  "ATE among matched pairs in which both members are Always-Responders",
  "Difference-in-means among matched pairs in which both members respond",
  "bounds",
  "ATE among all Always-Responders",
  "Bounds"
)

results <- difference_in_means |>
  mutate(bounds_low = NA_real_, bounds_high = NA_real_) |>
  bind_rows(tibble(
    estimator_id = "bounds",
    estimate = NA_real_,
    std_error = NA_real_,
    conf_low = bounds_ci$conf_low,
    conf_high = bounds_ci$conf_high,
    p_value = NA_real_,
    n = nrow(wnf_subset),
    bounds_low = bounds_point$low_est,
    bounds_high = bounds_point$high_est
  )) |>
  right_join(labels, by = "estimator_id") |>
  select(estimand, estimator, estimate, std_error, bounds_low, bounds_high,
         conf_low, conf_high, p_value, n)

write_csv(results, here::here("maintained", "output", "table_2_reanalysis.csv"))
