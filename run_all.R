# coppock_2019b/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, rebuild
# the two analysis frames, then Table 2 and the quantities the article states in prose.
# Every script is self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Cleaning ----
source(here::here("maintained", "clean_voterID.R"))

# Tables ----
source(here::here("maintained", "table_2_reanalysis.R"))

# In-text quantities ----
# text_in_text_estimates.R reads the Table 2 estimates, so it runs after the table.
source(here::here("maintained", "text_in_text_estimates.R"))
source(here::here("maintained", "text_response_rates.R"))

# Bootstrap sampler comparison ----
# Three thousand further bootstrap replicates of the bounds estimator, about nine
# seconds, which is most of the run.
source(here::here("maintained", "text_bootstrap_sampler.R"))

# The deposited script, run on current R ----
# Repairs the deposit's four defects in a scratch copy and runs it there, so that the
# ground truth's value_script column is generated rather than transcribed. original/ is
# never written to and never run in.
source(here::here("ground_truth", "extract_archive_values.R"))

# Ground truth ----
# Reads every value_rewrite back out of maintained/output/, so it has to run last. It
# also runs in_text_claims.R under capture.output as its coverage gate, so that file
# necessarily runs twice per pipeline: once silently for the gate, and once below for
# the readable log.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims ----
# The second instrument. One block per numeric claim the article makes, each recomputing
# the number from maintained/output/ by its own path.
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
