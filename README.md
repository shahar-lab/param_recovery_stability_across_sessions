# param_recovery_stability_across_sessions

Can a hierarchical Stan model recover the **test–retest ICC** of a reinforcement-learning parameter from choices alone?

## Setup
- 2-armed bandit (p = 0.7 / 0.3), 200 subjects × 2 sessions × 200 trials.
- Q-learning with softmax. β varies by subject and session, and α by subject × session:

  $$\log\beta_{ij} = \mu_j + \underbrace{\gamma_i}_{\text{stable}} + \underbrace{\gamma_{ij}}_{\text{session wobble}}$$

- Session is a **fixed effect** (one mean per session). With only 2 sessions, a random session SD can't be estimated well.

## ICC
Computed in every posterior draw:

$$\text{ICC}_{\text{cons}} = \frac{\sigma^2_{\text{subj}}}{\sigma^2_{\text{subj}} + \sigma^2_{\text{subj}\times\text{sess}}}
\qquad
\text{ICC}_{\text{agree}} = \frac{\sigma^2_{\text{subj}}}{\sigma^2_{\text{subj}} + v_{\text{sess}} + \sigma^2_{\text{subj}\times\text{sess}}}$$

$v_{\text{sess}}$ is the variance of the two session means. Agreement also counts a shift shared by everyone between sessions as disagreement. Consistency ignores it.

## Results

| | True | `irr` on true β | Stan [90% CI] |
|---|---|---|---|
| ICC agreement | 0.658 | 0.644 | **0.648** [0.57, 0.72] |
| ICC consistency | 0.735 | 0.691 | **0.695** [0.61, 0.76] |

Both ICCs are recovered, with R̂ ≤ 1.01 and 0 divergences. Individual log β is recovered at r ≈ 0.95.

![ICC: random vs fixed session](simulation/param-rec-rl-bandit-fixed-session-stan/output/11_icc_model_comparison.png)

A fixed session effect gives a much tighter agreement ICC than a random one. Consistency is the same in both.

![Individual recovery](simulation/param-rec-rl-bandit-fixed-session-stan/output/09_individual_recovery.png)

## Run
```r
source("simulation/param-rec-rl-bandit-fixed-session-stan/main.R")  # ~30 min
```
Settings are at the top of `main.R`. Artifacts are not committed.
