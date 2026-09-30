# rl-bandit-two-sessions

Two-session Q-learning model for a 2-armed bandit. The inverse temperature \(\beta\) has a crossed subject random effect, a session random effect, and a subject × session interaction on the log scale. The learning rate \(\alpha\) is drawn independently for each subject × session.

## Observation model

Subject \(i\), session \(j\), trial \(t\). Q-values start at 0.5 for both arms at the start of every session:

\[
P(c_{ijt} = 2) = \mathrm{logit}^{-1}\!\big(\beta_{ij}\,(Q_{ijt,2} - Q_{ijt,1})\big)
\]

\[
Q_{ij(t+1),c} = Q_{ijt,c} + \alpha_{ij}\,(r_{ijt} - Q_{ijt,c}) \quad \text{(chosen arm only)}
\]

\[
\log \beta_{ij} = \mu_{\log\beta} + \gamma_i + \gamma_j + \gamma_{ij},
\qquad
\alpha_{ij} = \mathrm{logit}^{-1}(\mu_\alpha + \sigma_\alpha z_{ij})
\]

Rewards are Bernoulli with a fixed probability per arm (`p_reward_1`, `p_reward_2`). Generation is one subject × one session: a single call of `generate_rl_bandit_two_sessions(n_trials, params)` simulates \(t = 1, \ldots, n_{\mathrm{trials}}\). The caller loops over subjects and sessions.

## Noise and ICC

There is no separate additive noise on \(\beta\). The subject × session term \(\gamma_{ij}\) is the session-to-session noise in the true \(\beta\). Choice randomness over a finite number of trials adds estimation noise, which is not part of the true ICC.

ICC of \(\log\beta\) across sessions (latent scale):

\[
\mathrm{ICC}_{\mathrm{agreement}} = \frac{\sigma^2_{\mathrm{subject}}}{\sigma^2_{\mathrm{subject}} + \sigma^2_{\mathrm{session}} + \sigma^2_{\mathrm{subjectXsession}}},
\qquad
\mathrm{ICC}_{\mathrm{consistency}} = \frac{\sigma^2_{\mathrm{subject}}}{\sigma^2_{\mathrm{subject}} + \sigma^2_{\mathrm{subjectXsession}}}
\]

With only two sessions, \(\sigma_{\mathrm{session}}\) is weakly identified, so ICC agreement is less precise than ICC consistency.

## Parameters

| Symbol | Code name | Role | Scale |
|---|---|---|---|
| \(\mu_{\log\beta}\) | `mu_log_beta` | Grand mean of log beta | Log beta |
| \(\gamma_i\) | `gamma_subject` | Subject effect; \(\mathrm{Normal}(0,\,\sigma_{\mathrm{subject}})\) | Log beta |
| \(\gamma_j\) | `gamma_session` | Session effect; \(\mathrm{Normal}(0,\,\sigma_{\mathrm{session}})\) | Log beta |
| \(\gamma_{ij}\) | `gamma_subjectXsession` | Subject × session effect; \(\mathrm{Normal}(0,\,\sigma_{\mathrm{subjectXsession}})\) | Log beta |
| \(\mu_\alpha\) | `mu_alpha` | Mean of logit alpha | Logit |
| \(\sigma_\alpha\) | `sigma_alpha` | SD of logit alpha | Positive |
| \(\alpha_{ij}\) | `alpha` | Learning rate per subject × session | (0, 1) |

Fitting uses the non-centred form \(\gamma = \sigma \cdot z\) with \(z \sim \mathrm{Normal}(0,1)\).

## Generating `params` vector

A named numeric vector with:

- `mu_log_beta`
- `gamma_subject`
- `gamma_session`
- `gamma_subjectXsession`
- `alpha`
- `p_reward_1`, `p_reward_2`

## Priors (Stan)

- `mu_log_beta ~ normal(1, 1)`
- `sigma_subject`, `sigma_subjectXsession ~ half-normal(0, 1)`
- `sigma_session ~ half-normal(0, 0.5)` (tighter: only two sessions)
- `mu_alpha ~ normal(0, 1.5)`, `sigma_alpha ~ half-normal(0, 1)`
- `z_subject`, `z_session`, `z_subjectXsession`, `z_alpha ~ std_normal()`
