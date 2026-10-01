# reads: artifacts/draws_pop.rds, artifacts/true_population.rds
# writes: artifacts/p_population.rds, output/07_population.png

#### PLOT POPULATION PARAMETERS ####

draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))

pop_strips <- c(
  "mu_log_beta[1]"        = "mu[log~beta]~session~1",
  "mu_log_beta[2]"        = "mu[log~beta]~session~2",
  sigma_subject           = "sigma[subject]",
  sigma_subjectXsession   = "sigma[subject%*%session]",
  mu_alpha                = "mu[logit~alpha]",
  sigma_alpha             = "sigma[logit~alpha]"
)

df <- map(names(pop_strips), function(nm) {
  data.frame(value = draws_pop[[nm]], strip = pop_strips[[nm]])
}) |>
  bind_rows() |>
  mutate(strip = factor(strip, levels = pop_strips))

df_lines <- data.frame(
  strip      = factor(pop_strips, levels = pop_strips),
  xintercept = vapply(names(pop_strips), function(nm) true_population[[nm]], numeric(1))
)

p <- ggplot(df, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(
    data = df_lines, aes(xintercept = xintercept),
    linetype = "dotted", colour = "blue", linewidth = 0.8
  ) +
  facet_wrap(~ strip, labeller = label_parsed, scales = "free_x", ncol = 3) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  ) +
  labs(x = "Population parameter")

saveRDS(p, file.path(artifacts_dir, "p_population.rds"))

plot_name <- "07_population"
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 6, dpi = 300, bg = "white")
