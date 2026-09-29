# reads: artifacts/draws_pop.rds, artifacts/true_population.rds
# writes: artifacts/p_population_scale.rds, output/09_population_scale.{pdf,png}

#### PLOT POPULATION SCALE ####

draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))

df <- bind_rows(
  data.frame(value = draws_pop$sigma_error, true_value = true_population$sigma_error, strip = "sigma[error]"),
  data.frame(value = draws_pop$sigma_subject, true_value = true_population$sigma_subject, strip = "sigma[subject]"),
  data.frame(value = draws_pop$sigma_session, true_value = true_population$sigma_session, strip = "sigma[session]"),
  data.frame(
    value      = draws_pop$sigma_subjectXsession,
    true_value = true_population$sigma_subjectXsession,
    strip      = "sigma[subjectXsession]"
  )
)

p <- ggplot(df, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(
    aes(xintercept = true_value),
    linetype = "dotted", colour = "blue", linewidth = 0.8
  ) +
  facet_wrap(~ strip, labeller = label_parsed, scales = "free_x", ncol = 2) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  ) +
  labs(x = "Population scale")

saveRDS(p, file.path(artifacts_dir, "p_population_scale.rds"))

plot_name <- "09_population_scale"
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = p, width = 10, height = 8, bg = "white")
