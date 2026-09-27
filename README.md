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
- [Errata](#errata)
- [Number-by-number comparison](#number-by-number-comparison)
- [The extraction and the two
  instruments](#the-extraction-and-the-two-instruments)
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
published number to the code that produces it: `published_claims.csv` is
the extraction of every number the article prints,
`extract_archive_values.R` runs the deposited script, and
`build_ground_truth.R` assembles the comparison and gates it.
`original/` is created by the download script and is deliberately absent
from the repository. `errata.qmd` renders the four corrections the
article needs. This file is the reproducibility report, also available
as a PDF in `report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`coppock_2019b.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposit, verifies its four files, produces the
published table and every in-text quantity into `maintained/output/`,
runs the deposited script in a scratch directory, rebuilds the ground
truth with its coverage gates, and prints one line per numeric claim the
article makes. Required packages: tidyverse, estimatr, rsample, broom,
xtable, knitr, kableExtra, here. Paths resolve through `here`, so
nothing depends on the working directory. The run takes well under a
minute, most of it in the 4,000 bootstrap replicates of the bounds
estimator. A successful run overwrites `maintained/output/`, which is
committed: **`git diff` on that folder is the reproduction check.**

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
places make it run to completion, and 27 of the 31 published values it
can be checked against come back. The 4 that do not are described below,
and none of the four is the archive’s fault: two belong to R and two to
the article’s own prose.

## Does the maintained rewrite reproduce the paper?

Yes, on every quantity the paper’s own analysis produces. Every
estimate, confidence interval and standard error in Table 2 and in the
article’s prose reproduces to the precision the article prints, and so
do the three response rates on the first page, which the deposited
script never computes at all. Both of the article’s descriptive claims
about statistical significance hold.

4 of the 31 checkable rows carry `match_rewrite = 0`, and none of the
four is a reproduction failure.

Two are the endpoints of the bootstrap confidence interval on the
bounds. R 3.6.0 changed how `sample()` converts uniform draws into
integers, so the archive’s `set.seed(343)` selects different resamples
than it did in 2018. Restoring the old sampler with
`RNGkind(sample.kind = "Rounding")` returns the published interval
exactly. The drift is the sampler, not the bootstrap package: the two
are shown below to draw identically.

The other two are inconsistencies inside the article, and each is an
entry in the errata note this repository carries. Table 2 reports the
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

# Errata

The article needs four corrections, three of them in the reanalysis
paragraph on page 3 and the fourth in Table 2, and none of them changes
a conclusion. `errata.qmd` sets them out and renders to
`coppock_2019b_errata.pdf` at the root of this repository, computing
every corrected value from `maintained/output/` at the moment it is
rendered, so the note cannot go stale in the way the sentences did.

Two of them are the same defect. The article gives the Always-Responder
estimate as $-5.5$ points where its own Table 2 gives $-0.056$, and the
standard error on the redefined outcome as 1.7 points where the standard
error is 1.756. In each case the published figure is the correct value
truncated rather than rounded at the last digit it prints. Table 2 is
right in every cell it prints, which is why the errata quotes its cells
rather than reprinting it.

The third is a dropped word rather than a wrong number. The same
paragraph gives the naive estimate as $-3.5$ percentage, with no unit,
where every other figure around it is in points. It came out of reading
the article word by word against its own PDF to prepare a remastered
edition, which is a finer sieve than the number-by-number comparison
below.

That is a separate matter from the repairs described above, which are to
the deposited *code*. No analytical decision in the deposit was changed,
and the rewrite corrects no coding error, because there is none to
correct.

# Number-by-number comparison

| Location | Claim | Paper | Archive | Match |
|:---|:---|:---|:---|:---|
| Introduction, p. 1 | Share of putatively non-Latino White names that received a response | 70.5 | 70.50720000 | 1 |
| Introduction, p. 1 | Share of putatively Latino names that received a response | 64.8 | 64.83100000 | 1 |
| Introduction, p. 1 | Difference in response rates, percentage points | -5.7 | -5.67616000 | 1 |
| Introduction, p. 1 | Whether the difference in response rates is statistically significant at the 0.05 level | 1 | NA |  |
| Table 1, p. 2 | Table 1, Always-Responder, R_i(0) | 1 | 1.00000000 | 1 |
| Table 1, p. 2 | Table 1, Always-Responder, R_i(1) | 1 | 1.00000000 | 1 |
| Find Always-Responders, p. 2 | Response rate required in both arms under the Always-Responders assumption | 100 | 100.00000000 | 1 |
| Table 2, p. 3 | Table 2, naive difference-in-means, estimate | -0.035 | -0.03542390 | 1 |
| Table 2, p. 3 | Table 2, naive difference-in-means, lower confidence limit | -0.075 | -0.07544890 | 1 |
| Table 2, p. 3 | Table 2, naive difference-in-means, upper confidence limit | 0.005 | 0.00460118 | 1 |
| Table 2, p. 3 | Table 2, redefined outcome, estimate | -0.061 | -0.06099950 | 1 |
| Table 2, p. 3 | Table 2, redefined outcome, lower confidence limit | -0.095 | -0.09543510 | 1 |
| Table 2, p. 3 | Table 2, redefined outcome, upper confidence limit | -0.027 | -0.02656380 | 1 |
| Table 2, p. 3 | Table 2, matched-pair Always-Responders, estimate | -0.056 | -0.05563280 | 1 |
| Table 2, p. 3 | Table 2, matched-pair Always-Responders, lower confidence limit | -0.104 | -0.10431800 | 1 |
| Table 2, p. 3 | Table 2, matched-pair Always-Responders, upper confidence limit | -0.007 | -0.00694736 | 1 |
| Table 2, p. 3 | Table 2, bounds, lower bound | -0.658 | -0.65780100 | 1 |
| Table 2, p. 3 | Table 2, bounds, upper bound | 0.645 | 0.64539000 | 1 |
| Table 2, p. 3 | Table 2, bounds, lower bootstrap confidence limit | -0.73 | -0.73863800 | 0 |
| Table 2, p. 3 | Table 2, bounds, upper bootstrap confidence limit | 0.726 | 0.72535200 | 0 |
| Table 2, p. 3 | Confidence level of the Table 2 intervals | 95 | 95.00000000 | 1 |
| Redefine the outcome, p. 3 | Value the redefined outcome takes when no e-mail is sent | 0 | 0.00000000 | 1 |
| Reanalysis, p. 3 | Zhang and Rubin lower bound, percentage points | -66 | -65.78010000 | 1 |
| Reanalysis, p. 3 | Zhang and Rubin upper bound, percentage points | 65 | 64.53900000 | 1 |
| Reanalysis, p. 3 | Matched pairs in which both members responded | 719 | 719.00000000 | 1 |
| Reanalysis, p. 3 | Always-Responder ATE, percentage points | -5.5 | -5.56328000 | 0 |
| Reanalysis, p. 3 | Always-Responder standard error, percentage points | 2.5 | 2.48190000 | 1 |
| Reanalysis, p. 3 | Redefined-outcome ATE, percentage points | -6 | -6.09995000 | 1 |
| Reanalysis, p. 3 | Redefined-outcome standard error, percentage points | 1.7 | 1.75629000 | 0 |
| Reanalysis, p. 3 | Whether the redefined-outcome interval excludes zero while the naive interval contains it | 1 | NA |  |
| Reanalysis, p. 3 | Naive ATE, percentage points | -3.5 | -3.54239000 | 1 |
| Reanalysis, p. 3 | Naive standard error, percentage points | 2.0 | 2.04099000 | 1 |
| Reanalysis, p. 3 | Estimates displayed in Table 2 | 4 | 4.00000000 | 1 |

Ground truth: published value against the value the repaired archive
script produces on current R. Published values are read from the
article; a blank Archive column means the deposited script never
computes the quantity.

Of the 33 recorded claims, 31 can be compared against something the
repaired archive produces. 27 match and 4 do not. The other 2 are the
article’s two claims about statistical significance, which have no
number to compare and carry a truth value instead; both hold.

`value_script` is not typed here.
`ground_truth/extract_archive_values.R` copies the deposit into a
scratch directory, applies the four repairs described above to its own
source text, runs it there, and writes what it produces to
`ground_truth/archive_values.csv`, which is what this column reads.
Three of the values in that file are counts and rates of the two frames
the deposited cleaning code builds rather than results the deposited
script prints: the article’s three opening response rates are among
them, and recording them as the deposit’s own is the claim that the
deposit’s data support the figures the article attributes to White,
Nathan and Faller (2015).

# The extraction and the two instruments

`ground_truth/published_claims.csv` is the extraction: every numeric
token in the article’s four published pages, read out with its
surrounding context and then classified by hand, followed by a second
sweep for numbers written as words, which no token scan sees. Citation
years, DOI numerals, running heads and the publisher’s own front matter
are the only tokens excluded. The article has no separate appendix.

| Class        | Claims | Requiring a block |
|:-------------|-------:|------------------:|
| definitional |     15 |                 5 |
| descriptive  |      2 |                 2 |
| pipeline     |     25 |                25 |
| structural   |      6 |                 1 |
| transcribed  |      4 |                 0 |

The extraction, by claim type. A pipeline or descriptive claim must have
a ground-truth row and a block in the claims file; a definitional,
structural or transcribed claim gets a block only where the pipeline can
reach the quantity, and is otherwise verified at the point of use.

Coverage of the two published tables is stated as a fraction rather than
as an existence check, because one row is not coverage of a float. All
14 of Table 2’s published numbers are covered, counting its confidence
level. 2 of Table 1’s 8 are: Table 1 is a stipulated typology of
principal strata, and only the Always-Responder row names units any
analysis identifies. The other three strata are verified nowhere, which
is a property of the paper rather than a gap in this repository.

`maintained/in_text_claims.R` is the second instrument. It carries one
block per claim, each with the article’s own sentence quoted verbatim
above code that recomputes the number from `maintained/output/` and
prints it at the precision the article prints. It never reads the ground
truth, never refits a model, and where `build_ground_truth.R` reaches a
quantity through one output file it reaches the same quantity through
another: the percentage-point figures come from the Table 2 estimates
rather than from `text_in_text_estimates.csv`, the pair count and the
response rates from the analysis frames, and the two significance claims
from the confidence intervals where the ground truth uses the p-values.
Agreement between two derivations is evidence the arithmetic is right;
it is not evidence that the quantity is the one the sentence names,
which is what writing the block out of the sentence is for.

`build_ground_truth.R` then gates the whole arrangement. It sources the
claims file as a program into its own environment and counts the claim
lines it prints, so a block that errors, or that ends in a bare
expression and prints nothing under `source()`, fails rather than
passing as coverage. It asserts that the 33 printed claim ids are
exactly the 33 the extraction declares, that every pipeline and
descriptive claim has a ground-truth row, that no ground-truth row names
a claim the article does not make, and that the two instruments agree
value by value at the article’s own precision. It also asserts that
every row carrying an adverse verdict has a `defect_locus` and that no
clean row has one, reading all three of `match`, `match_rewrite` and
`holds`, since a gate stated on the rewrite alone cannot see a failing
descriptive claim or an archive failure the rewrite passes.

| Location | Claim | Paper | Rewrite | Locus |
|:---|:---|:---|:---|:---|
| Table 2, p. 3 | Table 2, bounds, lower bootstrap confidence limit | -0.73 | -0.739 | environment |
| Table 2, p. 3 | Table 2, bounds, upper bootstrap confidence limit | 0.726 | 0.725 | environment |
| Reanalysis, p. 3 | Always-Responder ATE, percentage points | -5.5 | -5.563 | paper_internal |
| Reanalysis, p. 3 | Redefined-outcome standard error, percentage points | 1.7 | 1.756 | paper_internal |

Every row whose verdict is adverse, and where the fault lies.

2 are the environment, and 2 are the article disagreeing with itself.
Neither is a defect in the deposited code and neither is a defect in the
rewrite.

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
| in_text_claims.R | (printed claim lines only) | One block per numeric claim the article makes, recomputed and printed |

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

| Location | Claim | Paper | Rewrite | Verdict | Note |
|:---|:---|:---|:---|:---|:---|
| Introduction, p. 1 | Share of putatively non-Latino White names that received a response | 70.5 | 70.50720000 | 1 | The deposited script never computes this; value_script is the rate on the analysis frame the deposit itself builds |
| Introduction, p. 1 | Share of putatively Latino names that received a response | 64.8 | 64.83100000 | 1 | The deposited script never computes this; value_script is the rate on the analysis frame the deposit itself builds |
| Introduction, p. 1 | Difference in response rates, percentage points | -5.7 | -5.67616000 | 1 | The deposited script never computes this; value_script is the difference on the analysis frame the deposit itself builds |
| Introduction, p. 1 | Whether the difference in response rates is statistically significant at the 0.05 level | 1 | 1.00000000 | 1 | The deposit fits no model of response, so it has no verdict here. The rewrite’s two-sided p-value on the difference in response rates is the test the sentence claims |
| Table 1, p. 2 | Table 1, Always-Responder, R_i(0) | 1 | 1.00000000 | 1 | Read back off the Always-Responder frame rather than asserted |
| Table 1, p. 2 | Table 1, Always-Responder, R_i(1) | 1 | 1.00000000 | 1 | Read back off the Always-Responder frame rather than asserted |
| Find Always-Responders, p. 2 | Response rate required in both arms under the Always-Responders assumption | 100 | 100.00000000 | 1 | The article’s own stated check on the Always-Responders assumption |
| Table 2, p. 3 | Table 2, naive difference-in-means, estimate | -0.035 | -0.03542390 | 1 |  |
| Table 2, p. 3 | Table 2, naive difference-in-means, lower confidence limit | -0.075 | -0.07544890 | 1 |  |
| Table 2, p. 3 | Table 2, naive difference-in-means, upper confidence limit | 0.005 | 0.00460118 | 1 |  |
| Table 2, p. 3 | Table 2, redefined outcome, estimate | -0.061 | -0.06099950 | 1 |  |
| Table 2, p. 3 | Table 2, redefined outcome, lower confidence limit | -0.095 | -0.09543510 | 1 |  |
| Table 2, p. 3 | Table 2, redefined outcome, upper confidence limit | -0.027 | -0.02656380 | 1 |  |
| Table 2, p. 3 | Table 2, matched-pair Always-Responders, estimate | -0.056 | -0.05563280 | 1 |  |
| Table 2, p. 3 | Table 2, matched-pair Always-Responders, lower confidence limit | -0.104 | -0.10431800 | 1 |  |
| Table 2, p. 3 | Table 2, matched-pair Always-Responders, upper confidence limit | -0.007 | -0.00694736 | 1 |  |
| Table 2, p. 3 | Table 2, bounds, lower bound | -0.658 | -0.65780100 | 1 |  |
| Table 2, p. 3 | Table 2, bounds, upper bound | 0.645 | 0.64539000 | 1 |  |
| Table 2, p. 3 | Table 2, bounds, lower bootstrap confidence limit | -0.73 | -0.73863800 | 0 | R 3.6.0 changed sample(); under RNGkind(sample.kind = ‘Rounding’) the same seed gives -0.730, which is the published value. text_bootstrap_sampler.csv carries all three intervals |
| Table 2, p. 3 | Table 2, bounds, upper bootstrap confidence limit | 0.726 | 0.72535200 | 0 | R 3.6.0 changed sample(); under RNGkind(sample.kind = ‘Rounding’) the same seed gives 0.726, which is the published value. text_bootstrap_sampler.csv carries all three intervals |
| Table 2, p. 3 | Confidence level of the Table 2 intervals | 95 | 95.00000000 | 1 | The column header is a claim about the intervals beside it; the level is recovered from the ratio of each half width to its standard error |
| Redefine the outcome, p. 3 | Value the redefined outcome takes when no e-mail is sent | 0 | 0.00000000 | 1 | The redefined outcome’s floor, read off the analysis frame |
| Reanalysis, p. 3 | Zhang and Rubin lower bound, percentage points | -66 | -65.78010000 | 1 | The article rounds to whole points; -65.78 at full precision |
| Reanalysis, p. 3 | Zhang and Rubin upper bound, percentage points | 65 | 64.53900000 | 1 | The article rounds to whole points; 64.54 at full precision |
| Reanalysis, p. 3 | Matched pairs in which both members responded | 719 | 719.00000000 | 1 | Distinct pair identifiers among the Always-Responder pairs. One pair contributes an odd number of surviving rows, so halving the row count would give 719.5 |
| Reanalysis, p. 3 | Always-Responder ATE, percentage points | -5.5 | -5.56328000 | 0 | The text states -5.5 points and Table 2 states -0.056 for the same estimate. It is -5.563 points, so the table rounds and the text truncates. An inconsistency inside the article, not a reproduction failure |
| Reanalysis, p. 3 | Always-Responder standard error, percentage points | 2.5 | 2.48190000 | 1 | 2.482 at full precision |
| Reanalysis, p. 3 | Redefined-outcome ATE, percentage points | -6 | -6.09995000 | 1 | The article states a 6 point decrease; -6.100 at full precision |
| Reanalysis, p. 3 | Redefined-outcome standard error, percentage points | 1.7 | 1.75629000 | 0 | The text states SE = 1.7 points. It is 1.756 points, which rounds to 1.8; the text truncates. Table 2 prints no standard errors, so this figure appears only in prose |
| Reanalysis, p. 3 | Whether the redefined-outcome interval excludes zero while the naive interval contains it | 1 | 1.00000000 | 1 | Evaluated here from the two p-values; in_text_claims.R evaluates the same contrast from the two confidence intervals. The deposit prints no p-values |
| Reanalysis, p. 3 | Naive ATE, percentage points | -3.5 | -3.54239000 | 1 | -3.542 at full precision |
| Reanalysis, p. 3 | Naive standard error, percentage points | 2.0 | 2.04099000 | 1 | 2.041 at full precision |
| Reanalysis, p. 3 | Estimates displayed in Table 2 | 4 | 4.00000000 | 1 | Estimator rows in the reproduced Table 2 |

Maintained rewrite verification: published value against rewrite output.
The verdict is the rewrite’s match, except on the two descriptive
claims, which have no number to compare and carry a truth value instead.

**27** of the 31 checkable claims match the published article to the
precision it prints, and both of the 2 descriptive claims hold. The 4
that do not match are the two bootstrap endpoints, which the R 3.6
sampler change explains and the old sampler restores, and the two
figures in the reanalysis paragraph where the article’s own prose
disagrees with its own table and with the estimates behind it. Those two
are the first two errata.

# R environment

| Item      | Value                  |
|:----------|:-----------------------|
| R version | 4.6.0                  |
| Platform  | aarch64-apple-darwin23 |
| Date run  | 2026-09-27             |

| Package  | Version |
|:---------|:--------|
| estimatr | 2.0.1   |
| rsample  | 1.3.2   |
| dplyr    | 1.2.1   |
| tidyr    | 1.3.2   |
| purrr    | 1.2.2   |
| readr    | 2.2.0   |
| here     | 1.0.2   |

Package versions used for the run behind this report.
