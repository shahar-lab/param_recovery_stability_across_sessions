# reads: artifacts/brms_fit.rds
# writes: output/06_diagnostic.pdf

#### WRITE DIAGNOSTICS ####

brms_fit   <- readRDS(file.path(artifacts_dir, "brms_fit.rds"))
draws_full <- as_draws_array(brms_fit)

population_vars <- variables(draws_full)[!grepl("^r_", variables(draws_full))]
population_vars <- population_vars[!population_vars %in% c("lprior", "lp__", "Intercept")]
draws <- subset_draws(draws_full, variable = population_vars, regex = FALSE)

summary_table <- summarise_draws(draws, ess_bulk, ess_tail, rhat)
summary_table[-1] <- round(summary_table[-1], 2)

trank_plot <- mcmc_rank_overlay(draws)
pairs_plot <- mcmc_pairs(draws)

pdf(file.path(output_dir, "06_diagnostic.pdf"), width = 8, height = 6)
grid.arrange(tableGrob(summary_table))
print(trank_plot)
print(pairs_plot)
dev.off()
