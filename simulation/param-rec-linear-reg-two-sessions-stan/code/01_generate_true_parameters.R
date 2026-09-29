# reads: n_subjects, n_sessions, n_trials, intercept, sigma_*, ICC_* from main.R
# writes: artifacts/true_population.rds, artifacts/true_parameters.rds

#### GENERATE TRUE PARAMETERS ####

true_population <- list(
  intercept             = intercept,
  sigma_error           = sigma_error,
  sigma_subject         = sigma_subject,
  sigma_session         = sigma_session,
  sigma_subjectXsession = sigma_subjectXsession,
  n_trials              = n_trials,
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

true_parameters <- data.frame(
  subject_id              = seq_len(n_subjects),
  gamma_subject           = gamma_subject,
  gamma_subjectXsession_1 = gamma_subjectXsession[, 1],
  gamma_subjectXsession_2 = gamma_subjectXsession[, 2]
)

attr(true_parameters, "gamma_session") <- gamma_session
attr(true_parameters, "gamma_subjectXsession") <- gamma_subjectXsession

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
