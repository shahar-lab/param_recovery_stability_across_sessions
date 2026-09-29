# linear-reg-two-sessions

Two-session linear regression with a crossed subject random intercept, a session random intercept, and a subject × session interaction.

## Observation model

Subject \(i\), session \(j\), trial \(k\) within that subject–session cell:

\[
y_{ijk} \sim \mathrm{Normal}(\mu_{ij},\,\sigma_{\mathrm{error}})
\]

\[
\mu_{ij} = \texttt{intercept} + \gamma_i + \gamma_j + \gamma_{ij}
\]

Generation is one subject × one session: a single call of `generate_linear_reg_two_sessions(n_trials, params)` draws \(k = 1, \ldots, n_{\mathrm{trials}}\) from that cell's \(\mathrm{Normal}(\mu,\,\sigma_{\mathrm{error}})\). The caller loops over subjects and sessions. This definition uses two sessions.

## Parameters

| Symbol | Code name | Role | Scale |
|---|---|---|---|
| intercept | `intercept` | Grand mean | Same as \(y\) |
| \(\gamma_i\) | `gamma_subject` | Subject random intercept; \(\mathrm{Normal}(0,\,\sigma_{\mathrm{subject}})\) | Same as \(y\) |
| \(\gamma_j\) | `gamma_session` | Session random intercept; \(\mathrm{Normal}(0,\,\sigma_{\mathrm{session}})\) | Same as \(y\) |
| \(\gamma_{ij}\) | `gamma_subjectXsession` | Subject × session interaction; \(\mathrm{Normal}(0,\,\sigma_{\mathrm{subjectXsession}})\) | Same as \(y\) |
| \(\sigma_{\mathrm{error}}\) | `sigma_error` | Residual SD | Positive, same as \(y\) |
| \(\sigma_{\mathrm{subject}}\) | `sigma_subject` | SD of `gamma_subject` | Positive |
| \(\sigma_{\mathrm{session}}\) | `sigma_session` | SD of `gamma_session` | Positive |
| \(\sigma_{\mathrm{subjectXsession}}\) | `sigma_subjectXsession` | SD of `gamma_subjectXsession` | Positive |

Fitting uses the non-centred form \(\gamma = \sigma \cdot z\) with \(z \sim \mathrm{Normal}(0,1)\).

## Generating `params` vector

A named numeric vector with:

- `intercept`
- `sigma_error`
- `gamma_subject`
- `gamma_session`
- `gamma_subjectXsession`

## Priors (Stan)

- `intercept ~ normal(0, 10)`
- `sigma_error`, `sigma_subject`, `sigma_session`, `sigma_subjectXsession ~ half-normal(0, 10)` (declared `lower=0` with a `normal(0, 10)` prior)
- `z_subject`, `z_session`, `z_subjectXsession ~ std_normal()`
