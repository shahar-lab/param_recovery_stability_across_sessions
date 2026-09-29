# reads: artifacts/stan_fit.rds, artifacts/true_population.rds,
#        artifacts/true_parameters.rds, artifacts/draws_sbj.rds, artifacts/draws_pop.rds,
#        artifacts/simulated_data.rds
# writes: artifacts/recovered_parameters.rds, artifacts/draws_pop.rds,
#         artifacts/true_population.rds

#### EXTRACT RECOVERED PARAMETERS ####

rhat_max_criterion       <- 1.01
correlation_min          <- 0.90
abs_bias_max             <- 0.05
recovered_range_min_frac <- 0.70

fit             <- readRDS(file.path(artifacts_dir, "stan_fit.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
draws_sbj       <- readRDS(file.path(artifacts_dir, "draws_sbj.rds"))
draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))

df_sim <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))
n_trials_icc <- as.integer(
  nrow(df_sim) /
    (length(unique(df_sim$subject_id)) * length(unique(df_sim$session_id)))
)

residual_mean <- true_population$sigma_subjectXsession^2 +
  true_population$sigma_error^2 / n_trials_icc
true_population$n_trials        <- n_trials_icc
true_population$ICC_agreement   <- true_population$sigma_subject^2 /
  (true_population$sigma_subject^2 + true_population$sigma_session^2 + residual_mean)
true_population$ICC_consistency <- true_population$sigma_subject^2 /
  (true_population$sigma_subject^2 + residual_mean)
saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))

residual_mean_draws <- draws_pop$sigma_subjectXsession^2 +
  draws_pop$sigma_error^2 / n_trials_icc
draws_pop$ICC_agreement <- draws_pop$sigma_subject^2 /
  (draws_pop$sigma_subject^2 + draws_pop$sigma_session^2 + residual_mean_draws)
draws_pop$ICC_consistency <- draws_pop$sigma_subject^2 /
  (draws_pop$sigma_subject^2 + residual_mean_draws)
saveRDS(draws_pop, file.path(artifacts_dir, "draws_pop.rds"))

sum_tbl     <- fit$summary(
  variables = c(
    "intercept", "sigma_error", "sigma_subject", "sigma_session",
    "sigma_subjectXsession", "gamma_subject", "gamma_session",
    "gamma_subjectXsession"
  )
)
n_divergent <- sum(fit$diagnostic_summary()$num_divergent)

mean_and_sd <- function(draws, col_name) {
  c(mean = mean(draws[[col_name]]), sd = sd(draws[[col_name]]))
}

n_subj <- nrow(true_parameters)
rec_subject    <- numeric(n_subj)
rec_subject_sd <- numeric(n_subj)
for (i in seq_len(n_subj)) {
  stats <- mean_and_sd(draws_sbj, paste0("gamma_subject[", i, "]"))
  rec_subject[i]    <- stats[["mean"]]
  rec_subject_sd[i] <- stats[["sd"]]
}

rec_inter    <- matrix(NA_real_, n_subj, n_sessions)
rec_inter_sd <- matrix(NA_real_, n_subj, n_sessions)
for (i in seq_len(n_subj)) {
  for (j in seq_len(n_sessions)) {
    stats <- mean_and_sd(draws_sbj, paste0("gamma_subjectXsession[", i, ",", j, "]"))
    rec_inter[i, j]    <- stats[["mean"]]
    rec_inter_sd[i, j] <- stats[["sd"]]
  }
}

df_subject <- data.frame(
  subject_id    = true_parameters$subject_id,
  parameter     = "gamma_subject",
  true          = true_parameters$gamma_subject,
  recovered     = rec_subject,
  posterior_sd  = rec_subject_sd
)
df_inter <- data.frame(
  subject_id    = rep(true_parameters$subject_id, times = n_sessions),
  parameter     = "gamma_subjectXsession",
  true          = c(true_parameters$gamma_subjectXsession_1, true_parameters$gamma_subjectXsession_2),
  recovered     = as.vector(rec_inter),
  posterior_sd  = as.vector(rec_inter_sd)
)

recovered_parameters <- bind_rows(df_subject, df_inter)

pop_names <- c(
  "intercept", "sigma_error", "sigma_subject", "sigma_session",
  "sigma_subjectXsession", "ICC_agreement", "ICC_consistency"
)
missing_pop <- setdiff(pop_names, names(true_population))
if (length(missing_pop) > 0) {
  stop("true_population is missing: ", paste(missing_pop, collapse = ", "))
}
pop_true <- vapply(pop_names, function(nm) as.numeric(true_population[[nm]]), numeric(1))
pop_summary <- data.frame(
  parameter        = pop_names,
  true_val         = unname(pop_true),
  posterior_median = NA_real_,
  q05              = NA_real_,
  q95              = NA_real_,
  contains_true    = NA
)
for (k in seq_along(pop_names)) {
  d <- draws_pop[[pop_names[k]]]
  pop_summary$posterior_median[k] <- median(d)
  pop_summary$q05[k]              <- as.numeric(quantile(d, 0.05))
  pop_summary$q95[k]              <- as.numeric(quantile(d, 0.95))
  pop_summary$contains_true[k]    <- pop_true[k] >= pop_summary$q05[k] &
    pop_true[k] <= pop_summary$q95[k]
}

summarise_agent <- function(df_one) {
  pearson_r  <- cor(df_one$true, df_one$recovered)
  mean_bias  <- mean(df_one$recovered - df_one$true)
  slope      <- coef(lm(recovered ~ true, data = df_one))[["true"]]
  range_frac <- diff(range(df_one$recovered)) / diff(range(df_one$true))
  data.frame(
    parameter           = df_one$parameter[1],
    pearson_r           = pearson_r,
    mean_bias           = mean_bias,
    slope               = slope,
    range_frac          = range_frac,
    median_posterior_sd = median(df_one$posterior_sd),
    pass_r              = pearson_r >= correlation_min,
    pass_bias           = abs(mean_bias) < abs_bias_max,
    pass_prec           = range_frac >= recovered_range_min_frac
  )
}

agent_summary <- bind_rows(
  summarise_agent(df_subject),
  summarise_agent(df_inter)
)

attr(recovered_parameters, "rhat_max")      <- max(sum_tbl$rhat, na.rm = TRUE)
attr(recovered_parameters, "rhat_ok")       <- max(sum_tbl$rhat, na.rm = TRUE) <= rhat_max_criterion
attr(recovered_parameters, "n_divergent")   <- n_divergent
attr(recovered_parameters, "pop_summary")   <- pop_summary
attr(recovered_parameters, "agent_summary") <- agent_summary

saveRDS(recovered_parameters, file.path(artifacts_dir, "recovered_parameters.rds"))
