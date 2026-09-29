# reads: artifacts/simulated_data.rds
# writes: artifacts/stan_fit.rds, artifacts/draws_sbj.rds, artifacts/draws_pop.rds

#### FIT MODEL ####

df <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))

stan_data <- list(
  N          = nrow(df),
  n_subjects = max(df$subject_id),
  n_sessions = as.integer(n_sessions),
  subject_id = df$subject_id,
  session_id = df$session_id,
  y          = df$y
)

stan_file <- file.path(models_dir, fitted_model, paste0(fitted_model, ".stan"))
mod       <- cmdstan_model(stan_file)

fit <- mod$sample(
  data            = stan_data,
  chains          = n_chains,
  parallel_chains = n_chains,
  iter_warmup     = n_warmup,
  iter_sampling   = n_iter - n_warmup
)

fit$save_object(file.path(artifacts_dir, "stan_fit.rds"))

draws_sbj <- as_draws_df(
  fit$draws(variables = c("gamma_subject", "gamma_subjectXsession"))
)
draws_pop <- as_draws_df(
  fit$draws(
    variables = c(
      "intercept", "sigma_error", "sigma_subject",
      "sigma_session", "sigma_subjectXsession"
    )
  )
)

saveRDS(draws_sbj, file.path(artifacts_dir, "draws_sbj.rds"))
saveRDS(draws_pop, file.path(artifacts_dir, "draws_pop.rds"))
