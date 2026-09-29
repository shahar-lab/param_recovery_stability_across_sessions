# reads: artifacts/true_population.rds, artifacts/true_parameters.rds
# writes: artifacts/simulated_data.rds

#### GENERATE DATA ####

true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))

gamma_session         <- attr(true_parameters, "gamma_session")
gamma_subjectXsession <- attr(true_parameters, "gamma_subjectXsession")

df_list <- vector("list", n_subjects * n_sessions)
idx     <- 1

for (i in seq_len(n_subjects)) {
  for (j in seq_len(n_sessions)) {
    params <- c(
      intercept             = true_population$intercept,
      sigma_error           = true_population$sigma_error,
      gamma_subject         = true_parameters$gamma_subject[i],
      gamma_session         = gamma_session[j],
      gamma_subjectXsession = gamma_subjectXsession[i, j]
    )
    df_cell <- generate_linear_reg_two_sessions(n_trials, params)
    df_cell$subject_id <- i
    df_cell$session_id <- j
    df_cell$trial      <- seq_len(n_trials)
    df_list[[idx]]     <- df_cell
    idx <- idx + 1
  }
}

df <- bind_rows(df_list)

saveRDS(df, file.path(artifacts_dir, "simulated_data.rds"))
