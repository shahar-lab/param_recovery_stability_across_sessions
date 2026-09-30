# reads: artifacts/stan_fit.rds, artifacts/true_population.rds,
#        artifacts/true_parameters.rds, artifacts/draws_pop.rds
# writes: artifacts/recovered_parameters.rds

#### EXTRACT RECOVERED PARAMETERS ####

rhat_max_criterion       <- 1.01
correlation_min          <- 0.80
abs_bias_max             <- 0.05
recovered_range_min_frac <- 0.70

fit             <- readRDS(file.path(artifacts_dir, "stan_fit.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))

sum_tbl     <- fit$summary(
  variables = c(
    "mu_log_beta", "sigma_subject", "sigma_session", "sigma_subjectXsession",
    "mu_alpha", "sigma_alpha", "log_beta", "alpha"
  )
)
n_divergent <- sum(fit$diagnostic_summary()$num_divergent)

# Posterior mean and SD of each subject × session log_beta and alpha.
recovered_parameters <- sum_tbl |>
  filter(str_detect(variable, "^(log_beta|alpha)\\[")) |>
  mutate(
    parameter  = str_extract(variable, "^[a-z_]+"),
    subject_id = as.integer(str_match(variable, "\\[(\\d+),")[, 2]),
    session_id = as.integer(str_match(variable, ",(\\d+)\\]")[, 2])
  ) |>
  select(parameter, subject_id, session_id, recovered = mean, posterior_sd = sd) |>
  left_join(
    true_parameters |>
      select(subject_id, session_id, log_beta, alpha) |>
      pivot_longer(c(log_beta, alpha), names_to = "parameter", values_to = "true"),
    by = c("parameter", "subject_id", "session_id")
  ) |>
  as.data.frame()

pop_names <- c(
  "mu_log_beta", "sigma_subject", "sigma_session", "sigma_subjectXsession",
  "mu_alpha", "sigma_alpha", "ICC_agreement", "ICC_consistency"
)
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
    session_id          = df_one$session_id[1],
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

agent_summary <- recovered_parameters |>
  group_split(parameter, session_id) |>
  map(summarise_agent) |>
  bind_rows()

attr(recovered_parameters, "rhat_max")      <- max(sum_tbl$rhat, na.rm = TRUE)
attr(recovered_parameters, "rhat_ok")       <- max(sum_tbl$rhat, na.rm = TRUE) <= rhat_max_criterion
attr(recovered_parameters, "n_divergent")   <- n_divergent
attr(recovered_parameters, "pop_summary")   <- pop_summary
attr(recovered_parameters, "agent_summary") <- agent_summary

cat(sprintf(
  "\nMax Rhat = %.4f (ok: %s) | Divergent transitions = %d\n",
  attr(recovered_parameters, "rhat_max"),
  attr(recovered_parameters, "rhat_ok"),
  n_divergent
))

saveRDS(recovered_parameters, file.path(artifacts_dir, "recovered_parameters.rds"))
