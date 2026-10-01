# reads: artifacts/p_population.rds, artifacts/p_icc.rds,
#        artifacts/p_individual_recovery.rds
# writes: output/10_recovery_figures.pdf

#### COMPILE RECOVERY PDF ####

p_population <- readRDS(file.path(artifacts_dir, "p_population.rds"))
p_icc        <- readRDS(file.path(artifacts_dir, "p_icc.rds"))
p_indiv      <- readRDS(file.path(artifacts_dir, "p_individual_recovery.rds"))

pdf(file.path(output_dir, "10_recovery_figures.pdf"), width = 10, height = 8, onefile = TRUE)
print(p_population)
print(p_icc)
print(p_indiv)
dev.off()
