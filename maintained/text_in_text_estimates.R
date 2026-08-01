# coppock_2019b/maintained/text_in_text_estimates.R
# Output: output/text_in_text_estimates.csv
# Depends on: table_2_reanalysis.R output, clean_voterID.R output, helpers.R
# Description: The quantities the article states in prose rather than in Table 2: the
#   bounds in percentage points, the number of matched pairs in which both members
#   responded, and each estimator's point estimate and standard error in percentage
#   points. All are read from the Table 2 estimates at full precision, so nothing here
#   is rounded twice.
source(here::here("maintained", "helpers.R"))

wnf_subset <- read_rds(here::here("maintained", "output", "wnf_subset.rds"))
results <- read_csv(here::here("maintained", "output", "table_2_reanalysis.csv"),
                    show_col_types = FALSE)

in_points <- function(estimator_label, column) {
  100 * results[[column]][results$estimator == estimator_label]
}

naive <- "Naive difference-in-means"
redefined <- "Difference-in-means"
always_responder <- "Difference-in-means among matched pairs in which both members respond"

# The paper counts pairs, not rows. One pair contributes an odd number of surviving rows
# because a pair member's email bounced, so halving the count of AR rows would give
# 719.5; the count of distinct pair identifiers is the quantity the article states.
n_ar_pairs <- n_distinct(wnf_subset$pair_id[wnf_subset$AR])

claims <- tribble(
  ~claim, ~value,
  "Lower bound, percentage points", in_points("Bounds", "bounds_low"),
  "Upper bound, percentage points", in_points("Bounds", "bounds_high"),
  "Matched pairs in which both members responded", as.numeric(n_ar_pairs),
  "Always-Responder ATE, percentage points", in_points(always_responder, "estimate"),
  "Always-Responder SE, percentage points", in_points(always_responder, "std_error"),
  "Redefined-outcome ATE, percentage points", in_points(redefined, "estimate"),
  "Redefined-outcome SE, percentage points", in_points(redefined, "std_error"),
  "Naive ATE, percentage points", in_points(naive, "estimate"),
  "Naive SE, percentage points", in_points(naive, "std_error")
)

write_csv(claims, here::here("maintained", "output", "text_in_text_estimates.csv"))
