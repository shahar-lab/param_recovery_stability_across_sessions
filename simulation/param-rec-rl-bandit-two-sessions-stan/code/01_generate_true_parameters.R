# reads: n_subjects, n_sessions, n_trials, p_reward, mu_log_beta, sigma_*, mu_alpha,
#        sigma_alpha, ICC_* from main.R
# writes: artifacts/true_population.rds, artifacts/true_parameters.rds

#### GENERATE TRUE PARAMETERS ####

true_population <- list(
  mu_log_beta           = mu_log_beta,
  sigma_subject         = sigma_subject,
  sigma_session         = sigma_session,
  sigma_subjectXsession = sigma_subjectXsession,
  mu_alpha              = mu_alpha,
  sigma_alpha           = sigma_alpha,
  n_trials              = n_trials,
  p_reward              = p_reward,
  ICC_agreement         = ICC_agreement,
  ICC_consistency       = ICC_consistency
)

gamma_subject <- rnorm(n_subjects, mean = 0, sd = sigma_subject)
gamma_session <- rnorm(n_sessions, mean = 0, sd = sigma_session)
gamma_subjectXsession <- matrix(
  rnorm(n_subjects * n_sessions, mean = 0, sd = sigma_subjectXsession),
  nrow = n_subjects,
  ncol = n_sessions
)
logit_alpha <- matrix(
  rnorm(n_subjects * n_sessions, mean = mu_alpha, sd = sigma_alpha),
  nrow = n_subjects,
  ncol = n_sessions
)

# One row per subject × session.
true_parameters <- expand.grid(
  subject_id = seq_len(n_subjects),
  session_id = seq_len(n_sessions)
) |>
  mutate(
    gamma_subject         = gamma_subject[subject_id],
    gamma_session         = gamma_session[session_id],
    gamma_subjectXsession = gamma_subjectXsession[cbind(subject_id, session_id)],
    log_beta              = mu_log_beta + gamma_subject + gamma_session + gamma_subjectXsession,
    beta                  = exp(log_beta),
    alpha                 = plogis(logit_alpha[cbind(subject_id, session_id)])
  ) |>
  arrange(subject_id, session_id)

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
