# coppock_2019b/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_2019b_ground_truth.csv
# Depends on: maintained/output/ (run run_all.R first), ground_truth/archive_values.csv,
#   ground_truth/published_claims.csv
# Description: Assemble the ground truth table and run the coverage gates over it.
#
#   Provenance, which is the whole point of generating this file rather than typing it:
#   - value_paper comes from ground_truth/published_claims.csv, the hand-reviewed
#     extraction of every numeric token in the article. That is the only transcription
#     of the published page anywhere in this repository, so there is no second copy for
#     it to drift against, and no published number is an input to any computation here
#     or in maintained/.
#   - value_script comes from ground_truth/archive_values.csv, written by
#     extract_archive_values.R, which runs the repaired deposit in a scratch directory.
#   - value_rewrite is read back out of maintained/output/, so the table cannot drift
#     from the pipeline.
#
#   The gates at the foot of the file check that every pipeline and descriptive claim in
#   the extraction has a row here and a live block in maintained/in_text_claims.R, and
#   that the two instruments agree number by number.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

t2 <- out("table_2_reanalysis.csv")
in_text <- out("text_in_text_estimates.csv")
response_rates <- out("text_response_rates.csv")
archive <- read_csv(here::here("ground_truth", "archive_values.csv"), show_col_types = FALSE)

wnf_subset <- read_rds(here::here("maintained", "output", "wnf_subset.rds"))
wnf_always_responders <- read_rds(here::here("maintained", "output", "wnf_always_responders.rds"))

