# reads: artifacts/true_population.rds, artifacts/true_parameters.rds
# writes: artifacts/simulated_data.rds

#### GENERATE DATA ####

true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))

df_list <- vector("list", nrow(true_parameters))

for (k in seq_len(nrow(true_parameters))) {
  row <- true_parameters[k, ]
  params <- c(
    mu_log_beta           = true_population$mu_log_beta,
    gamma_subject         = row$gamma_subject,
    gamma_session         = row$gamma_session,
    gamma_subjectXsession = row$gamma_subjectXsession,
    alpha                 = row$alpha,
    p_reward_1            = true_population$p_reward[1],
    p_reward_2            = true_population$p_reward[2]
  )
  df_cell <- generate_rl_bandit_two_sessions(true_population$n_trials, params)
  df_cell$subject_id <- row$subject_id
  df_cell$session_id <- row$session_id
  df_list[[k]]       <- df_cell
}

df <- bind_rows(df_list) |>
  select(subject_id, session_id, trial, choice, reward)

saveRDS(df, file.path(artifacts_dir, "simulated_data.rds"))
