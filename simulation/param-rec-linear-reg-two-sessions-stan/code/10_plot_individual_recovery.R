# reads: artifacts/recovered_parameters.rds
# writes: artifacts/p_individual_recovery.rds, output/10_individual_recovery.png

#### PLOT INDIVIDUAL RECOVERY ####

df <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))
df <- df[complete.cases(df$true, df$recovered), ]

r_labels <- df |>
  group_by(parameter) |>
  summarise(
    pearson_r = cor(true, recovered),
    .groups   = "drop"
  ) |>
  mutate(label = sprintf("[Pearson r = %.2f]", pearson_r))

p <- ggplot(df, aes(x = true, y = recovered)) +
  geom_point(colour = "#56B4E9", alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#D55E00", linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  geom_text(
    data = r_labels,
    aes(x = Inf, y = Inf, label = label),
    hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30", inherit.aes = FALSE
  ) +
  facet_wrap(~ parameter, scales = "free") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), aspect.ratio = 1) +
  labs(x = "True parameter value", y = "Recovered parameter value")

saveRDS(p, file.path(artifacts_dir, "p_individual_recovery.rds"))

plot_name <- "10_individual_recovery"
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 8, dpi = 300, bg = "white")
