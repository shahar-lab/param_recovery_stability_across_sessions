# reads: artifacts/simulated_data.rds
# writes: artifacts/stan_fit.rds, artifacts/draws_sbj.rds, artifacts/draws_pop.rds

#### FIT MODEL ####

df <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))

n_subj_data  <- max(df$subject_id)
n_trial_data <- max(df$trial)
dims         <- c(n_subj_data, n_sessions, n_trial_data)
idx          <- cbind(df$subject_id, df$session_id, df$trial)

choice_arr <- array(NA_integer_, dim = dims)
reward_arr <- array(NA_integer_, dim = dims)
choice_arr[idx] <- df$choice
reward_arr[idx] <- df$reward
stopifnot(!anyNA(choice_arr), !anyNA(reward_arr))

stan_data <- list(
  n_subjects = n_subj_data,
  n_sessions = as.integer(n_sessions),
  n_trials   = n_trial_data,
  choice     = choice_arr,
  reward     = reward_arr
)

stan_file <- file.path(models_dir, fitted_model, paste0(fitted_model, ".stan"))
mod       <- cmdstan_model(stan_file)

fit <- mod$sample(
  data            = stan_data,
  chains          = n_chains,
  parallel_chains = n_chains,
  iter_warmup     = n_warmup,
  iter_sampling   = n_iter - n_warmup,
  adapt_delta     = adapt_delta,
  seed            = 2026
)

fit$save_object(file.path(artifacts_dir, "stan_fit.rds"))

draws_sbj <- as_draws_df(
  fit$draws(variables = c("log_beta", "beta", "alpha"))
)
draws_pop <- as_draws_df(
  fit$draws(
    variables = c(
      "mu_log_beta", "sigma_subject", "sigma_subjectXsession", "var_session",
      "mu_alpha", "sigma_alpha", "ICC_agreement", "ICC_consistency"
    )
  )
)

saveRDS(draws_sbj, file.path(artifacts_dir, "draws_sbj.rds"))
saveRDS(draws_pop, file.path(artifacts_dir, "draws_pop.rds"))
