# reads: artifacts/recovered_parameters.rds, artifacts/true_population.rds,
#        artifacts/p_population_location.rds, artifacts/p_population_scale.rds,
#        artifacts/p_icc.rds, artifacts/p_individual_recovery.rds
# writes: output/13_recovery_report.pdf

#### WRITE RECOVERY PDF ####

recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))
true_population      <- readRDS(file.path(artifacts_dir, "true_population.rds"))
agent_summary        <- attr(recovered_parameters, "agent_summary")
pop_summary          <- attr(recovered_parameters, "pop_summary")
rhat_max             <- attr(recovered_parameters, "rhat_max")
n_divergent          <- attr(recovered_parameters, "n_divergent")

p_location <- readRDS(file.path(artifacts_dir, "p_population_location.rds"))
p_scale    <- readRDS(file.path(artifacts_dir, "p_population_scale.rds"))
p_icc      <- readRDS(file.path(artifacts_dir, "p_icc.rds"))
p_indiv    <- readRDS(file.path(artifacts_dir, "p_individual_recovery.rds"))

page_w <- 11
page_h <- 8.5

wrap_to_width <- function(text, width_in, fontsize = 10) {
  chars <- max(24, floor(width_in * 72 / (fontsize * 0.48)))
  paste(strwrap(text, width = chars), collapse = "\n")
}

table_plot <- function(df, col_widths) {
  n_row <- nrow(df)
  n_col <- ncol(df)
  col_x <- cumsum(c(0, col_widths[-n_col])) + col_widths / 2
  df_chr <- as.data.frame(lapply(df, as.character), stringsAsFactors = FALSE)
  cells <- expand.grid(row = 0:n_row, col = seq_len(n_col), KEEP.OUT.ATTRS = FALSE)
  cells$label <- mapply(
    function(r, c) if (r == 0) names(df)[c] else df_chr[r, c],
    cells$row, cells$col
  )
  cells$is_header <- cells$row == 0
  cells$x     <- col_x[cells$col]
  cells$width <- col_widths[cells$col]
  cells$fill  <- ifelse(cells$is_header, "grey25",
                   ifelse(cells$row %% 2 == 1, "grey94", "white"))
  cells$colour <- ifelse(cells$is_header, "white",
                    ifelse(cells$label == "no", "#D55E00",
                      ifelse(cells$label == "yes", "#009E73", "grey15")))
  cells$face  <- ifelse(cells$is_header, "bold", "plain")
  cells$hjust <- ifelse(cells$col == 1, 0, 0.5)
  cells$tx    <- ifelse(cells$col == 1, cells$x - cells$width / 2 + 0.08, cells$x)
  ggplot(cells, aes(x = x, y = -row)) +
    geom_tile(aes(fill = fill, width = width), height = 0.92, colour = NA) +
    geom_text(
      aes(x = tx, label = label, colour = colour, fontface = face, hjust = hjust),
      size = 3.1
    ) +
    scale_fill_identity() +
    scale_colour_identity() +
    coord_cartesian(
      xlim = c(0, sum(col_widths)),
      ylim = c(-(n_row + 0.5), 0.5),
      expand = FALSE
    ) +
    theme_void()
}

draw_in <- function(grobs, x, y, width, height) {
  pushViewport(viewport(
    x = unit(x, "in"), y = unit(y, "in"),
    width = unit(width, "in"), height = unit(height, "in"),
    just = c("left", "top")
  ))
  grid.draw(grobs)
  popViewport()
}

draw_chip <- function(x, y, value, label, width = 2.35, fill = "grey95") {
  grid.roundrect(
    x = unit(x, "in"), y = unit(y, "in"),
    width = unit(width, "in"), height = unit(0.72, "in"),
    just = c("left", "top"), r = unit(5, "pt"),
    gp = gpar(fill = fill, col = "grey80", lwd = 0.7)
  )
  grid.text(
    value, x = unit(x + 0.14, "in"), y = unit(y - 0.12, "in"),
    just = c("left", "top"), gp = gpar(fontsize = 13, fontface = "bold", col = "grey15")
  )
  grid.text(
    label, x = unit(x + 0.14, "in"), y = unit(y - 0.42, "in"),
    just = c("left", "top"), gp = gpar(fontsize = 8.5, col = "grey40")
  )
}

