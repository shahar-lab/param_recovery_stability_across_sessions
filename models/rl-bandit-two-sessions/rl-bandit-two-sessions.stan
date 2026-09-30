// MODEL: rl-bandit-two-sessions
// Stan fitting code. Lives in models/rl-bandit-two-sessions/ (project-rules.md §1).
//
// Agreements with rl-bandit-two-sessions.R:
// 1. Population form — gamma_* = sigma_* * z_* with z_* ~ std_normal() is the
//    non-centred version of Normal(0, sigma_*); alpha = inv_logit(mu_alpha +
//    sigma_alpha * z_alpha) is the non-centred version of the generating
//    inv_logit(Normal(mu_alpha, sigma_alpha)).
// 2. Scale — mu_log_beta and gamma_* are on the log-beta scale; beta = exp(log_beta).
//    alpha is on the probability scale (0, 1).
// 3. Likelihood — Q-values start at 0.5 each session; choice - 1 ~
//    bernoulli_logit(beta * (Q[2] - Q[1])), the same density as the generating
//    rbinom(1, 1, plogis(beta * (Q[2] - Q[1]))). Only the chosen arm is updated.

data {
  int<lower=1> n_subjects;
  int<lower=2, upper=2> n_sessions;
  int<lower=1> n_trials;
  array[n_subjects, n_sessions, n_trials] int<lower=1, upper=2> choice;
  array[n_subjects, n_sessions, n_trials] int<lower=0, upper=1> reward;
}

parameters {
  real mu_log_beta;
  real<lower=0> sigma_subject;
  real<lower=0> sigma_session;
  real<lower=0> sigma_subjectXsession;
  vector[n_subjects] z_subject;
  vector[n_sessions] z_session;
  matrix[n_subjects, n_sessions] z_subjectXsession;

  real mu_alpha;
  real<lower=0> sigma_alpha;
  matrix[n_subjects, n_sessions] z_alpha;
}

transformed parameters {
  vector[n_subjects] gamma_subject = sigma_subject * z_subject;
  vector[n_sessions] gamma_session = sigma_session * z_session;
  matrix[n_subjects, n_sessions] gamma_subjectXsession =
    sigma_subjectXsession * z_subjectXsession;
  matrix[n_subjects, n_sessions] log_beta;
  matrix[n_subjects, n_sessions] beta;
  matrix[n_subjects, n_sessions] alpha = inv_logit(mu_alpha + sigma_alpha * z_alpha);

  for (i in 1:n_subjects) {
    for (j in 1:n_sessions) {
      log_beta[i, j] = mu_log_beta + gamma_subject[i] + gamma_session[j]
                     + gamma_subjectXsession[i, j];
    }
  }
  beta = exp(log_beta);
}

model {
  mu_log_beta           ~ normal(1, 1);
  sigma_subject         ~ normal(0, 1);
  sigma_session         ~ normal(0, 0.5);
  sigma_subjectXsession ~ normal(0, 1);
  z_subject             ~ std_normal();
  z_session             ~ std_normal();
  to_vector(z_subjectXsession) ~ std_normal();

  mu_alpha              ~ normal(0, 1.5);
  sigma_alpha           ~ normal(0, 1);
  to_vector(z_alpha)    ~ std_normal();

  for (i in 1:n_subjects) {
    for (j in 1:n_sessions) {
      vector[2] Q = rep_vector(0.5, 2);
      vector[n_trials] q_diff;
      array[n_trials] int chose_2;

      for (t in 1:n_trials) {
        int c = choice[i, j, t];
        q_diff[t]  = Q[2] - Q[1];
        chose_2[t] = c - 1;
        Q[c] += alpha[i, j] * (reward[i, j, t] - Q[c]);
      }
      chose_2 ~ bernoulli_logit(beta[i, j] * q_diff);
    }
  }
}

generated quantities {
  // ICC of log_beta across sessions (latent scale, no trial-error term).
  real ICC_agreement = square(sigma_subject) /
    (square(sigma_subject) + square(sigma_session) + square(sigma_subjectXsession));
  real ICC_consistency = square(sigma_subject) /
    (square(sigma_subject) + square(sigma_subjectXsession));
}
