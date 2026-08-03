# coppock_2019b/maintained/in_text_claims.R
# Output: printed CLAIM lines only; no files
# Depends on: maintained/output/, helpers.R
# Description: One block per numeric claim the published article makes, each carrying
#   the article's own sentence verbatim and then recomputing the number from the
#   pipeline's committed output. This is the second instrument: it never reads
#   ground_truth/coppock_2019b_ground_truth.csv, it never refits a model, and it
#   reaches every quantity by its own path, so where it and build_ground_truth.R
#   disagree one of them is wrong.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || <label>
#
#   which is what build_ground_truth.R parses to check coverage against
#   ground_truth/published_claims.csv. The value is printed at the precision the
#   article prints, so it can be read against the page without re-rounding.
#
#   Where build_ground_truth.R reads a quantity out of one of the text_ output files,
#   this file derives it instead from the Table 2 estimates or from the analysis frames,
#   and the other way round for the two significance claims. That is what makes the two
#   instruments independent rather than two printings of one number.
#
#   Transcription convention: the published PDF sets minus signs as U+2212 and uses
#   ligatures for "ff" and "fi". The quotes below are plain ASCII, and the potential
#   outcome notation Y_i(Z) and R_i(Z) is written with underscores. Quotes are the
#   sentences the article prints today, however wrong; where a sentence is wrong that
#   is recorded in the ground truth and in the errata, never by editing the quote.
source(here::here("maintained", "helpers.R"))

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

results <- out("table_2_reanalysis.csv")
response_rates <- out("text_response_rates.csv")

wnf_subset <- read_rds(here::here("maintained", "output", "wnf_subset.rds"))
wnf_always_responders <- read_rds(here::here("maintained", "output", "wnf_always_responders.rds"))

# claim: print one claim line in the form the coverage gate parses. digits is the number
# of decimal places the article prints, so a value printed here can be laid against the
# page without being rounded a second time.
claim <- function(id, value, label, digits = 0) {
  printed <- if (length(value) != 1 || is.na(value)) {
    "NA"
  } else {
    sprintf(paste0("%.", digits, "f"), value)
  }
  cat("CLAIM ", id, " = ", printed, " || ", label, "\n", sep = "")
}

# row: one row of the Table 2 estimates, by the estimator label the table prints. The
# assertion is what stops a renamed estimator from silently emptying a claim.
row_of <- function(estimator_label) {
  hit <- results[results$estimator == estimator_label, ]
  stopifnot(nrow(hit) == 1)
  hit
}

naive <- row_of("Naive difference-in-means")
redefined <- row_of("Difference-in-means")
always_responder <- row_of("Difference-in-means among matched pairs in which both members respond")
bounds <- row_of("Bounds")

# Introduction ----

# "Whereas Non-Latino White names received a response 70.5% of the time, Latino names
#  were responded to 64.8% of the time, for a statistically and substantively
#  significant difference of negative 5.7 percentage points."
#
# The three figures are attributed to White et al. (2015) and the deposited script never
# computes them. They are recovered here from the deposited data on the analysis frame
# the rest of the paper uses: week one, first contact, the two excluded states dropped,
# bounced e-mails removed. build_ground_truth.R reads them out of
# text_response_rates.csv; this block goes back to the frame.
rr_by_arm <- wnf_subset |>
  summarize(rate = 100 * mean(response), .by = first_name_latino)

claim("intro_rr_nonlatino", rr_by_arm$rate[rr_by_arm$first_name_latino == 0],
      "response rate to putatively non-Latino White names, per cent", 1)
claim("intro_rr_latino", rr_by_arm$rate[rr_by_arm$first_name_latino == 1],
      "response rate to putatively Latino names, per cent", 1)
claim("intro_rr_difference",
      rr_by_arm$rate[rr_by_arm$first_name_latino == 1] -
        rr_by_arm$rate[rr_by_arm$first_name_latino == 0],
      "difference in response rates, percentage points", 1)

# The significance half of the same sentence. build_ground_truth.R evaluates it from the
# p-value; this block uses the confidence interval, which is the other statement of the
# same test. Substantive significance is not a computable quantity and is not tested
# here or there.
rr_difference <- response_rates[
  response_rates$claim == "Difference in response rates, percentage points", ]
