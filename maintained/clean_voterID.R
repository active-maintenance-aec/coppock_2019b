# coppock_2019b/maintained/clean_voterID.R
# Output: output/wnf_subset.rds, output/wnf_always_responders.rds
# Depends on: original/voterIDexp_data_sept2014.RData, helpers.R
# Description: Rebuild the two analysis frames the paper works from: the week-one
#   voter-registration emails that did not bounce, and the subset of those belonging to
#   matched pairs in which both members responded.
source(here::here("maintained", "helpers.R"))

# The deposited file is voterIDexp_data_sept2014.RData. The archive's own script asks
# for voterIDexp_data_sept2014.Rdata, which resolves on macOS and Windows and fails on
# Linux; the name here is the one the deposit actually carries.
load(here::here("original", "voterIDexp_data_sept2014.RData"))
wnf <- data
rm(data)

# Subset to voter registration emails in week one, dropping two states ----
# Codes 41 and 12 are the two states the original analysis excludes.
wnf_subset <- wnf |>
  filter(
    !code %in% c(41, 12),
    week == 1,
    first_text == 1
  ) |>
  mutate(
    bounced = as.numeric(is.na(response)),
    response_no_na = if_else(is.na(response), 0L, response),
    friendly_no_na = if_else(is.na(friendly), 0L, friendly),
    pair_id = paste0(fullpair, "_", code.fac)
  )

# Flag matched pairs in which both members responded ----
pair_level <- wnf_subset |>
  group_by(pair_id) |>
  summarize(num_response = sum(response, na.rm = TRUE), .groups = "drop")

wnf_subset <- wnf_subset |>
  left_join(pair_level, by = "pair_id") |>
  mutate(AR = (num_response == 2)) |>
  filter(bounced == 0) |>
  select(pair_id, code, week, first_text, first_name_latino, response, response_no_na,
         friendly, friendly_no_na, bounced, num_response, AR)

# Always-Responders ----
# Two responding officials have no friendliness code; the original analysis treats them
# as unfriendly, which is the assumption carried forward here.
wnf_always_responders <- wnf_subset |>
  filter(AR, response_no_na == 1) |>
  mutate(friendly = if_else(is.na(friendly), 0L, friendly))

write_rds(wnf_subset, here::here("maintained", "output", "wnf_subset.rds"))
write_rds(wnf_always_responders, here::here("maintained", "output", "wnf_always_responders.rds"))