# one_value: a single value out of a two-column output file, selected by a pattern that
# has to identify exactly one row. The assertion is what stops a widened output file
# from turning a scalar into a vector and a ground-truth row into a list column.
one_value <- function(d, key, pattern) {
  hits <- d$value[str_detect(d[[key]], pattern)]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

t2_row <- function(estimator_label) {
  hit <- t2[t2$estimator == estimator_label, ]
  stopifnot(nrow(hit) == 1)
  hit
}

naive <- t2_row("Naive difference-in-means")
redefined <- t2_row("Difference-in-means")
always_responder <- t2_row("Difference-in-means among matched pairs in which both members respond")
bounds <- t2_row("Bounds")

# The confidence level the Table 2 header states, recovered from the estimates rather
# than asserted. in_text_claims.R recovers the same level from the naive row; this uses
# the redefined-outcome row, so the two reach it by different arithmetic.
redefined_multiplier <- ((redefined$conf_high - redefined$conf_low) / 2) / redefined$std_error
archive_multiplier <- ((one_value(archive, "quantity", "^naive conf high$") -
                          one_value(archive, "quantity", "^naive conf low$")) / 2) /
  one_value(archive, "quantity", "^naive std error$")

ar_rate <- function(z) {
  mean(wnf_always_responders$response_no_na[wnf_always_responders$first_name_latino == z])
}

# The rows ----
# claim_id ties every row to ground_truth/published_claims.csv. The order below is the
# order the article states the quantities in.
gt <- tribble(
  ~claim_id, ~value_script, ~value_rewrite, ~defect_locus, ~notes,

  "intro_rr_nonlatino",
  one_value(archive, "quantity", "^response rate, non-Latino"),
  one_value(response_rates, "claim", "^Response rate, Putatively non-Latino"),
  NA_character_,
  "The deposited script never computes this; value_script is the rate on the analysis frame the deposit itself builds",

  "intro_rr_latino",
  one_value(archive, "quantity", "^response rate, Latino"),
  one_value(response_rates, "claim", "^Response rate, Putatively Latino"),
  NA_character_,
  "The deposited script never computes this; value_script is the rate on the analysis frame the deposit itself builds",

  "intro_rr_difference",
  one_value(archive, "quantity", "^difference in response rates$"),
  one_value(response_rates, "claim", "^Difference in response rates"),
  NA_character_,
  "The deposited script never computes this; value_script is the difference on the analysis frame the deposit itself builds",

  "intro_rr_difference_significant",
  NA_real_,
  as.numeric(response_rates$p_value[!is.na(response_rates$p_value)] < 0.05),
  NA_character_,
  "The deposit fits no model of response, so it has no verdict here. The rewrite's two-sided p-value on the difference in response rates is the test the sentence claims",

  "t1_ar_r0",
  one_value(archive, "quantity", "^always responder response rate, non-Latino"),
  ar_rate(0),
  NA_character_,
  "Read back off the Always-Responder frame rather than asserted",

  "t1_ar_r1",
  one_value(archive, "quantity", "^always responder response rate, Latino"),
  ar_rate(1),
  NA_character_,
  "Read back off the Always-Responder frame rather than asserted",

  "p2_ar_response_rate",
  one_value(archive, "quantity", "^always responder response rate, pooled$"),
  100 * mean(wnf_always_responders$response_no_na),
  NA_character_,
  "The article's own stated check on the Always-Responders assumption",

  "t2_naive_estimate",
  one_value(archive, "quantity", "^naive estimate$"), naive$estimate, NA_character_, "",
  "t2_naive_ci_lower",
  one_value(archive, "quantity", "^naive conf low$"), naive$conf_low, NA_character_, "",
  "t2_naive_ci_upper",
  one_value(archive, "quantity", "^naive conf high$"), naive$conf_high, NA_character_, "",

  "t2_redefined_estimate",
  one_value(archive, "quantity", "^redefined estimate$"), redefined$estimate, NA_character_, "",
  "t2_redefined_ci_lower",
  one_value(archive, "quantity", "^redefined conf low$"), redefined$conf_low, NA_character_, "",
  "t2_redefined_ci_upper",
  one_value(archive, "quantity", "^redefined conf high$"), redefined$conf_high, NA_character_, "",

  "t2_ar_estimate",
  one_value(archive, "quantity", "^always responder estimate$"),
  always_responder$estimate, NA_character_, "",
  "t2_ar_ci_lower",
  one_value(archive, "quantity", "^always responder conf low$"),
  always_responder$conf_low, NA_character_, "",
  "t2_ar_ci_upper",
  one_value(archive, "quantity", "^always responder conf high$"),
  always_responder$conf_high, NA_character_, "",

  "t2_bounds_low",
  one_value(archive, "quantity", "^bounds low$"), bounds$bounds_low, NA_character_, "",
  "t2_bounds_high",
  one_value(archive, "quantity", "^bounds high$"), bounds$bounds_high, NA_character_, "",

  "t2_bounds_ci_lower",
  one_value(archive, "quantity", "^bounds conf low$"), bounds$conf_low, "environment",
  "R 3.6.0 changed sample(); under RNGkind(sample.kind = 'Rounding') the same seed gives -0.730, which is the published value. text_bootstrap_sampler.csv carries all three intervals",
  "t2_bounds_ci_upper",
  one_value(archive, "quantity", "^bounds conf high$"), bounds$conf_high, "environment",
  "R 3.6.0 changed sample(); under RNGkind(sample.kind = 'Rounding') the same seed gives 0.726, which is the published value. text_bootstrap_sampler.csv carries all three intervals",

  "t2_ci_level",
  100 * (2 * pt(archive_multiplier,
                one_value(archive, "quantity", "^naive degrees of freedom$")) - 1),
  100 * (2 * pt(redefined_multiplier, redefined$n - 2) - 1),
  NA_character_,
  "The column header is a claim about the intervals beside it; the level is recovered from the ratio of each half width to its standard error",

  "p3_redefine_zero",
  one_value(archive, "quantity", "^redefined outcome maximum"),
  max(wnf_subset$friendly_no_na[wnf_subset$response_no_na == 0]),
  NA_character_,
  "The redefined outcome's floor, read off the analysis frame",

  "p3_lower_bound_points",
  100 * one_value(archive, "quantity", "^bounds low$"),
  one_value(in_text, "claim", "^Lower bound"), NA_character_,
  "The article rounds to whole points; -65.78 at full precision",
  "p3_upper_bound_points",
  100 * one_value(archive, "quantity", "^bounds high$"),
  one_value(in_text, "claim", "^Upper bound"), NA_character_,
  "The article rounds to whole points; 64.54 at full precision",

  "p3_matched_pairs",
  one_value(archive, "quantity", "^matched pairs both responding$"),
  one_value(in_text, "claim", "^Matched pairs"), NA_character_,
  "Distinct pair identifiers among the Always-Responder pairs. One pair contributes an odd number of surviving rows, so halving the row count would give 719.5",

  "p3_ar_ate_points",
  100 * one_value(archive, "quantity", "^always responder estimate$"),
  one_value(in_text, "claim", "^Always-Responder ATE"), "paper_internal",
  "The text states -5.5 points and Table 2 states -0.056 for the same estimate. It is -5.563 points, so the table rounds and the text truncates. An inconsistency inside the article, not a reproduction failure",

  "p3_ar_se_points",
  100 * one_value(archive, "quantity", "^always responder std error$"),
  one_value(in_text, "claim", "^Always-Responder SE"), NA_character_,
  "2.482 at full precision",

  "p3_redefined_ate_points",
  100 * one_value(archive, "quantity", "^redefined estimate$"),
  one_value(in_text, "claim", "^Redefined-outcome ATE"), NA_character_,
  "The article states a 6 point decrease; -6.100 at full precision",

  "p3_redefined_se_points",
  100 * one_value(archive, "quantity", "^redefined std error$"),
  one_value(in_text, "claim", "^Redefined-outcome SE"), "paper_internal",
  "The text states SE = 1.7 points. It is 1.756 points, which rounds to 1.8; the text truncates. Table 2 prints no standard errors, so this figure appears only in prose",

  "p3_significance_contrast",
  NA_real_,
  as.numeric(redefined$p_value < 0.05 & naive$p_value >= 0.05),
  NA_character_,
  "Evaluated here from the two p-values; in_text_claims.R evaluates the same contrast from the two confidence intervals. The deposit prints no p-values",

  "p3_naive_ate_points",
  100 * one_value(archive, "quantity", "^naive estimate$"),
  one_value(in_text, "claim", "^Naive ATE"), NA_character_,
  "-3.542 at full precision",

  "p3_naive_se_points",
  100 * one_value(archive, "quantity", "^naive std error$"),
  one_value(in_text, "claim", "^Naive SE"), NA_character_,
  "2.041 at full precision",

  "p3_four_estimates",
  one_value(archive, "quantity", "^estimator rows"), as.numeric(nrow(t2)), NA_character_,
  "Estimator rows in the reproduced Table 2"
)

# The extraction ----
# value_paper is forced to character in every reader, here included: a column whose
# entries all look numeric is guessed as double, and that silently turns the article's
# 2.0 into 2 and -0.00 into 0, destroying the printed precision the comparison depends on.
claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(.default = col_character(),
                                    value_paper = col_character())) |>
  mutate(needs_block = needs_block == "TRUE")

