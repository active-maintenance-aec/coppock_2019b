# coppock_2019b/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first), the deposited script itself
# Description: Run the deposited script exactly as shipped, with no repair, and record
#   whether it finishes and what it writes. extract_archive_values.R answers a different
#   question: it repairs the deposit's four defects in a scratch copy so that the ground
#   truth's value_script column can be generated. This file records the deposit's own
#   behavior before any repair.
#
#   Two passes, each in a fresh scratch directory that holds a copy of the deposit and
#   nothing else, so original/ is never written to and never run in:
#   - as_shipped: all four deposited files.
#   - stripped: the data and the code only. The deposit ships no intermediate that its
#     own code reads, so the HTML log and the README are the only files withheld, and
#     neither is an input to anything.
#
#   The deposit is one script that both cleans and analyzes, so it gets one row per pass
#   with role "analysis".
#
#   This file is not part of run_all.R, because its record depends on the filesystem.
#   The script's load() call asks for .Rdata and the deposit carries .RData, which
#   resolves on the case-insensitive filesystems macOS and Windows use by default and
#   fails on Linux. The committed record is from macOS, where the script gets past
#   load() and stops at the bootstrap; on Linux it stops at load(), so a rerun there
#   would rewrite stopped_at and fail the maintenance check on a difference that is the
#   deposit's own defect rather than drift.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

deposited_script <- "aec_replication_JEPS.R"
deposit_files <- list.files(here::here("original"))
stopifnot(deposited_script %in% deposit_files, length(deposit_files) == 4)

pass_files <- list(
  as_shipped = deposit_files,
  stripped = c(deposited_script, "voterIDexp_data_sept2014.RData")
)

# file_md5: a named vector of checksums for every file under a directory.
file_md5 <- function(dir) {
  files <- list.files(dir, recursive = TRUE)
  set_names(unname(tools::md5sum(file.path(dir, files))), files)
}

# run_pass: copy one pass's files into a fresh directory, run the script there as a
# separate R process, and return the run's record and the files it changed.
run_pass <- function(pass) {
  run_dir <- file.path(tempdir(), str_c("coppock_2019b_", pass))
  unlink(run_dir, recursive = TRUE)
  dir.create(run_dir)
  stopifnot(all(file.copy(here::here("original", pass_files[[pass]]), run_dir)))

  before <- file_md5(run_dir)
  run <- processx::run(file.path(R.home("bin"), "Rscript"), deposited_script,
                       wd = run_dir, error_on_status = FALSE, timeout = 600)
  after <- file_md5(run_dir)

  # The error R prints, from its first line up to the backtrace or the warnings that
  # follow it.
  stderr_lines <- str_split_1(run$stderr, "\n")
  error_start <- str_which(stderr_lines, "^Error")
  stopped_at <- if (length(error_start) == 0) {
    NA_character_
  } else {
    error_lines <- stderr_lines[error_start[1]:length(stderr_lines)]
    error_end <- c(str_which(error_lines, "^(Backtrace:|In addition|Warning message|Execution halted)"),
                   length(error_lines) + 1)[1]
    error_lines[seq_len(error_end - 1)] |>
      str_c(collapse = " ") |>
      str_squish()
  }

  status <- tibble(
    pass = pass,
    script = deposited_script,
    role = "analysis",
    exit_status = if (run$timeout) NA_integer_ else as.integer(run$status),
    outcome = case_when(run$timeout ~ "timeout", run$status == 0 ~ "clean",
                        .default = "error"),
    stopped_at = stopped_at
  )

  overwrites <- bind_rows(
    tibble(file = setdiff(names(after), names(before)), effect = "added",
           matches_deposit = NA),
    tibble(file = intersect(names(before), names(after))) |>
      filter(before[file] != after[file]) |>
      mutate(effect = "overwritten", matches_deposit = FALSE),
    tibble(file = setdiff(names(before), names(after)), effect = "deleted",
           matches_deposit = NA)
  ) |>
    mutate(pass = pass, .before = 1)

  list(status = status, overwrites = overwrites)
}

# Run both passes ----
runs <- map(names(pass_files), run_pass)

run_status <- map(runs, "status") |> list_rbind()
overwrites <- map(runs, "overwrites") |>
  list_rbind() |>
  select(pass, file, effect, matches_deposit)

stopifnot(nrow(run_status) == 2, !anyNA(run_status$outcome))

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(run_status, width = 200)
print(overwrites)
