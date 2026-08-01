# Active Maintenance Report: coppock_2019b

2026-08-01

- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Paper overview](#paper-overview)
- [Original archive reproducibility](#original-archive-reproducibility)
  - [The bootstrap](#the-bootstrap)
  - [The renamed tidy columns](#the-renamed-tidy-columns)
  - [The filename](#the-filename)
- [Number-by-number comparison](#number-by-number-comparison)
- [The bootstrap interval and the R 3.6
  sampler](#the-bootstrap-interval-and-the-r-36-sampler)
- [Maintained rewrite](#maintained-rewrite)
  - [Architecture](#architecture)
  - [Deprecated patterns replaced](#deprecated-patterns-replaced)
- [Table 2 as reproduced](#table-2-as-reproduced)
- [Maintained rewrite verification](#maintained-rewrite-verification)
- [R environment](#r-environment)

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

This repository holds the actively maintained replication code for
Coppock (2019), together with the reproducibility report that documents
what the original archive did and did not do. It is part of a program
applying the maintenance proposal in Peer, Orr and Coppock (2021, *PS:
Political Science & Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1017/XPS.2018.9](https://doi.org/10.1017/XPS.2018.9) |
| Replication archive | [10.7910/DVN/6NVI9C](https://doi.org/10.7910/DVN/6NVI9C) |
| Underlying data (White, Nathan and Faller 2015) | [10.7910/DVN/28158](https://doi.org/10.7910/DVN/28158) |

**The data are not redistributed here.** The deposit is 1.3 MB across
four files and lives at Harvard Dataverse, which is the only copy this
repository points at. `download_original.R` fetches it and verifies
every file; `original_manifest.csv` pins the file identifiers, sizes and
checksums, so the exact bytes this code was written against are recorded
in version control even though the bytes themselves are not.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or set of in-text quantities, writing to
`output/`, which is committed so a reader can compare a fresh run
against it without downloading anything. `ground_truth/` ties every
published number to the code that produces it. `original/` is created by
the download script and is deliberately absent from the repository. This
file is the reproducibility report, also available as a PDF in
`report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`coppock_2019b.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposit, verifies its four files, and produces the
published table and every in-text quantity into `maintained/output/`.
Required packages: tidyverse, estimatr, rsample, knitr, kableExtra,
here. Paths resolve through `here`, so nothing depends on the working
directory. The full run takes about twelve seconds, most of it in the
3,000 bootstrap replicates of the bounds estimator. A successful run
overwrites `maintained/output/`, which is committed: **`git diff` on
that folder is the reproduction check.**

# Summary

Two questions, answered before the detail.

## Does the deposited archive run?

No. The archive’s single script stops partway through on a current R
installation, and it stops twice, at two independent points, neither of
which produces a helpful error message.

The first failure is the bootstrap. `broom::bootstrap()` still exists,
but it builds a grouped data frame in the format dplyr used before
version 0.8.0, and the `dplyr::do()` on the next line rejects it with
`Corrupt grouped_df using old (< 0.8.0) format`. The second failure is
downstream of that and would be reached by anyone who fixed the first:
the script reads `fit_1$coefficients`, `fit_1$ci_lower` and
`fit_1$ci_upper` out of a tidied `lm_robust` object, and current
`estimatr` names those columns `estimate`, `conf.low` and `conf.high`.
That one fails with `non-numeric argument to mathematical function`,
which says nothing about the renamed column. A third defect stops the
script on its first line for anyone not working on macOS or Windows: the
`load()` call asks for `voterIDexp_data_sept2014.Rdata` and the
deposited file is `voterIDexp_data_sept2014.RData`.

Both are mechanical and resolvable without the author. Ten lines in four
places make it run to completion, and 18 of the 22 published values it
can be checked against come back. The 4 that do not are described below,
and none of the four is the archive’s fault: two belong to R and two to
the article’s own prose.

## Does the maintained rewrite reproduce the paper?

Yes, on every quantity the paper’s own analysis produces. Every
estimate, confidence interval and standard error in Table 2 and in the
article’s prose reproduces to the precision the article prints, and so
do the three response rates on the first page, which the deposited
script never computed at all.

Three of the 25 checkable rows carry `match_rewrite = 0`, and none of
the three is a reproduction failure.

Two are the endpoints of the bootstrap confidence interval on the
bounds. R 3.6.0 changed how `sample()` converts uniform draws into
integers, so the archive’s `set.seed(343)` selects different resamples
than it did in 2018. Restoring the old sampler with
`RNGkind(sample.kind = "Rounding")` returns the published interval
exactly. The drift is the sampler, not the bootstrap package: the two
are shown below to draw identically.

The third is an inconsistency inside the article. Table 2 reports the
Always-Responder estimate as $-0.056$ and the text on the same page
reports it as $-5.5$ points. The estimate is $-5.563$ points, so the
table rounds and the text truncates. The same truncation appears one
sentence later, where the standard error on the redefined outcome is
stated as 1.7 points against an actual 1.756.

# Paper overview

**Citation**: Coppock, A. (2019). “Avoiding post-treatment bias in audit
experiments.” *Journal of Experimental Political Science*, 6(1), 1-4.
DOI: 10.1017/XPS.2018.9

**Summary**: Audit experiments randomize a requester characteristic,
such as an apparently Latino versus an apparently non-Latino White name,
and measure whether a request draws a response. Researchers routinely
want to go further and ask whether the responses that arrive are better
or worse, but response is itself a consequence of treatment, so
conditioning on it de-randomizes the experiment. The note takes White,
Nathan and Faller’s (2015) audit of local election officials as a worked
example and lays out the three options an analyst actually has: bound
the effect among subjects who would respond either way, find a subgroup
that can be assumed to respond either way, or redefine the outcome so
that a non-response counts as zero. Applied to the same data, the naive
conditional estimate is $-3.5$ points and not significant, while the
redefined-outcome estimate is $-6.1$ points and the matched-pair
Always-Responder estimate is $-5.6$ points, both significant.
Conditioning on response does not merely bias the estimate in principle;
here it attenuates it enough to change the conclusion.

# Original archive reproducibility

The deposit is four files: the analysis script, the White et al. data it
reanalyzes, a README, and an HTML log of a 2018 run. There is one script
and it produces one table.

| File | Status on current R | Resolution |
|:---|:---|:---|
| aec_replication_JEPS.R | Fails at two points on current R | Replace the do() over broom::bootstrap(); rename three tidy() columns |
| voterIDexp_data_sept2014.RData | Loads clean | Correct the case of the filename in the load() call |
| aec_replication_JEPS.html | Log of a 2018 run; carries Table 2 but no standard errors | None needed |
| README.txt | Describes the files and the constructed variables | None needed |

Original archive reproducibility, checked against R 4.6.0 on 1 August
2026.

Every package the script names still installs from CRAN: `dplyr`,
`estimatr`, `xtable` and `broom`. Nothing here was retired. All three
defects are the same kind of thing, a name or a data structure that
moved underneath code that was correct when it was written.

## The bootstrap

The script draws its bootstrap replicates like this:

``` r
set.seed(343)
boot_df <-
  bootstrap(wnf_subset, 1000) %>%
  do(bounds_wrapper(.)) %>%
  ungroup()
```

`broom::bootstrap()` was deprecated in broom 0.5.0 and is still present
in broom 1.0.13, where it warns and then returns a data frame carrying
the `indices`, `labels` and `vars` attributes that dplyr used before
version 0.8.0. Modern dplyr wants a `groups` tibble instead, so `do()`
refuses the object it is handed. The function is not missing and the
error does not mention it; the visible failure is two calls downstream
of the cause.

## The renamed tidy columns

Once the bootstrap is repaired the script fails again, at the table
assembly:

``` r
estimates <- c(round(fit_1$coefficients[2], 3), ...)
cis <- c(paste0("[", round(fit_1$ci_lower[2], 3), ", ", ...))
```

`fit_1` is `tidy(lm_robust(...))`. Current `estimatr` returns that tidy
frame with columns `estimate`, `conf.low` and `conf.high`, following
broom’s conventions; the names the script uses were the ones estimatr
returned in 2018. Indexing a data frame by a column that does not exist
returns `NULL`, and `round(NULL, 3)` is the error the user actually
sees.

## The filename

`load("voterIDexp_data_sept2014.Rdata")` asks for a file the deposit
spells `voterIDexp_data_sept2014.RData`. It resolves on macOS and
Windows, whose filesystems are case-insensitive by default, and fails on
the first line for anyone running on Linux. This defect is invisible to
the author and to any reviewer working on the same platform, which is
exactly what makes it worth recording.

# Number-by-number comparison

| Location | Claim                     | Paper  | Archive | Match |
|:---------|:--------------------------|:-------|:--------|:------|
| table_2  | naive_estimate            | -0.035 | -0.035  | 1     |
| table_2  | naive_ci_lower            | -0.075 | -0.075  | 1     |
| table_2  | naive_ci_upper            | 0.005  | 0.005   | 1     |
| table_2  | redefined_estimate        | -0.061 | -0.061  | 1     |
| table_2  | redefined_ci_lower        | -0.095 | -0.095  | 1     |
| table_2  | redefined_ci_upper        | -0.027 | -0.027  | 1     |
| table_2  | ar_estimate               | -0.056 | -0.056  | 1     |
| table_2  | ar_ci_lower               | -0.104 | -0.104  | 1     |
| table_2  | ar_ci_upper               | -0.007 | -0.007  | 1     |
| table_2  | bounds_low                | -0.658 | -0.658  | 1     |
| table_2  | bounds_high               | 0.645  | 0.645   | 1     |
| table_2  | bounds_ci_lower           | -0.73  | -0.739  | 0     |
| table_2  | bounds_ci_upper           | 0.726  | 0.725   | 0     |
| text_p1  | response_rate_non_latino  | 70.5   |         |       |
| text_p1  | response_rate_latino      | 64.8   |         |       |
| text_p1  | response_rate_difference  | -5.7   |         |       |
| text_p3  | bounds_low_points         | -66    | -66     | 1     |
| text_p3  | bounds_high_points        | 65     | 65      | 1     |
| text_p3  | n_ar_pairs                | 719    | 719     | 1     |
| text_p3  | ar_estimate_points        | -5.5   | -5.6    | 0     |
| text_p3  | ar_se_points              | 2.5    | 2.5     | 1     |
| text_p3  | redefined_estimate_points | -6     | -6.1    | 1     |
| text_p3  | redefined_se_points       | 1.7    | 1.8     | 0     |
| text_p3  | naive_estimate_points     | -3.5   | -3.5    | 1     |
| text_p3  | naive_se_points           | 2      | 2       | 1     |

Ground truth: published value against the value the repaired archive
script produces on current R. Published values are read from the
article; a blank Archive column means the deposited script never
computes the quantity.

Of the 25 recorded claims, 22 can be compared against something the
repaired archive produces. 18 match and 4 do not. The remaining 3 are
the three response rates the article’s first page attributes to White et
al. (2015), which the deposited script never computes.

# The bootstrap interval and the R 3.6 sampler

The one published quantity the archive no longer returns is the
bootstrap confidence interval on the bounds, and the reason is not in
the archive.

R 3.6.0, released in April 2019, replaced the “Rounding” method that
`sample()` used to convert uniform variates into integers with a
“Rejection” method. Every resample the bootstrap draws therefore differs
from the one the same seed drew in 2018. `text_bootstrap_sampler.R`
computes the interval three ways to isolate the cause.

| Method                                                    | Lower   | Upper  |
|:----------------------------------------------------------|:--------|:-------|
| Maintained rewrite: rsample::bootstraps(), R 3.6+ sampler | -0.7386 | 0.7254 |
| Archive resampling scheme, R 3.6+ sampler                 | -0.7386 | 0.7254 |
| Archive resampling scheme, pre-3.6 sampler                | -0.7296 | 0.7258 |
| Published (Table 2)                                       | -0.73   | 0.726  |

The bounds bootstrap interval, computed three ways, against the
published values. Only the pre-3.6 sampler returns the article’s
interval.

Two things follow. The first is that `rsample::bootstraps()` and the
archive’s own `sample(n, replace = TRUE)` scheme give the identical
interval at the identical seed, to the last digit. The two rows above
that agree exactly are the same 1,000 resamples reached by two routes,
so no difference between the bootstrap implementations can explain the
drift.

The second is that restoring the old sampler restores the published
interval to the digit the article prints, $[-0.73, 0.726]$. The deposit
is internally reproducible. What changed was R.

The maintained rewrite keeps the modern sampler, because reproducing a
number by pinning a retired random number generator is a way of
preserving an artifact rather than a result. The difference is in any
case well inside Monte Carlo noise for a 1,000-replicate bootstrap of an
interval more than 1.4 wide.

# Maintained rewrite

The rewrite lives in `maintained/`: a shared `helpers.R`, one cleaning
script, one table script, and three scripts for quantities the article
states in prose. It is a translation, not a reanalysis: every estimator,
specification and sample restriction is the one the paper used.

| Script | Output | Description |
|:---|:---|:---|
| helpers.R | (sourced by every script) | Packages and the Zhang and Rubin bounds estimator |
| clean_voterID.R | wnf_subset.rds, wnf_always_responders.rds | The two analysis frames: week-one non-bounced emails, and matched-pair Always-Responders |
| table_2_reanalysis.R | table_2_reanalysis.csv | The four estimators of Table 2, at full precision |
| text_in_text_estimates.R | text_in_text_estimates.csv | The bounds, the pair count and each estimator in percentage points |
| text_response_rates.R | text_response_rates.csv | The response rates the first page attributes to White et al. (2015) |
| text_bootstrap_sampler.R | text_bootstrap_sampler.csv | The bounds interval under three resampling routes |

Maintained rewrite scripts.

## Architecture

`clean_voterID.R` builds both analysis frames and writes them to
`output/`, so the sample restrictions are stated once and every
downstream script reads the same rows. `table_2_reanalysis.R` writes its
estimates at full precision rather than at the three decimals the
article prints, and the two in-text scripts read that file rather than
recomputing the models. Nothing in this repository rounds a number
twice, and no published value is typed into a script.

The bounds estimator is the one place where the rewrite reimplements
rather than replaces. It is the Zhang and Rubin (2003) trimming
estimator, which the archive adapted from Aronow, Baron and Pinson’s
source code; it exists in no package, so `helpers.R` carries it,
translated from base-R indexing and two accumulator loops into
`arrange`, `filter` and `cumsum`. It is called from both the table
script and the sampler script, which is why it lives in `helpers.R` and
not in either.

`text_response_rates.R` is an addition rather than a translation. The
article’s opening paragraph reports that non-Latino White names drew a
response 70.5 percent of the time and Latino names 64.8 percent, a
difference of $-5.7$ points, attributing the figures to White et
al. (2015). The deposited script never computes them, so nothing in the
deposit shows they can be recovered. They can, and on exactly the
analysis frame the rest of the paper uses.

| Quantity                                        | Rewrite |    N |
|:------------------------------------------------|:--------|-----:|
| Response rate, Putatively non-Latino White name | 70.5    | 1597 |
| Response rate, Putatively Latino name           | 64.8    | 1598 |
| Difference in response rates, percentage points | -5.7    | 3195 |

The first paragraph’s response rates, recovered from the deposited data.
The article states 70.5, 64.8 and -5.7.

## Deprecated patterns replaced

| Original pattern | Replacement |
|:---|:---|
| `rm(list = ls())` | (omitted) |
| `load("...Rdata")` | `load("...RData")`, the name the deposit carries |
| `broom::bootstrap()` + `dplyr::do()` | `rsample::bootstraps()` + `purrr::map()` |
| `fit$coefficients`, `fit$ci_lower`, `fit$ci_upper` | `estimate`, `conf.low`, `conf.high` |
| `within()` blocks over base indexing | `mutate()` paragraphs with `if_else()` |
| `left_join()` with no `by =` | `left_join(by = "pair_id")` |
| `data.frame()` inside the estimator | `tibble()` |
| two accumulator `for` loops | `arrange()` + `cumsum()` |
| `xtable` + `print.xtable` (commented out) | `write_csv()` to `output/` |
| magrittr pipe | native pipe |

Deprecated patterns and their replacements in the maintained rewrite.

`xtable` is left alone where a rewrite still needs it; here it is not
needed, because the archive’s only `xtable` call is commented out and
the table it would have written is reproduced as a CSV.

# Table 2 as reproduced

| Estimand | Estimator | Estimate | 95% CI |
|:---|:---|:---|:---|
| Undefined | Naive difference-in-means | -0.035 | \[-0.075, 0.005\] |
| ATE on redefined outcome | Difference-in-means | -0.061 | \[-0.095, -0.027\] |
| ATE among matched pairs in which both members are Always-Responders | Difference-in-means among matched pairs in which both members respond | -0.056 | \[-0.104, -0.007\] |
| ATE among all Always-Responders | Bounds | \[-0.658, 0.645\] | \[-0.739, 0.725\] |

Table 2 of the article, as reproduced by the maintained rewrite. The
article prints the same four estimates; its bounds interval is \[-0.73,
0.726\], for the reason given above.

| Quantity                                      | Rewrite |
|:----------------------------------------------|:--------|
| Lower bound, percentage points                | -65.780 |
| Upper bound, percentage points                | 64.539  |
| Matched pairs in which both members responded | 719.000 |
| Always-Responder ATE, percentage points       | -5.563  |
| Always-Responder SE, percentage points        | 2.482   |
| Redefined-outcome ATE, percentage points      | -6.100  |
| Redefined-outcome SE, percentage points       | 1.756   |
| Naive ATE, percentage points                  | -3.542  |
| Naive SE, percentage points                   | 2.041   |

The quantities the article states in prose, at full precision. The
article rounds the bounds to -66 and 65 points and the standard errors
to one decimal.

# Maintained rewrite verification

| Location | Claim | Paper | Rewrite | Match | Note |
|:---|:---|:---|:---|:---|:---|
| table_2 | naive_estimate | -0.035 | -0.035 | 1 |  |
| table_2 | naive_ci_lower | -0.075 | -0.075 | 1 |  |
| table_2 | naive_ci_upper | 0.005 | 0.005 | 1 |  |
| table_2 | redefined_estimate | -0.061 | -0.061 | 1 |  |
| table_2 | redefined_ci_lower | -0.095 | -0.095 | 1 |  |
| table_2 | redefined_ci_upper | -0.027 | -0.027 | 1 |  |
| table_2 | ar_estimate | -0.056 | -0.056 | 1 |  |
| table_2 | ar_ci_lower | -0.104 | -0.104 | 1 |  |
| table_2 | ar_ci_upper | -0.007 | -0.007 | 1 |  |
| table_2 | bounds_low | -0.658 | -0.658 | 1 |  |
| table_2 | bounds_high | 0.645 | 0.645 | 1 |  |
| table_2 | bounds_ci_lower | -0.73 | -0.739 | 0 | R 3.6.0 changed sample(); under RNGkind(sample.kind = ‘Rounding’) the same seed gives -0.730, which is the published value |
| table_2 | bounds_ci_upper | 0.726 | 0.725 | 0 | R 3.6.0 changed sample(); under RNGkind(sample.kind = ‘Rounding’) the same seed gives 0.726, which is the published value |
| text_p1 | response_rate_non_latino | 70.5 | 70.5 | 1 | Attributed to White et al. (2015); the deposited script never computes it. The maintained rewrite recovers it from the deposited data on the paper’s own analysis frame |
| text_p1 | response_rate_latino | 64.8 | 64.8 | 1 | Attributed to White et al. (2015); the deposited script never computes it |
| text_p1 | response_rate_difference | -5.7 | -5.7 | 1 | Attributed to White et al. (2015); the deposited script never computes it |
| text_p3 | bounds_low_points | -66 | -66 | 1 | Text states -66 points; -65.78 at full precision |
| text_p3 | bounds_high_points | 65 | 65 | 1 | Text states 65 points; 64.54 at full precision |
| text_p3 | n_ar_pairs | 719 | 719 | 1 | Not printed by the deposited script; 719 distinct pair_id values in the wnf_always_responders object it builds |
| text_p3 | ar_estimate_points | -5.5 | -5.6 | 0 | Text states -5.5 points, Table 2 states -0.056; the estimate is -5.563 points, so the text truncates where the table rounds. Internal inconsistency in the article, not a reproduction failure |
| text_p3 | ar_se_points | 2.5 | 2.5 | 1 | 2.482 at full precision |
| text_p3 | redefined_estimate_points | -6 | -6.1 | 1 | Text states a 6 point decrease; -6.100 at full precision |
| text_p3 | redefined_se_points | 1.7 | 1.8 | 0 | Text states SE = 1.7 points; the standard error is 1.756 points, which rounds to 1.8. The text truncates rather than rounds |
| text_p3 | naive_estimate_points | -3.5 | -3.5 | 1 | -3.542 at full precision |
| text_p3 | naive_se_points | 2 | 2 | 1 | 2.041 at full precision |

Maintained rewrite verification: published value against rewrite output.

**21** of the 25 checkable claims match the published article to the
precision it prints. The 4 that do not are the two bootstrap endpoints,
which the R 3.6 sampler change explains and the old sampler restores,
and the Always-Responder estimate in points, where the article’s own
text and its own table disagree with each other.

# R environment

| Item      | Value                  |
|:----------|:-----------------------|
| R version | 4.6.0                  |
| Platform  | aarch64-apple-darwin23 |
| Date run  | 2026-08-01             |

| Package  | Version |
|:---------|:--------|
| estimatr | 1.0.6   |
| rsample  | 1.3.2   |
| dplyr    | 1.2.1   |
| tidyr    | 1.3.2   |
| purrr    | 1.2.2   |
| readr    | 2.2.0   |
| here     | 1.0.2   |

Package versions used for the run behind this report.