stopifnot(!any(duplicated(claims$claim_id)), !any(is.na(claims$value_paper)))

# Agreement at the precision the article prints ----
# value_paper is carried as the string the article prints, because the number alone does
# not record its own precision: 2.0 and 2 are the same double, and reading the precision
# off the double would compare a one-decimal published value at a tolerance of 0.5.
printed_decimals <- function(txt) {
  if_else(str_detect(txt, "\\."), nchar(str_remove(txt, "^[^.]*\\.")), 0L)
}

agrees <- function(value, target_printed) {
  target <- parse_double(target_printed)
  case_when(
    is.na(value) | is.na(target) ~ NA_real_,
    abs(value - target) <= 0.5 * 10^(-printed_decimals(target_printed)) ~ 1,
    .default = 0
  )
}

gt <- gt |>
  left_join(claims |> select(claim_id, location, claim, claim_type, value_paper),
            by = "claim_id") |>
  mutate(
    paper_id = "coppock_2019b",
    table_figure = location,
    # A descriptive claim has no printed number to agree with, so its verdict is a third
    # state: match and match_rewrite stay NA and holds carries it.
    descriptive = claim_type == "descriptive",
    match = if_else(descriptive, NA_real_, agrees(value_script, value_paper)),
    match_rewrite = if_else(descriptive, NA_real_, agrees(value_rewrite, value_paper)),
    holds = if_else(descriptive, agrees(value_rewrite, value_paper), NA_real_),
    defect_locus = if_else(defect_locus == "", NA_character_, defect_locus),
    notes = replace_na(notes, "")
  )

stopifnot(!any(is.na(gt$claim)), !any(duplicated(gt$claim_id)))

# A locus is required on every adverse verdict, and on no clean row ----
# The gate reads all three verdicts. Stated on match_rewrite alone it could not see a
# failing descriptive claim, whose verdict lives in holds, nor an archive failure that
# the rewrite passes, which is the signature of environment drift and is exactly what
# the two bootstrap endpoints below are.
adverse <- (!is.na(gt$match) & gt$match == 0) |
  (!is.na(gt$match_rewrite) & gt$match_rewrite == 0) |
  (!is.na(gt$holds) & gt$holds == 0)

stopifnot(all(!is.na(gt$defect_locus[adverse])), all(is.na(gt$defect_locus[!adverse])))

# Coverage against the extraction ----
required_rows <- claims$claim_id[claims$claim_type %in% c("pipeline", "descriptive")]
stopifnot(
  length(setdiff(required_rows, gt$claim_id)) == 0,
  length(setdiff(gt$claim_id, claims$claim_id)) == 0
)

