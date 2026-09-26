###############################################
# Function for weighted descriptive trends 
###############################################

plot_descriptive_trend <- function(
    data,
    outcome,
    title,
    frequency = c("quarterly", "annual"),
    ylim = NULL,
    y_breaks = NULL
) {
  
  frequency <- match.arg(frequency)
  
  # Calculate weighted means by treatment group and quarter
  
  plot_data <- data |>
    group_by(mw_luecke_g2, year, month, timeQ) |>
    summarise(
      value = weighted.mean(
        .data[[outcome]],
        weight_pop13,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    arrange(year, month)
  
  # Preserve positions on the full quarterly timeline
  
  plot_data$xaxis <- as.numeric(plot_data$timeQ)
  
  # Separate higher- and lower-exposure regions
  
  treatment_group <- plot_data |>
    filter(mw_luecke_g2 == 1)
  
  control_group <- plot_data |>
    filter(mw_luecke_g2 == 0)
  
  # Annual outcomes are observed only once per year
  
  if (frequency == "annual") {
    treatment_group <- treatment_group |>
      filter(is.finite(value))
    
    control_group <- control_group |>
      filter(is.finite(value))
  }
  
  # Plot higher-exposure group
  
  if (is.null(ylim)) {
    ylim <- range(
      c(treatment_group$value, control_group$value),
      na.rm = TRUE
    )
  }
  
  plot(
    treatment_group$xaxis,
    treatment_group$value,
    type = "o",
    pch = 16,
    xaxt = "n",
    yaxt = "n",
    ylim = ylim,
    xlab = "",
    ylab = "",
    main = title
  )
  
  axis(
    2,
    at = if (is.null(y_breaks)) axTicks(2) else y_breaks,
    las = 1
  )
  
  # Add lower-exposure group
  
  lines(
    control_group$xaxis,
    control_group$value,
    type = "o",
    pch = 1
  )
  
  # Quarter labels
  
  if (frequency == "annual") {
    axis(
      1,
      at = treatment_group$xaxis,
      labels = paste0("6/", treatment_group$year),
      las = 2
    )
  } else {
    axis(
      1,
      at = seq_along(levels(data$timeQ)),
      labels = levels(data$timeQ),
      las = 2
    )
  }
  
  # Minimum-wage law passed
  
  abline(v = 6.2, lty = 2)
  
  # Minimum wage introduced in Q1/2015
  
  abline(v = 8.5, lty = 1)
  
  legend(
    "bottom",
    legend = c(
      "Control group (lower 50%)",
      "Treatment group (upper 50%)",
      "Minimum-wage law passed (July 2014)",
      "Minimum wage introduced (January 2015)"
    ),
    pch = c(1, 16, NA, NA),
    lty = c(1, 1, 2, 1),
    ncol = 2,
    bty = "n",
    xpd = NA,
    inset = c(0, -0.32),
    cex = 0.75
  )
}


###############################################
# Event-Study Plotting Function
###############################################

# Extract quarter or year from fixest coefficient names

.extract_period <- function(coef_name, frequency) {
  
  pattern <- if (frequency == "quarter") {
    "Q[1-4]/[0-9]{4}"
  } else {
    "[0-9]{4}"
  }
  
  hit <- regmatches(
    coef_name,
    regexpr(pattern, coef_name, perl = TRUE)
  )
  
  if (!length(hit) || hit == "") {
    return(NA_character_)
  }
  
  hit
}


# Place periods on a continuous calendar axis

.period_position <- function(period, frequency) {
  
  if (frequency == "quarter") {
    
    quarter <- as.numeric(substr(period, 2, 2))
    year <- as.numeric(substr(period, 4, 7))
    
    return(year + (quarter - 0.5) / 4)
  }
  
  # Annual outcomes are observed in the first half of the year
  as.numeric(period) + 0.25
}


plot_eventstudy <- function(
    model,
    title,
    frequency = c("quarter", "year"),
    reference = NULL,
    treatment = "mw_luecke"
) {
  
  frequency <- match.arg(frequency)
  
  if (is.null(reference)) {
    reference <- if (frequency == "quarter") "Q2/2014" else "2014"
  }
  
  estimates <- coef(model)
  coef_names <- names(estimates)
  
  # Identify treatment-by-period coefficients
  periods <- vapply(
    coef_names,
    .extract_period,
    character(1),
    frequency = frequency
  )
  
  keep <- grepl(
    treatment,
    coef_names,
    fixed = TRUE
  ) & !is.na(periods)
  
  if (!any(keep)) {
    stop("No treatment-by-period coefficients found.")
  }
  
  # Confidence intervals
  ci <- confint(model, level = 0.95)
  ci <- ci[coef_names[keep], , drop = FALSE]
  
  plot_data <- data.frame(
    period = periods[keep],
    estimate = estimates[keep],
    lower = ci[, 1],
    upper = ci[, 2]
  )
  
  # Add omitted reference period
  plot_data <- rbind(
    plot_data,
    data.frame(
      period = reference,
      estimate = 0,
      lower = 0,
      upper = 0
    )
  )
  
  # Position periods chronologically
  plot_data$x <- .period_position(
    plot_data$period,
    frequency
  )
  
  plot_data <- plot_data[
    order(plot_data$x),
  ]
  
  # Plot
  ggplot(plot_data, aes(x = x, y = estimate)) +
    geom_hline(
      yintercept = 0,
      linewidth = 0.45
    ) +
    geom_vline(
      xintercept = 2014.5,
      linetype = "dashed",
      linewidth = 0.55
    ) +
    geom_vline(
      xintercept = 2015,
      linetype = "solid",
      linewidth = 0.55
    ) +
    geom_errorbar(
      aes(ymin = lower, ymax = upper),
      width = 0.035,
      linewidth = 0.45
    ) +
    geom_point(size = 2.1) +
    scale_x_continuous(
      breaks = plot_data$x,
      labels = if (frequency == "year") {
        paste0("6/", plot_data$period)
      } else {
        plot_data$period
      },
      expand = expansion(mult = c(0.025, 0.025))
    ) +
    labs(
      title = title,
      x = "Time",
      y = "Point Estimate"
      ) +
    theme_classic(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14),
      axis.text.x = element_text(
        angle = 90,
        hjust = 1,
        vjust = 0.5
      ),
      plot.caption = element_text(hjust = 0.5)
    )
}