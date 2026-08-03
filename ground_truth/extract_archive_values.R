# coppock_2019b/ground_truth/extract_archive_values.R
# Output: ground_truth/archive_values.csv
# Depends on: original/ (fetched by download_original.R), the deposited script itself
# Description: Run the deposited analysis script on a current R installation and write
#   down what it produces, so that the ground truth's value_script column is generated
#   rather than transcribed. The deposit does not run as shipped, so the script is
#   copied into a scratch directory and repaired there by four textual substitutions,
#   each applied to the deposit's own source and each recorded below. original/ is
#   never written to and never run in.
#
#   The scratch directory comes from the ARCHIVE_RUN_DIR environment variable and
#   defaults to a session temporary directory, so this file is runnable by anyone who
#   has cloned the repository.

library(here)
library(tidyverse)

here::i_am("ground_truth/extract_archive_values.R")

archive_run_dir <- Sys.getenv("ARCHIVE_RUN_DIR", unset = file.path(tempdir(), "coppock_2019b_archive"))
dir.create(archive_run_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(dir.exists(archive_run_dir))

# The scratch copy ----
# Data and code only. Running the deposit as shipped would let it read its own HTML log
# or write beside the deposited files; neither can happen here.
deposited_script <- here::here("original", "aec_replication_JEPS.R")
deposited_data <- here::here("original", "voterIDexp_data_sept2014.RData")
stopifnot(file.exists(deposited_script), file.exists(deposited_data))

scratch_data <- file.path(archive_run_dir, "voterIDexp_data_sept2014.RData")
scratch_script <- file.path(archive_run_dir, "aec_replication_JEPS_repaired.R")
invisible(file.copy(deposited_data, scratch_data, overwrite = TRUE))

# The four repairs ----
# 1. rm(list = ls()) clears the caller's workspace and has no purpose in a sourced file.
# 2. The load() call asks for .Rdata and the deposit carries .RData, which resolves on a
#    case-insensitive filesystem and fails everywhere else. The path is also made
#    absolute so that nothing here depends on the working directory.
# 3. broom::bootstrap() still exists but returns a pre-dplyr-0.8.0 grouped data frame
#    that the do() on the next line rejects. The replacement draws each replicate as
#    sample(n, replace = TRUE), which is the draw bootstrap() itself makes.
# 4. tidy() on an lm_robust object now names its columns estimate, conf.low and
#    conf.high; the script reads coefficients, ci_lower and ci_upper.
deposited_text <- read_file(deposited_script)

original_bootstrap <- str_c(
  "boot_df <-\n",
  "  bootstrap(wnf_subset, 1000) %>%\n",
  "  do(bounds_wrapper(.)) %>%\n",
  "  ungroup()"
)

repaired_bootstrap <- str_c(
  "boot_df <- bind_rows(lapply(1:1000, function(i)  # repair 3\n",
  "  bounds_wrapper(wnf_subset[sample(nrow(wnf_subset), replace = TRUE), ])))"
)

stopifnot(
  str_detect(deposited_text, fixed("rm(list = ls())")),
  str_detect(deposited_text, fixed('load("voterIDexp_data_sept2014.Rdata")')),
  str_detect(deposited_text, fixed(original_bootstrap)),
  str_detect(deposited_text, fixed("$coefficients["))
)

repaired_text <- deposited_text |>
  str_replace(fixed("rm(list = ls())"), "# rm(list = ls())  # repair 1") |>
  str_replace(
    fixed('load("voterIDexp_data_sept2014.Rdata")'),
    str_c('load("', scratch_data, '")  # repair 2')
  ) |>
  str_replace(fixed(original_bootstrap), repaired_bootstrap) |>
  str_replace_all(fixed("$coefficients["), "$estimate[") |>
  str_replace_all(fixed("$ci_lower["), "$conf.low[") |>
  str_replace_all(fixed("$ci_upper["), "$conf.high[")

stopifnot(
  !str_detect(repaired_text, fixed('load("voterIDexp_data_sept2014.Rdata")')),
  !str_detect(repaired_text, fixed("$ci_lower[")),
  !str_detect(repaired_text, fixed("bootstrap(wnf_subset, 1000)"))
)

write_file(repaired_text, scratch_script)

# Run it ----
# Into its own environment, so nothing the deposit defines can reach the objects this
# file or build_ground_truth.R depends on. The deposit prints its assembled table.
archive <- new.env()
invisible(capture.output(suppressMessages(suppressWarnings(
  source(scratch_script, local = archive)
))))

stopifnot(all(c("fit_1", "fit_2", "fit_3", "bounds_df", "mat", "wnf_subset",
                "wnf_always_responders") %in% ls(archive)))

# What the deposit computes ----
# The script prints Table 2 rounded to three decimals; the underlying fits carry more,
# and a value read back at full precision cannot be rounded twice on its way into the
# ground truth. The percentage-point quantities the article states in prose are derived
# here from those same fits, which is the only place the deposit could supply them.
#
# The block after the fits reads counts and rates off the two frames the deposited
# cleaning code builds. Those are quantities the deposit determines and never prints,
# which is a weaker thing than a printed result and a stronger thing than nothing: no
# model is fitted here that the deposit did not fit, and no value is typed.
term_row <- function(fit) which(fit$term == "first_name_latino")

archive_subset <- archive$wnf_subset
archive_ar <- archive$wnf_always_responders
subset_rate <- function(z) 100 * mean(archive_subset$response[archive_subset$first_name_latino == z])
ar_rate <- function(z) mean(archive_ar$response_no_na[archive_ar$first_name_latino == z])

archive_values <- tribble(
  ~quantity, ~value,
  "naive estimate", archive$fit_1$estimate[term_row(archive$fit_1)],
  "naive conf low", archive$fit_1$conf.low[term_row(archive$fit_1)],
  "naive conf high", archive$fit_1$conf.high[term_row(archive$fit_1)],
  "naive std error", archive$fit_1$std.error[term_row(archive$fit_1)],
  "redefined estimate", archive$fit_2$estimate[term_row(archive$fit_2)],
  "redefined conf low", archive$fit_2$conf.low[term_row(archive$fit_2)],
  "redefined conf high", archive$fit_2$conf.high[term_row(archive$fit_2)],
  "redefined std error", archive$fit_2$std.error[term_row(archive$fit_2)],
  "always responder estimate", archive$fit_3$estimate[term_row(archive$fit_3)],
  "always responder conf low", archive$fit_3$conf.low[term_row(archive$fit_3)],
  "always responder conf high", archive$fit_3$conf.high[term_row(archive$fit_3)],
  "always responder std error", archive$fit_3$std.error[term_row(archive$fit_3)],
  "bounds low", archive$bounds_df$low_est,
  "bounds high", archive$bounds_df$high_est,
  "bounds conf low", archive$bounds_df$ci_lower,
  "bounds conf high", archive$bounds_df$ci_upper,
  "naive degrees of freedom", archive$fit_1$df[term_row(archive$fit_1)],
  "matched pairs both responding", as.numeric(n_distinct(archive_subset$pair_id[archive_subset$AR])),
  "response rate, non-Latino White arm", subset_rate(0),
  "response rate, Latino arm", subset_rate(1),
  "difference in response rates", subset_rate(1) - subset_rate(0),
  "always responder response rate, non-Latino White arm", ar_rate(0),
  "always responder response rate, Latino arm", ar_rate(1),
  "always responder response rate, pooled", 100 * mean(archive_ar$response_no_na),
  "redefined outcome maximum among non-responders",
  max(archive_subset$friendly_no_na[archive_subset$response_no_na == 0]),
  "estimator rows in the assembled table", as.numeric(nrow(archive$mat))
)

stopifnot(nrow(archive_values) == 26, !any(is.na(archive_values$value)))

write_csv(archive_values, here::here("ground_truth", "archive_values.csv"))

print(archive_values, n = nrow(archive_values))