# Float coverage, as a fraction rather than as an existence check ----
# "At least one row" is not coverage of a float. Table 1 is a stipulated typology whose
# other three strata no analysis identifies, so its covered fraction is low by design and
# is stated rather than waved through.
float_coverage <- claims |>
  filter(str_starts(location, "Table")) |>
  mutate(float = str_extract(location, "^Table \\d+")) |>
  summarize(published_cells = n(), covered_cells = sum(claim_id %in% gt$claim_id),
            .by = float)

stopifnot(all(float_coverage$covered_cells >= 1))

# The second instrument ----
# Read as a program, not as text: a block that errors at runtime, or that ends in a bare
# expression and therefore prints nothing under source(), would satisfy any check that
# merely looked for its claim id in the file. local = new.env() keeps the claims file's
# own out(), claims and naive objects from replacing the ones this gate runs against.
claims_log <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env())
)

printed <- str_match(claims_log, "^CLAIM (\\S+) = (\\S+) \\|\\| (.*)$")
printed <- tibble(claim_id = printed[, 2], printed_value = printed[, 3],
                  label = printed[, 4]) |>
  filter(!is.na(claim_id))

declared <- claims$claim_id[claims$needs_block]

stopifnot(
  !any(duplicated(printed$claim_id)),
  nrow(printed) == length(declared),
  length(setdiff(declared, printed$claim_id)) == 0,
  length(setdiff(printed$claim_id, declared)) == 0
)

# Two instruments, compared value by value ----
# build_ground_truth.R and in_text_claims.R reach each number by separate paths from the
# same outputs, so a disagreement between them is a finding in its own right.
cross_check <- printed |>
  inner_join(gt |> select(claim_id, value_paper, value_rewrite), by = "claim_id") |>
  mutate(
    digits = printed_decimals(value_paper),
    gt_printed = if_else(is.na(value_rewrite), "NA",
                         sprintf(paste0("%.", digits, "f"), value_rewrite)),
    agrees = printed_value == gt_printed
  )

if (any(!cross_check$agrees)) print(cross_check |> filter(!agrees), n = Inf, width = 200)
stopifnot(length(setdiff(declared, cross_check$claim_id)) == 0, all(cross_check$agrees))

gt <- gt |>
  select(paper_id, claim_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, holds, defect_locus, notes)

write_csv(gt, here::here("ground_truth", "coppock_2019b_ground_truth.csv"))

# The committed file must store the string the article prints, not a re-parsed double.
# write_csv is not asked to be trusted on that; the file is read back and checked.
written <- read_csv(here::here("ground_truth", "coppock_2019b_ground_truth.csv"),
                    col_types = cols(.default = col_character(),
                                     value_paper = col_character()))
stopifnot(identical(written$value_paper, gt$value_paper))

# The errata spine's claim_ids ----
# errata_entries.csv names, for every published entry, the ground-truth claims it corrects.
# Every one of those ids has to exist here: a missing one is a typo or a claim that has since
# been renamed, and a dangling reference inside a document whose whole purpose is correcting
# the record is worse than a failed build.
errata_spine <- here::here("errata_entries.csv")
if (file.exists(errata_spine)) {
  cited_ids <- read_csv(errata_spine, show_col_types = FALSE)$claim_ids |>
    str_split(";") |>
    unlist() |>
    str_trim() |>
    discard(\(x) is.na(x) | x == "")
  dangling <- setdiff(cited_ids, gt$claim_id)
  if (length(dangling) > 0) print(dangling)
  stopifnot(length(dangling) == 0)
}

print(gt |> select(claim_id, table_figure, value_script, value_paper, match,
                   value_rewrite, match_rewrite, holds, defect_locus),
      n = nrow(gt), width = 200)
print(float_coverage)
print(tibble(
  quantity = c("rows", "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing",
               "descriptive claims", "descriptive claims holding",
               "extraction rows", "extraction rows needing a block",
               "claims printed by in_text_claims.R",
               "claims compared across the two instruments"),
  value = c(nrow(gt), sum(!is.na(gt$match)), sum(gt$match == 1, na.rm = TRUE),
            sum(!is.na(gt$match_rewrite)), sum(gt$match_rewrite == 1, na.rm = TRUE),
            sum(gt$match_rewrite == 0, na.rm = TRUE),
            sum(!is.na(gt$holds)), sum(gt$holds == 1, na.rm = TRUE),
            nrow(claims), length(declared), nrow(printed), nrow(cross_check))
))