stopifnot(nrow(rr_difference) == 1)

claim("intro_rr_difference_significant",
      as.numeric(rr_difference$conf_low > 0 | rr_difference$conf_high < 0),
      str_glue("1 if the 95 per cent interval on the response rate difference excludes ",
               "zero; it runs {sprintf('%.1f', rr_difference$conf_low)} to ",
               "{sprintf('%.1f', rr_difference$conf_high)} points"), 0)

# Types of subjects ----

# Table 1, first row: "Always-Responder | R_i(0) = 1 | R_i(1) = 1 | Y_i(0) | Y_i(1)"
#
# The other three rows of Table 1 are strata whose members no analysis identifies, so
# they are verified nowhere and are recorded as such in published_claims.csv. The
# Always-Responder row is the one the paper acts on, and the rewrite's Always-Responder
# frame is where it can be read back rather than asserted.
ar_by_arm <- wnf_always_responders |>
  summarize(rate = mean(response_no_na), n = n(), .by = first_name_latino)

claim("t1_ar_r0", ar_by_arm$rate[ar_by_arm$first_name_latino == 0],
      str_glue("response indicator under the non-Latino White name across the ",
               "{ar_by_arm$n[ar_by_arm$first_name_latino == 0]} assumed Always-Responders"), 0)
claim("t1_ar_r1", ar_by_arm$rate[ar_by_arm$first_name_latino == 1],
      str_glue("response indicator under the Latino name across the ",
               "{ar_by_arm$n[ar_by_arm$first_name_latino == 1]} assumed Always-Responders"), 0)

# Find Always-Responders ----

# "One check on the plausibility of the "Always-Responders" assumption is that the
#  response rate in both the treatment and control groups must equal 100%."
claim("p2_ar_response_rate", 100 * mean(wnf_always_responders$response_no_na),
      str_glue("response rate across both arms of the Always-Responder frame, per cent, ",
               "on {nrow(wnf_always_responders)} units"), 0)

# Table 2 ----

# Table 2, "Reanalysis of White, Nathan, and Faller (2015)", column headed "Estimate"
# and column headed "95% CI".
claim("t2_naive_estimate", naive$estimate, "naive difference-in-means estimate", 3)
claim("t2_naive_ci_lower", naive$conf_low, "naive difference-in-means, lower confidence limit", 3)
claim("t2_naive_ci_upper", naive$conf_high, "naive difference-in-means, upper confidence limit", 3)

claim("t2_redefined_estimate", redefined$estimate, "redefined-outcome estimate", 3)
claim("t2_redefined_ci_lower", redefined$conf_low, "redefined outcome, lower confidence limit", 3)
claim("t2_redefined_ci_upper", redefined$conf_high, "redefined outcome, upper confidence limit", 3)

claim("t2_ar_estimate", always_responder$estimate,
      "matched-pair Always-Responder estimate", 3)
claim("t2_ar_ci_lower", always_responder$conf_low,
      "matched-pair Always-Responders, lower confidence limit", 3)
claim("t2_ar_ci_upper", always_responder$conf_high,
      "matched-pair Always-Responders, upper confidence limit", 3)

claim("t2_bounds_low", bounds$bounds_low, "Zhang and Rubin lower bound", 3)
claim("t2_bounds_high", bounds$bounds_high, "Zhang and Rubin upper bound", 3)

# The article prints the lower bootstrap limit at two decimals and the upper at three,
# so the two are printed here the same way. Neither comes back on current R: R 3.6.0
# changed how sample() turns uniform draws into integers, and the published interval is
# what the same seed drew before that change.
claim("t2_bounds_ci_lower", bounds$conf_low,
      "bounds bootstrap interval, lower limit, at the two decimals the article prints", 2)
claim("t2_bounds_ci_upper", bounds$conf_high,
      "bounds bootstrap interval, upper limit", 3)

