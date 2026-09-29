// MODEL: linear-reg-two-sessions
// Stan fitting code. Lives in models/linear-reg-two-sessions/ (project-rules.md §1).
//
// Agreements with linear-reg-two-sessions.R:
// 1. Population form — gamma_* = sigma_* * z_* with z_* ~ std_normal() is the
//    non-centred version of Normal(0, sigma_*), the distribution the generating
//    function expects its gamma_* arguments to have been drawn from.
// 2. Scale — intercept, gamma_*, and sigma_error are on the identity / outcome
//    scale. No link transform is applied.
// 3. Likelihood — y ~ normal(mu, sigma_error), the same density as the
//    generating rnorm(n_trials, mean = mu, sd = sigma_error).

data {
  int<lower=1> N;
  int<lower=1> n_subjects;
  int<lower=2, upper=2> n_sessions;
  array[N] int<lower=1, upper=n_subjects> subject_id;
  array[N] int<lower=1, upper=n_sessions> session_id;
  vector[N] y;
}

parameters {
  real intercept;
  real<lower=0> sigma_error;
  real<lower=0> sigma_subject;
  real<lower=0> sigma_session;
  real<lower=0> sigma_subjectXsession;
  vector[n_subjects] z_subject;
  vector[n_sessions] z_session;
  matrix[n_subjects, n_sessions] z_subjectXsession;
}

transformed parameters {
  vector[n_subjects] gamma_subject = sigma_subject * z_subject;
  vector[n_sessions] gamma_session = sigma_session * z_session;
  matrix[n_subjects, n_sessions] gamma_subjectXsession =
    sigma_subjectXsession * z_subjectXsession;
  vector[N] mu;

  for (n in 1:N) {
    mu[n] = intercept
          + gamma_subject[subject_id[n]]
          + gamma_session[session_id[n]]
          + gamma_subjectXsession[subject_id[n], session_id[n]];
  }
}

model {
  intercept             ~ normal(0, 10);
  sigma_error           ~ normal(0, 10);
  sigma_subject         ~ normal(0, 10);
  sigma_session         ~ normal(0, 10);
  sigma_subjectXsession ~ normal(0, 10);
  z_subject             ~ std_normal();
  z_session             ~ std_normal();
  to_vector(z_subjectXsession) ~ std_normal();

  y ~ normal(mu, sigma_error);
}

generated quantities {
  vector[N] log_lik;

  for (n in 1:N) {
    log_lik[n] = normal_lpdf(y[n] | mu[n], sigma_error);
  }
}
