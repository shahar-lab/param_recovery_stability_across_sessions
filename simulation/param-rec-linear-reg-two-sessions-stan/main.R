rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(brms)
library(posterior)
library(tidybayes)
library(ggplot2)
library(ggdist)
library(patchwork)
library(grid)
library(irr)

# Directories
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "param-rec-linear-reg-two-sessions-stan", "code")
artifacts_dir <- file.path(project_root, "simulation", "param-rec-linear-reg-two-sessions-stan", "artifacts")
output_dir    <- file.path(project_root, "simulation", "param-rec-linear-reg-two-sessions-stan", "output")
models_dir    <- file.path(project_root, "models")

# Models
generative_model <- "linear-reg-two-sessions"
fitted_model     <- "linear-reg-two-sessions"


#### GENERATING TRUE PARAMETERS ####
# Draw agent-level parameters from the population values above, plot them
# (dot histograms), and save true_population.rds / true_parameters.rds to artifacts/.

n_subjects            <- 500L
n_sessions            <- 2L
n_trials              <- 1L    # observations per agent per session
intercept             <- 0
sigma_error           <- 0.5
sigma_subject         <- 1
sigma_session         <- 0.5
sigma_subjectXsession <- 0.5

# Two-way single-measure ICC on subject-session means (McGraw & Wong;
# residual is interaction plus trial error averaged over n_trials).
ICC_agreement   <- sigma_subject^2 /
  (sigma_subject^2 + sigma_session^2 + sigma_subjectXsession^2 +
     sigma_error^2 / n_trials)

ICC_consistency <- sigma_subject^2 /
  (sigma_subject^2 + sigma_subjectXsession^2 + sigma_error^2 / n_trials)

source(file.path(code_dir, "01_generate_true_parameters.R"))
source(file.path(code_dir, "02_plot_true_parameters.R"))


#### GENERATING DATA ####

# Source models/<generative_model>/<generative_model>.R, simulate from the saved
# true parameters, and write simulated_data.rds to artifacts/. Nothing is read
# from data/. n_subjects, n_trials, and n_sessions are the quantities set above.
source(file.path(code_dir, "03_generate_data.R"))
source(file.path(code_dir, "04_compute_icc_from_irr.R"))
cat(sprintf(
  "True ICC_agreement = %.4f | True ICC_consistency = %.4f\nirr ICC_agreement = %.4f | irr ICC_consistency = %.4f\n",
  ICC_agreement, ICC_consistency,
  icc_from_irr$ICC_agreement, icc_from_irr$ICC_consistency
))


#### RECOVERING PARAMETERS ####
# Fit the researcher's chosen estimator (models/<fitted_model>/<fitted_model>.stan,
# brms, or other). Save the fit, population and agent draws, and recovered
# parameters to artifacts/.

n_chains   = 4
n_iter     = 5000
n_warmup   = 3000

source(file.path(code_dir, "05_fit_model.R"))
source(file.path(code_dir, "06_extract_recovered_parameters.R"))


#### VISUALIZATION AND OUTPUT ####

# Custom ggplot2 / tidybayes / ggdist from the saved draws — not bayesplot recovery
# wrappers. Figures, then one multi-page figures PDF and one narrative PDF report.
source(file.path(code_dir, "07_plot_population_location.R"))
source(file.path(code_dir, "08_plot_population_scale.R"))
source(file.path(code_dir, "09_plot_icc.R"))
source(file.path(code_dir, "10_plot_individual_recovery.R"))
source(file.path(code_dir, "11_compile_recovery_pdf.R"))
source(file.path(code_dir, "12_write_recovery_pdf.R"))
