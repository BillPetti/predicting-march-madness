if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(caret, MASS) # load ML packages that unfortunately mask dplyr functions
p_load(tidyverse, janitor)

active_model <- read_rds("data/models/glm_all_data.Rds")

### Make predictions for stage 1 ----------------------------

blank_stage_1_preds <- read_csv("data/kaggle/SampleSubmissionStage1.csv") %>%
  clean_names() %>%
  separate(id, into = c("year", "lower_team", "higher_team"), sep = "_", remove = FALSE, convert = TRUE) %>%
  select(-pred)

stage_1_with_data <- blank_stage_1_preds %>%
  add_kp_data %>% # get this from the file 03_tidy_raw_data.R ; you'll also need the object kp_dat so run that script first
  create_vars_for_prediction %>%
  mutate(lower_team_court_adv = as.factor("N")) %>%
  dplyr::select(contains("diff"), lower_team_court_adv, contains("rank"))

stage_1_preds <- predict(active_model, stage_1_with_data, type = "prob")[, 2]

preds_to_send <- blank_stage_1_preds %>%
  select(id) %>%
  mutate(Pred = stage_1_preds)

write_csv(preds_to_send, "data/predictions/glm_1.csv")

### Make predictions for final round ----------------------------

# For final round: Average with 538 first round predictions
# And/or, if you don't mind the impurity, gain an edge by picking a game 100% in one submission and 0% in another

final_blank <- read_csv("data/kaggle/SampleSubmission.csv") %>%
  clean_names()
  separate(id, into = c("year", "lower_team", "higher_team"), sep = "_", remove = FALSE, convert = TRUE) %>%
  dplyr::select(-pred)

final_blank_with_data <- final_blank %>%
  add_kp_data %>%
  create_vars_for_prediction %>%
  mutate(lower_team_court_adv = as.factor("N")) %>%
  dplyr::select(contains("diff"), lower_team_court_adv, contains("rank")) %>%
  dplyr::select(-lower_pre_seas_rank_all, -higher_pre_seas_rank_all)

levels(final_blank_with_data$lower_team_court_adv) <- c("N", "H", "A") # to make levels match the training set

final_preds_1 <- predict(active_model, final_blank_with_data, type = "prob")[, 2]

final_preds_to_send <- final_blank %>%
  select(id) %>%
  mutate(Pred = stage_1_preds)


write_csv(final_preds_to_send, "data/predictions/final_glm.csv")

# Average with 538 1st round predictions
# Or if you don't mind the impurity of it, pick a first round game 0% in one submission and 100% in the other to gain an edge