#### MODEL: rl-bandit-two-sessions ####
# Generating code for the rl-bandit-two-sessions model.
# Lives in models/rl-bandit-two-sessions/ alongside rl-bandit-two-sessions.stan
# (project-rules.md §1). Fitting and evaluation happen in analysis/ or simulation/,
# never here.
#
# One call generates one subject × one session of a 2-armed bandit. The caller
# loops over cells.
#
# Agreements with rl-bandit-two-sessions.stan:
# 1. Population form — gamma_* arrive already drawn as Normal(0, sigma_*), and alpha
#    arrives already drawn as inv_logit(Normal(mu_alpha, sigma_alpha)).
#    Stan reconstructs the same forms as gamma_* = sigma_* * z_* and
#    alpha = inv_logit(mu_alpha + sigma_alpha * z_alpha), z_* ~ std_normal().
# 2. Scale — mu_log_beta and gamma_* are on the log-beta scale; beta = exp(log_beta).
#    alpha is on the probability scale (0, 1).
# 3. Likelihood — Q-values start at 0.5 each session; P(choice = 2) =
#    inv_logit(beta * (Q[2] - Q[1])), the same density as Stan's bernoulli_logit.
#    Only the chosen arm is updated: Q[c] += alpha * (reward - Q[c]).

generate_rl_bandit_two_sessions <- function(n_trials, params) {
  # params is a named vector:
  # mu_log_beta, gamma_subject, gamma_session, gamma_subjectXsession (log-beta scale),
  # alpha (probability scale), p_reward_1, p_reward_2 (reward probability per arm)

  log_beta <- params[["mu_log_beta"]] + params[["gamma_subject"]] +
    params[["gamma_session"]] + params[["gamma_subjectXsession"]]
  beta     <- exp(log_beta)
  alpha    <- params[["alpha"]]
  p_reward <- c(params[["p_reward_1"]], params[["p_reward_2"]])

  Q      <- c(0.5, 0.5)
  choice <- integer(n_trials)
  reward <- integer(n_trials)

  for (t in seq_len(n_trials)) {
    p_choose_2 <- plogis(beta * (Q[2] - Q[1]))
    choice[t]  <- rbinom(1, size = 1, prob = p_choose_2) + 1L
    reward[t]  <- rbinom(1, size = 1, prob = p_reward[choice[t]])
    Q[choice[t]] <- Q[choice[t]] + alpha * (reward[t] - Q[choice[t]])
  }

  df <- data.frame(
    trial  = seq_len(n_trials),
    choice = choice,
    reward = reward
  )

  df
}