draw_header <- function(title) {
  grid.text(
    title, x = unit(0.55, "in"), y = unit(page_h - 0.32, "in"),
    just = c("left", "top"), gp = gpar(fontsize = 16, fontface = "bold", col = "grey15")
  )
  grid.rect(
    x = unit(0.55, "in"), y = unit(page_h - 0.62, "in"),
    width = unit(page_w - 1.1, "in"), height = unit(1.2, "pt"),
    just = c("left", "top"), gp = gpar(fill = "grey25", col = NA)
  )
}

n_wrap_lines <- function(text, width_in, fontsize = 10) {
  chars <- max(24, floor(width_in * 72 / (fontsize * 0.48)))
  length(strwrap(text, width = chars))
}

draw_figure_page <- function(p, title, caption, fig_h) {
  grid.newpage()
  draw_header(title)
  fig_w <- page_w - 1.1
  fig_top <- page_h - 0.78
  draw_in(
    ggplotGrob(p + theme(plot.margin = margin(4, 8, 2, 8))),
    x = 0.55, y = fig_top,
    width = fig_w, height = fig_h
  )
  grid.text(
    wrap_to_width(caption, width_in = page_w - 1.2, fontsize = 10),
    x = unit(0.55, "in"), y = unit(fig_top - fig_h - 0.12, "in"),
    just = c("left", "top"),
    gp = gpar(fontsize = 10, fontface = "italic", col = "grey25", lineheight = 1.15)
  )
}

para_design <- paste0(
  "Data were generated from ", n_subjects, " agents, ", n_sessions,
  " sessions, and ", n_trials, " observations per agent per session. ",
  "The intercept was fixed at ", true_population$intercept, ". ",
  "Agent-level random effects were drawn as gamma_subject ~ Normal(0, ",
  true_population$sigma_subject, "), gamma_session ~ Normal(0, ",
  true_population$sigma_session, "), and gamma_subjectXsession ~ Normal(0, ",
  true_population$sigma_subjectXsession, "). Residual error was Normal(0, ",
  true_population$sigma_error, ")."
)
para_icc <- paste0(
  "ICC_agreement and ICC_consistency were stored as true values (",
  round(true_population$ICC_agreement, 2), " and ",
  round(true_population$ICC_consistency, 2),
  ") using the two-way single-measure formulas on subject-session means ",
  "(variances, with subject-by-session interaction and trial error / n_trials in the residual); ",
  "they were not used to generate data and were recovered from the scale parameters. ",
  "No parameter was transformed onto the unit interval. ",
  "Parameters were recovered with brms. ",
  "The sampler used ", n_chains, " chains, ", n_iter, " iterations, and ",
  n_warmup, " warmup."
)

df_pop <- data.frame(
  Parameter = pop_summary$parameter,
  True      = sprintf("%.3f", pop_summary$true_val),
  Median    = sprintf("%.3f", pop_summary$posterior_median),
  `5%`      = sprintf("%.3f", pop_summary$q05),
  `95%`     = sprintf("%.3f", pop_summary$q95),
  Covered   = ifelse(pop_summary$contains_true, "yes", "no"),
  check.names = FALSE
)
df_agent <- data.frame(
  Parameter     = agent_summary$parameter,
  r             = sprintf("%.3f", agent_summary$pearson_r),
  Bias          = sprintf("%.3f", agent_summary$mean_bias),
  Slope         = sprintf("%.3f", agent_summary$slope),
  Range         = sprintf("%.3f", agent_summary$range_frac),
  `Post. SD`    = sprintf("%.3f", agent_summary$median_posterior_sd),
  `Pass r`      = ifelse(agent_summary$pass_r, "yes", "no"),
  `Pass bias`   = ifelse(agent_summary$pass_bias, "yes", "no"),
  `Pass prec.`  = ifelse(agent_summary$pass_prec, "yes", "no"),
  check.names   = FALSE
)

p_pop_tbl   <- table_plot(df_pop,   c(2.35, 1.15, 1.15, 1.15, 1.15, 1.15))
p_agent_tbl <- table_plot(df_agent, c(2.20, 0.85, 0.90, 0.85, 0.90, 1.05, 0.85, 1.05, 1.05))
conv_fill   <- if (n_divergent > 0 || rhat_max > 1.01) "#F6EBE4" else "grey95"

