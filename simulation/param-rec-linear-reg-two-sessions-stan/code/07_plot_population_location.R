# reads: artifacts/draws_pop.rds, artifacts/true_population.rds
# writes: artifacts/p_population_location.rds, output/07_population_location.png

#### PLOT POPULATION LOCATION ####

draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))

df <- data.frame(
  value      = draws_pop$intercept,
  true_value = true_population$intercept,
  strip      = "mu[intercept]"
)

p <- ggplot(df, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(
    aes(xintercept = true_value),
    linetype = "dotted", colour = "blue", linewidth = 0.8
  ) +
  facet_wrap(~ strip, labeller = label_parsed, scales = "free_x") +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  ) +
  labs(x = "Population location")

saveRDS(p, file.path(artifacts_dir, "p_population_location.rds"))

plot_name <- "07_population_location"
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 4, dpi = 300, bg = "white")
