# reads: artifacts/draws_pop.rds, artifacts/true_population.rds,
#        artifacts/icc_from_irr.rds
# writes: artifacts/p_icc.rds, output/08_icc.png

#### PLOT ICC RECOVERY ####

draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
icc_from_irr    <- readRDS(file.path(artifacts_dir, "icc_from_irr.rds"))

df <- bind_rows(
  data.frame(
    value = draws_pop$ICC_agreement,
    strip = "ICC[agreement]"
  ),
  data.frame(
    value = draws_pop$ICC_consistency,
    strip = "ICC[consistency]"
  )
)

df_lines <- bind_rows(
  data.frame(
    strip      = c("ICC[agreement]", "ICC[consistency]"),
    xintercept = c(true_population$ICC_agreement, true_population$ICC_consistency),
    source     = "True"
  ),
  data.frame(
    strip      = c("ICC[agreement]", "ICC[consistency]"),
    xintercept = c(icc_from_irr$ICC_agreement, icc_from_irr$ICC_consistency),
    source     = "irr::icc"
  )
)

pal_lines <- c("True" = "blue", "irr::icc" = "#E69F00")
lty_lines <- c("True" = "dotted", "irr::icc" = "solid")

p <- ggplot(df, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(
    data = df_lines,
    aes(xintercept = xintercept, colour = source, linetype = source),
    linewidth = 0.8
  ) +
  scale_colour_manual(values = pal_lines) +
  scale_linetype_manual(values = lty_lines) +
  facet_wrap(~ strip, labeller = label_parsed) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid             = element_blank(),
    axis.title.y           = element_blank(),
    axis.text.y            = element_blank(),
    axis.ticks.y           = element_blank(),
    axis.line.y            = element_blank(),
    axis.line.x            = element_line(colour = "grey30"),
    legend.position        = "inside",
    legend.position.inside = c(1, 0.95),
    legend.justification   = c("right", "top"),
    legend.background      = element_blank(),
    legend.key             = element_blank()
  ) +
  labs(x = "ICC", colour = NULL, linetype = NULL) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

saveRDS(p, file.path(artifacts_dir, "p_icc.rds"))

plot_name <- "08_icc"
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 4, dpi = 300, bg = "white")
