#### MODEL: linear-reg-two-sessions ####
# Generating code for the linear-reg-two-sessions model.
# Lives in models/linear-reg-two-sessions/ alongside linear-reg-two-sessions.stan
# (project-rules.md §1). Fitting and evaluation happen in analysis/ or simulation/,
# never here.
#
# One call generates one subject × one session. The caller loops over cells.
#
# Agreements with linear-reg-two-sessions.stan:
# 1. Population form — gamma_* arrive already drawn as Normal(0, sigma_*).
#    Stan reconstructs the same form as gamma_* = sigma_* * z_*, z_* ~ std_normal().
# 2. Scale — intercept, gamma_*, and sigma_error arrive on the identity / outcome
#    scale. No link transform is applied.
# 3. Likelihood — y ~ Normal(mu, sigma_error), the same density as Stan's
#    normal(mu, sigma_error).

generate_linear_reg_two_sessions <- function(n_trials, params) {
  # params is a named vector on the identity / outcome scale:
  # intercept, sigma_error, gamma_subject, gamma_session, gamma_subjectXsession

  intercept             <- params[["intercept"]]
  sigma_error           <- params[["sigma_error"]]
  gamma_subject         <- params[["gamma_subject"]]
  gamma_session         <- params[["gamma_session"]]
  gamma_subjectXsession <- params[["gamma_subjectXsession"]]

  mu <- intercept + gamma_subject + gamma_session + gamma_subjectXsession

  df <- data.frame(
    y = rnorm(n = n_trials, mean = mu, sd = sigma_error)
  )

  df
}
