# Recovery Notebook: linear-reg-two-sessions (brms)

**Generative model:** `models/linear-reg-two-sessions/`
**Fitted model:** brms formula: `y ~ 1 + (1 | subject_id) + (1 | session_id) + (1 | subject_id:session_id)`
**Job-folder:** `simulation/param-rec-linear-reg-two-sessions-brms/`
**Date Created:** 2026-09-29

## 1. Design (set in `main.R`)

* **n_subjects:** 100
* **n_trials:** 100
* **n_sessions:** 2
* **Population location (`mu_*`):** intercept = 0
* **Population scale (`sigma_*`):** sigma_error = 0.5; sigma_subject = 1; sigma_session = 0.25; sigma_subjectXsession = 0.5
* **Derived true values (not used in generation):** two-way single-measure ICC on subject-session means:
  ICC_agreement = sigma_subject^2 / (sigma_subject^2 + sigma_session^2 + sigma_subjectXsession^2 + sigma_error^2 / n_trials);
  ICC_consistency = sigma_subject^2 / (sigma_subject^2 + sigma_subjectXsession^2 + sigma_error^2 / n_trials)
* **Unit-interval transforms:** none
* **Sampler:** brms / cmdstanr; 4 chains, 2000 iterations, 1000 warmup
* **Family:** gaussian()
* **Priors:** Intercept ~ normal(0, 10); residual sigma and all random-effect SDs ~ normal(0, 10)
* **irr::icc (after data generation):** twoway, unit = "single"; type = "agreement" and type = "consistency", from subject-session means of y
* **Recovery criteria:** rhat ≤ 1.01; Pearson r ≥ 0.90; |bias| < 0.05; recovered range ≥ 70% of true

## 2. Generating true parameters

* Agent-level values were drawn as gamma_subject ~ Normal(0, sigma_subject), gamma_session ~ Normal(0, sigma_session), and gamma_subjectXsession ~ Normal(0, sigma_subjectXsession).
* ICC_agreement and ICC_consistency are stored in `true_population.rds` but are not passed to the generating function. They are the two-way single-measure ICCs implied by the population variances on subject-session means.
* Artifacts: `true_population.rds`, `true_parameters.rds`
* Dot-histogram figures of gamma_subject, gamma_session, and gamma_subjectXsession (panels A–C), with Normal(0, matching sigma) overlay and x-axis at ±3 SD of the generating distribution.

## 3. Generating data

* Generating definition loaded from `models/linear-reg-two-sessions/`
* After data are generated, y is averaged per subject per session, pivoted to wide format, and `irr::icc` is computed (twoway, single unit) for type = "agreement" and type = "consistency". Values are printed to the console and saved as `icc_from_irr.rds`.
* Artifacts: `simulated_data.rds`, `icc_from_irr.rds`

## 4. Recovering parameters

* Fitting definition: brms formula `y ~ 1 + (1 | subject_id) + (1 | session_id) + (1 | subject_id:session_id)`
* Artifacts: `brms_fit.rds`, `draws_pop.rds`, `draws_sbj.rds`, `recovered_parameters.rds`
* Diagnostics: `output/06_diagnostic.pdf` (ess/rhat table, trankplot, pairs plot of population parameters)

## 5. Findings / Summary

* (Leave this section blank until the model is fitted and the Word/PDF report has been inspected.)
* Required deliverables in `output/`: the narrative recovery report PDF and the standalone multi-page vector PDF (figures, one per page).

## 6. Manuscript excerpt — example 1

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph describing the recovery *design*: sample size, generative population distributions, and any logistic transform onto the unit interval.]

## 7. Manuscript excerpt — example 2

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph reporting the recovery *result*: population-parameter coverage and agent-level Pearson *r* / bias / precision, in manuscript prose.]