caption_1 <- paste(
  "Figure 1. Posterior density of the population location (intercept).",
  "The dotted blue line marks the true generating value."
)
caption_2 <- paste(
  "Figure 2. Posterior densities of the population scale parameters.",
  "The dotted blue line marks the true generating value on each panel."
)
caption_3 <- paste(
  "Figure 3. Posterior densities of ICC_agreement and ICC_consistency,",
  "derived from the scale-parameter draws.",
  "The dotted blue line marks the true value stored with the generating parameters.",
  "The solid orange line marks the irr::icc estimate from subject-session means",
  "(twoway, single unit; agreement or consistency matching the panel)."
)
caption_4 <- paste(
  "Figure 4. True versus recovered agent-level parameters.",
  "The dashed line is the identity; the solid line is the OLS fit; r is Pearson's correlation."
)

open_pdf <- if (isTRUE(capabilities("cairo"))) cairo_pdf else pdf
open_pdf(file.path(output_dir, "13_recovery_report.pdf"), width = page_w, height = page_h, onefile = TRUE)

grid.newpage()
grid.text(
  "Parameter recovery",
  x = unit(0.55, "in"), y = unit(page_h - 0.32, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 22, fontface = "bold", col = "grey15")
)
grid.text(
  fitted_model,
  x = unit(0.55, "in"), y = unit(page_h - 0.72, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 11, col = "grey40")
)
grid.rect(
  x = unit(0.55, "in"), y = unit(page_h - 0.96, "in"),
  width = unit(page_w - 1.1, "in"), height = unit(1.4, "pt"),
  just = c("left", "top"), gp = gpar(fill = "grey25", col = NA)
)
chip_y <- page_h - 1.12
draw_chip(0.55, chip_y, n_subjects, "agents")
draw_chip(3.00, chip_y, n_sessions, "sessions")
draw_chip(5.45, chip_y, n_trials, "trials per session")
draw_chip(7.90, chip_y, paste0("R-hat ", sprintf("%.3f", rhat_max)),
          paste(n_divergent, "divergences"), fill = conv_fill)

y <- page_h - 2.02
grid.text(
  "Design",
  x = unit(0.55, "in"), y = unit(y, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 12, fontface = "bold", col = "grey15")
)
y <- y - 0.28
grid.text(
  wrap_to_width(para_design, width_in = 9.9, fontsize = 10),
  x = unit(0.55, "in"), y = unit(y, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 10, col = "grey20", lineheight = 1.25)
)
y <- y - n_wrap_lines(para_design, 9.9) * (10 * 1.25 / 72) - 0.16
grid.text(
  wrap_to_width(para_icc, width_in = 9.9, fontsize = 10),
  x = unit(0.55, "in"), y = unit(y, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 10, col = "grey20", lineheight = 1.25)
)
y <- y - n_wrap_lines(para_icc, 9.9) * (10 * 1.25 / 72) - 0.28

grid.text(
  "Population recovery",
  x = unit(0.55, "in"), y = unit(y, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 12, fontface = "bold", col = "grey15")
)
y <- y - 0.22
row_h <- 0.235
pop_h <- (nrow(df_pop) + 1) * row_h
draw_in(ggplotGrob(p_pop_tbl), x = 0.55, y = y, width = 8.1, height = pop_h)
y <- y - pop_h - 0.18

grid.text(
  "Agent-level recovery",
  x = unit(0.55, "in"), y = unit(y, "in"),
  just = c("left", "top"), gp = gpar(fontsize = 12, fontface = "bold", col = "grey15")
)
y <- y - 0.22
draw_in(ggplotGrob(p_agent_tbl), x = 0.55, y = y, width = 9.9, height = (nrow(df_agent) + 1) * row_h)

draw_figure_page(p_location, "Figure 1. Population location", caption_1, fig_h = 4.0)
draw_figure_page(p_scale, "Figure 2. Population scale", caption_2, fig_h = 6.4)
draw_figure_page(p_icc, "Figure 3. Intraclass correlation", caption_3, fig_h = 4.0)
draw_figure_page(p_indiv, "Figure 4. Agent-level recovery", caption_4, fig_h = 6.4)

dev.off()