# The "95% CI" column header is a claim about the intervals beside it. The level is
# recoverable from the estimates themselves: the ratio of a half width to its standard
# error is the multiplier, and the multiplier names the level.
ci_multiplier <- ((naive$conf_high - naive$conf_low) / 2) / naive$std_error
claim("t2_ci_level", 100 * (2 * pt(ci_multiplier, naive$n - 2) - 1),
      str_glue("confidence level implied by a multiplier of ",
               "{sprintf('%.4f', ci_multiplier)} on {naive$n - 2} degrees of freedom, ",
               "per cent"), 0)

# Redefine the outcome ----

# "Analysts can change the outcome variable to be Y_i*(Z), which is equal to Y_i(Z) if
#  R_i(Z) = 1 and 0 otherwise. Crucially, this means that e-mails never sent are "not
#  friendly.""
claim("p3_redefine_zero", max(wnf_subset$friendly_no_na[wnf_subset$response_no_na == 0]),
      str_glue("largest value the redefined outcome takes across the ",
               "{sum(wnf_subset$response_no_na == 0)} non-responders"), 0)

# Reanalysis ----

# "Following the procedure in Zhang and Rubin (2003), I estimate the lower bound to be
#  -66 points and the upper bound to be 65 points."
claim("p3_lower_bound_points", 100 * bounds$bounds_low,
      "Zhang and Rubin lower bound, percentage points", 0)
claim("p3_upper_bound_points", 100 * bounds$bounds_high,
      "Zhang and Rubin upper bound, percentage points", 0)

# "I subset the dataset to the 719 matched pairs in which both the treated and untreated
#  pair member responded."
#
# The paper counts pairs, not rows. One pair contributes an odd number of surviving rows
# because a pair member's e-mail bounced, so halving the count of Always-Responder rows
# would give 719.5; the count of distinct pair identifiers is the quantity the sentence
# names.
claim("p3_matched_pairs", n_distinct(wnf_subset$pair_id[wnf_subset$AR]),
      "matched pairs in which both members responded", 0)

# "Under the unverifiable assumption that both pair members would also have responded if
#  the treatment assignment had been switched, I estimate the ATE among this subgroup to
#  be -5.5 points (SE = 2.5 points)."
claim("p3_ar_ate_points", 100 * always_responder$estimate,
      str_glue("matched-pair Always-Responder ATE, percentage points; Table 2 prints ",
               "{sprintf('%.3f', always_responder$estimate)} for the same estimate"), 1)
claim("p3_ar_se_points", 100 * always_responder$std_error,
      "matched-pair Always-Responder standard error, percentage points", 1)

# "Finally, using the redefined outcome, I estimate the ATE to be a 6 point decrease in
#  friendliness (SE = 1.7 points)."
#
# The sentence states the sign in words, so the printed value is signed and the article's
# "6 point decrease" is its whole-point counterpart.
claim("p3_redefined_ate_points", 100 * redefined$estimate,
      "redefined-outcome ATE, percentage points", 0)
claim("p3_redefined_se_points", 100 * redefined$std_error,
      "redefined-outcome standard error, percentage points", 1)

# "As it happens, this estimate is statistically significant while the naive estimate
#  (-3.5 percentage, SE = 2.0 points) is not."
#
# Two quantities that can be mistaken for each other, so the contrast prints both
# intervals on one line. build_ground_truth.R evaluates the same contrast from the two
# p-values.
claim("p3_significance_contrast",
      as.numeric((redefined$conf_low > 0 | redefined$conf_high < 0) &
                   (naive$conf_low < 0 & naive$conf_high > 0)),
      str_glue("1 if the redefined-outcome interval [",
               "{sprintf('%.3f', redefined$conf_low)}, ",
               "{sprintf('%.3f', redefined$conf_high)}] excludes zero while the naive ",
               "interval [{sprintf('%.3f', naive$conf_low)}, ",
               "{sprintf('%.3f', naive$conf_high)}] contains it"), 0)

claim("p3_naive_ate_points", 100 * naive$estimate,
      "naive ATE, percentage points", 1)
claim("p3_naive_se_points", 100 * naive$std_error,
      "naive standard error, percentage points", 1)

# "Table 2 displays all four estimates."
claim("p3_four_estimates", nrow(results),
      "estimator rows the rewrite's Table 2 carries", 0)
