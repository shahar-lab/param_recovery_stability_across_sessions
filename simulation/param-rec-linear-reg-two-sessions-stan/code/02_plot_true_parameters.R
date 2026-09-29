# reads: artifacts/true_parameters.rds, artifacts/true_population.rds
# writes: output/02_true_parameters_dot_histogram.png

#### PLOT TRUE PARAMETERS ####

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
gamma_session   <- attr(true_parameters, "gamma_session")

df <- bind_rows(
  data.frame(parameter = "gamma_subject", x = true_parameters$gamma_subject),
  data.frame(parameter = "gamma_session", x = gamma_session),
  data.frame(parameter = "gamma_subjectXsession", x = c(
    true_parameters$gamma_subjectXsession_1,
    true_parameters$gamma_subjectXsession_2
  ))
)

build_dot_histogram <- function(df_one, x_lab, sd_true) {
  theory_lo   <- -3 * sd_true
  theory_hi   <-  3 * sd_true
  full_range  <- range(c(theory_lo, theory_hi, df_one$x))
  axis_breaks <- round(seq(theory_lo, theory_hi, length.out = 5), 2)

  p <- ggplot(df_one, aes(x = x)) +
    geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30") +
    scale_x_continuous(breaks = axis_breaks) +
    coord_cartesian(xlim = full_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), aspect.ratio = 1) +
    labs(x = x_lab)

  built       <- ggplot_build(p)$data[[1]]
  max_y       <- max(built$ymax) * built$scale[1]
  bw          <- find_dotplot_binwidth(df_one$x, maxheight = 1, layout = "bin")
  binned      <- bin_dots(x = df_one$x, y = 0, binwidth = bw, layout = "bin")
  max_count   <- max(tabulate(factor(binned$bin)))
  tick_counts <- unique(round(seq(0, max_count, length.out = 4)))
  tick_y      <- tick_counts / max_count * max_y

  xs       <- seq(full_range[1], full_range[2], length.out = 200)
  dens     <- dnorm(xs, mean = 0, sd = sd_true)
  dens_y   <- dens / max(dens) * max_y
  df_curve <- data.frame(x = xs, y = dens_y)

  p +
    geom_line(
      data = df_curve, aes(x = x, y = y),
      colour = "#0072B2", linewidth = 0.9, inherit.aes = FALSE
    ) +
    scale_y_continuous(
      name   = "Count",
      breaks = tick_y,
      labels = tick_counts
    )
}

p_subject <- build_dot_histogram(
  df[df$parameter == "gamma_subject", ],
  "True gamma_subject",
  true_population$sigma_subject
)
p_session <- build_dot_histogram(
  df[df$parameter == "gamma_session", ],
  "True gamma_session",
  true_population$sigma_session
)
p_inter <- build_dot_histogram(
  df[df$parameter == "gamma_subjectXsession", ],
  "True gamma_subjectXsession",
  true_population$sigma_subjectXsession
)

p_final <- (p_subject | p_session | p_inter) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

plot_name <- "02_true_parameters_dot_histogram"
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p_final, width = 10, height = 5, dpi = 300, bg = "white")
