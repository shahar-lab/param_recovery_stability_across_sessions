# reads: artifacts/draws_pop.rds, artifacts/true_population.rds,
#        artifacts/icc_from_irr.rds,
#        <random_session_artifacts_dir>/draws_pop.rds (from main.R)
# writes: artifacts/icc_model_comparison.rds, output/11_icc_model_comparison.png

#### COMPARE ICC WITH RANDOM-SESSION FIT ####

random_draws_file <- file.path(random_session_artifacts_dir, "draws_pop.rds")

if (!file.exists(random_draws_file)) {
  cat("\nSkipping ICC comparison: no random-session draws at", random_draws_file, "\n")
} else {
  draws_fixed     <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
  draws_random    <- readRDS(random_draws_file)
  true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
  icc_from_irr    <- readRDS(file.path(artifacts_dir, "icc_from_irr.rds"))

  model_levels <- c("Random session", "Fixed session")

  df <- bind_rows(
    data.frame(model = "Random session", strip = "ICC[agreement]",   value = draws_random$ICC_agreement),
    data.frame(model = "Random session", strip = "ICC[consistency]", value = draws_random$ICC_consistency),
    data.frame(model = "Fixed session",  strip = "ICC[agreement]",   value = draws_fixed$ICC_agreement),
    data.frame(model = "Fixed session",  strip = "ICC[consistency]", value = draws_fixed$ICC_consistency)
  ) |>
    mutate(model = factor(model, levels = rev(model_levels)))

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

  icc_model_comparison <- df |>
    group_by(strip, model) |>
    summarise(
      median = median(value),
      q05    = quantile(value, 0.05),
      q95    = quantile(value, 0.95),
      .groups = "drop"
    )
  cat("\nICC posterior by model (median, 90% interval)\n")
  print(as.data.frame(icc_model_comparison))

  pal_lines <- c("True" = "blue", "irr::icc" = "#E69F00")
  lty_lines <- c("True" = "dotted", "irr::icc" = "solid")

  p <- ggplot(df, aes(x = value, y = model)) +
    stat_slab(fill = "gray80", height = 0.9) +
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
      panel.grid      = element_blank(),
      axis.line.x     = element_line(colour = "grey30"),
      legend.position = "bottom"
    ) +
    labs(x = "ICC", y = NULL, colour = NULL, linetype = NULL) +
    coord_cartesian(xlim = c(0, 1))

  saveRDS(icc_model_comparison, file.path(artifacts_dir, "icc_model_comparison.rds"))

  plot_name <- "11_icc_model_comparison"
  ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 4.5, dpi = 300, bg = "white")
}
