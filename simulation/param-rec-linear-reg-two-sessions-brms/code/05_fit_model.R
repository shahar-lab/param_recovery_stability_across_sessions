# reads: artifacts/simulated_data.rds
# writes: artifacts/brms_fit.rds, artifacts/draws_sbj.rds, artifacts/draws_pop.rds

#### FIT MODEL ####

df <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))
df$subject_id <- factor(df$subject_id, levels = seq_len(n_subjects))
df$session_id <- factor(df$session_id, levels = seq_len(n_sessions))

my_priors <- c(
  prior(normal(0, 10), class = "Intercept"),
  prior(normal(0, 10), class = "sigma"),
  prior(normal(0, 10), class = "sd")
)

brms_fit <- brm(
  formula = y ~ 1 + (1 | subject_id) + (1 | session_id) + (1 | subject_id:session_id),
  data    = df,
  family  = gaussian(),
  prior   = my_priors,
  chains  = n_chains,
  iter    = n_iter,
  warmup  = n_warmup,
  backend = "cmdstanr",
  cores   = n_chains
)

saveRDS(brms_fit, file.path(artifacts_dir, "brms_fit.rds"))

draws_all <- as_draws_df(brms_fit)
sd_vars   <- names(draws_all)[startsWith(names(draws_all), "sd_")]
sd_subject <- sd_vars[grepl("subject_id", sd_vars) & !grepl("session", sd_vars)]
sd_session <- sd_vars[grepl("session_id", sd_vars) & !grepl("subject", sd_vars)]
sd_inter   <- setdiff(sd_vars, c(sd_subject, sd_session))
if (length(sd_subject) != 1L || length(sd_session) != 1L || length(sd_inter) != 1L) {
  stop("Could not map brms sd_ names: ", paste(sd_vars, collapse = ", "))
}
if (!all(c("b_Intercept", "sigma") %in% names(draws_all))) {
  stop("brms draws missing b_Intercept or sigma")
}

draws_pop <- draws_all[, c(".chain", ".iteration", ".draw")]
draws_pop$intercept             <- draws_all$b_Intercept
draws_pop$sigma_error           <- draws_all$sigma
draws_pop$sigma_subject         <- draws_all[[sd_subject]]
draws_pop$sigma_session         <- draws_all[[sd_session]]
draws_pop$sigma_subjectXsession <- draws_all[[sd_inter]]

r_all   <- names(draws_all)[startsWith(names(draws_all), "r_")]
r_subj  <- grep("^r_subject_id\\[[^,]+,\\s*Intercept\\]$", r_all, value = TRUE)
r_sess  <- grep("^r_session_id\\[[^,]+,\\s*Intercept\\]$", r_all, value = TRUE)
r_inter <- setdiff(r_all, c(r_subj, r_sess))
if (length(r_subj) != n_subjects) {
  stop("Expected ", n_subjects, " subject RE columns, found ", length(r_subj))
}
if (length(r_inter) != n_subjects * n_sessions) {
  stop("Expected ", n_subjects * n_sessions, " interaction RE columns, found ", length(r_inter))
}

draws_sbj <- draws_all[, c(".chain", ".iteration", ".draw")]
for (col in r_subj) {
  i <- as.integer(sub("^r_subject_id\\[([^,]+),\\s*Intercept\\]$", "\\1", col))
  if (is.na(i)) {
    stop("Could not parse subject RE column: ", col)
  }
  draws_sbj[[paste0("gamma_subject[", i, "]")]] <- draws_all[[col]]
}
for (col in r_inter) {
  level <- sub("^.*\\[([^,]+),\\s*Intercept\\]$", "\\1", col)
  parts <- strsplit(level, "[_:]", perl = TRUE)[[1]]
  i <- as.integer(parts[[1]])
  j <- as.integer(parts[[2]])
  if (is.na(i) || is.na(j) || length(parts) != 2L) {
    stop("Could not parse interaction RE column: ", col)
  }
  draws_sbj[[paste0("gamma_subjectXsession[", i, ",", j, "]")]] <- draws_all[[col]]
}

saveRDS(draws_sbj, file.path(artifacts_dir, "draws_sbj.rds"))
saveRDS(draws_pop, file.path(artifacts_dir, "draws_pop.rds"))
