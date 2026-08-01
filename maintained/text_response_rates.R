# coppock_2019b/maintained/text_response_rates.R
# Output: output/text_response_rates.csv
# Depends on: clean_voterID.R output, helpers.R
# Description: The response rates the article's opening paragraph attributes to White,
#   Nathan and Faller (2015): 70.5 percent for putatively non-Latino White names, 64.8
#   percent for putatively Latino names, a difference of negative 5.7 points. The
#   deposited script never computes them, so nothing in the archive shows that they can
#   be recovered from the deposited data. They can, on exactly the analysis frame the
#   rest of the paper uses.
source(here::here("maintained", "helpers.R"))

wnf_subset <- read_rds(here::here("maintained", "output", "wnf_subset.rds"))

by_arm <- wnf_subset |>
  summarize(
    response_rate = 100 * mean(response),
    n = n(),
    .by = first_name_latino
  ) |>
  arrange(first_name_latino) |>
  mutate(arm = if_else(first_name_latino == 1, "Putatively Latino name",
                       "Putatively non-Latino White name"))

fit_response <- lm_robust(response ~ first_name_latino, data = wnf_subset)

response_rates <- by_arm |>
  transmute(claim = str_c("Response rate, ", arm), value = response_rate, n) |>
  bind_rows(tibble(
    claim = "Difference in response rates, percentage points",
    value = 100 * coef(fit_response)[["first_name_latino"]],
    n = as.integer(fit_response$nobs)
  ))

write_csv(response_rates, here::here("maintained", "output", "text_response_rates.csv"))
