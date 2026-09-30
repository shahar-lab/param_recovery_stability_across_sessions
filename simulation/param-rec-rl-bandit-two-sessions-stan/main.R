rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(ggplot2)
library(ggdist)
library(patchwork)
library(irr)

# Directories
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "param-rec-rl-bandit-two-sessions-stan", "code")
artifacts_dir <- file.path(project_root, "simulation", "param-rec-rl-bandit-two-sessions-stan", "artifacts")
output_dir    <- file.path(project_root, "simulation", "param-rec-rl-bandit-two-sessions-stan", "output")
models_dir    <- file.path(project_root, "models")

# Models
generative_model <- "rl-bandit-two-sessions"
fitted_model     <- "rl-bandit-two-sessions"

set.seed(2026)


#### GENERATING TRUE PARAMETERS ####
# Draw subject × session beta and alpha from the population values below, plot them
# (dot histograms), and save true_population.rds / true_parameters.rds to artifacts/.

n_subjects            <- 200L
n_sessions            <- 2L
n_trials              <- 200L  # trials per subject per session
p_reward              <- c(0.7, 0.3)

# beta (log scale): log_beta_ij = mu_log_beta + subject_i + session_j + subjectXsession_ij
mu_log_beta           <- log(3)
sigma_subject         <- 0.5   # stable, between-subject part
sigma_session         <- 0.2   # shift shared by everyone in a session
sigma_subjectXsession <- 0.3   # session-to-session noise within a subject

# alpha (logit scale), independent per subject × session
mu_alpha              <- qlogis(0.3)
sigma_alpha           <- 0.8

# True ICC of log beta across sessions (latent scale).
ICC_agreement   <- sigma_subject^2 /
  (sigma_subject^2 + sigma_session^2 + sigma_subjectXsession^2)

ICC_consistency <- sigma_subject^2 /
  (sigma_subject^2 + sigma_subjectXsession^2)

source(file.path(code_dir, "01_generate_true_parameters.R"))
source(file.path(code_dir, "02_plot_true_parameters.R"))


#### GENERATING DATA ####

# Source models/<generative_model>/<generative_model>.R, simulate choices from the
# saved true parameters, and write simulated_data.rds to artifacts/.
source(file.path(code_dir, "03_generate_data.R"))
source(file.path(code_dir, "04_compute_icc_from_irr.R"))
cat(sprintf(
  "True ICC_agreement = %.4f | True ICC_consistency = %.4f\nirr ICC_agreement = %.4f | irr ICC_consistency = %.4f\n",
  ICC_agreement, ICC_consistency,
  icc_from_irr$ICC_agreement, icc_from_irr$ICC_consistency
))


#### RECOVERING PARAMETERS ####
# Fit models/<fitted_model>/<fitted_model>.stan. Save the fit, population and
# subject × session draws, and recovered parameters to artifacts/.

n_chains    = 4
n_iter      = 2000
n_warmup    = 1000
adapt_delta = 0.9

source(file.path(code_dir, "05_fit_model.R"))
source(file.path(code_dir, "06_extract_recovered_parameters.R"))
print(attr(recovered_parameters, "pop_summary"))
print(attr(recovered_parameters, "agent_summary"))


#### VISUALIZATION AND OUTPUT ####

source(file.path(code_dir, "07_plot_population.R"))
source(file.path(code_dir, "08_plot_icc.R"))
source(file.path(code_dir, "09_plot_individual_recovery.R"))
source(file.path(code_dir, "10_compile_recovery_pdf.R"))
