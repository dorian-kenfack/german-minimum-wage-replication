###############################################
# Replication of Bonin et al. (2020)
###############################################

# Replication and additional analysis of average annual hours worked

###############################################
# 0. Packages and Data
###############################################

library(fixest)
library(dplyr)
library(ggplot2)
library(patchwork)

source("code/functions.R")

panel_data <- read.csv("data/original/mlkamrpanel.csv")
hours_data <- read.csv("data/final/AMR_Working_Hours_2013_2016.csv")

###############################################
# 1. Prepare Variables and Analysis Samples
###############################################

## 1.1 Treatment indicator

# Remove leading and trailing whitespace
panel_data$mw_luecke_g2 <- trimws(panel_data$mw_luecke_g2)

# Convert treatment labels to binary indicator
panel_data$mw_luecke_g2[
  panel_data$mw_luecke_g2 == "treatment"
] <- 1

panel_data$mw_luecke_g2[
  panel_data$mw_luecke_g2 == "control"
] <- 0

panel_data$mw_luecke_g2 <- as.numeric(
  panel_data$mw_luecke_g2
)

## 1.2 Time variables

# Annual trend: constant within each year
panel_data$trend_year <- panel_data$year - 2013

# Chronological ordering of quarters
quarter_levels <- c(
  "Q1/2013", "Q2/2013", "Q3/2013", "Q4/2013",
  "Q1/2014", "Q2/2014", "Q3/2014", "Q4/2014",
  "Q1/2015", "Q2/2015", "Q3/2015", "Q4/2015",
  "Q1/2016", "Q2/2016", "Q3/2016", "Q4/2016"
)

panel_data$timeQ <- factor(
  panel_data$timeQ,
  levels = quarter_levels
)

# Continuous quarterly trend: Q1/2013 = 0, ..., Q4/2016 = 15
panel_data$trend_quarter <- as.numeric(panel_data$timeQ) - 1

# 'time' is stored as text in the raw panel.
# Converting it to a factor allows time-specific, non-linear interactions.
panel_data$time_factor <- factor(panel_data$time)


## 1.3 East-West indicator

panel_data$east <- factor(
  panel_data$east,
  levels = c(1, 0),
  labels = c("East", "West")
)


## 1.4 Restricted sample for Specification 5

q <- quantile(
  panel_data$mw_luecke,
  probs = c(0.1, 0.9),
  na.rm = TRUE
)

# Including the upper cutoff reproduces the reported sample size.
# The original Stata code uses a strict upper bound.
trimmed_sample <- panel_data[
  panel_data$mw_luecke > q[1] &
    panel_data$mw_luecke <= q[2],
]


###############################################
# 2. Figure 3: Descriptive Trends by Exposure Group
###############################################

# Save multi-panel figure
png(
  "figures/figure_3.png",
  width = 1400,
  height = 2200,
  res = 180
)

par(
  mfrow = c(3, 1),
  mar = c(8, 4, 3, 1)
)

plot_descriptive_trend(
  data = panel_data,
  outcome = "log_svb_total",
  title = "(a) Regular employment (in logs)",
  frequency = "quarterly",
  ylim = c(11.8, 12.42),
  y_breaks = seq(11.8, 12.4, by = 0.2)
)

plot_descriptive_trend(
  panel_data,
  "log_geb_total",
  "(b) Marginal employment (in logs)",
  frequency = "annual",
  ylim = c(10.35, 11.0),
  y_breaks = seq(10.4, 11.0, by = 0.2)
)

plot_descriptive_trend(
  panel_data,
  "log_al_abs_insg_tot",
  "(c) Total unemployment (in logs)",
  frequency = "quarterly",
  ylim = c(9.6, 9.85),
  y_breaks = seq(9.6, 9.85, by = 0.05)
)

dev.off()


###############################################
# 3. Binary Difference-in-Differences Models
###############################################

# For Specifications 4 and 5, the control structure follows
# the original Stata implementation.
# The controls combine sector-specific trends with time-varying
# East-West interactions in pre-treatment regional characteristics.

# Specifications:
# (1) AMR and time fixed effects
# (2) Additional East-West-specific seasonal/trend controls
# (3) Additional East-West and AMR-type-specific time effects
# (4) Additional trends in pre-treatment regional characteristics
# (5) Specification 4 using the trimmed exposure sample

# Table 1

## Panel A: Regular employment (quarterly outcome)

panelA.1 <- feols(
  log_svb_total ~ mw_luecke_g2:post14 | amr + timeQ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelA.2 <- feols(
  log_svb_total ~ mw_luecke_g2:post14 | amr + timeQ + east^month,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelA.3 <- feols(
  log_svb_total ~ mw_luecke_g2:post14 | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelA.4 <- feols(
  log_svb_total ~ mw_luecke_g2:post14 +
    trend_quarter:empl_share_manutot_2013:east +
    trend_quarter:empl_share_publ_2013:east +
    trend_quarter:empl_share_agric_2013:east +
    trend_quarter:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelA.5 <- feols(
  log_svb_total ~ mw_luecke_g2:post14 +
    trend_quarter:empl_share_manutot_2013:east +
    trend_quarter:empl_share_publ_2013:east +
    trend_quarter:empl_share_agric_2013:east +
    trend_quarter:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

t1.A <- etable(
  panelA.1, panelA.2, panelA.3, panelA.4, panelA.5,
  keep_raw = "^mw_luecke_g2:post14$",
  digits = 4
)
print(t1.A)

## Panel B: Marginal employment (annual outcome)

panelB.1 <- feols(
  log_geb_total ~ mw_luecke_g2:post14 | amr + year,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelB.2 <- feols(
  log_geb_total ~ mw_luecke_g2:post14 + east:trend_year | amr + year,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelB.3 <- feols(
  log_geb_total ~ mw_luecke_g2:post14 | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelB.4 <- feols(
  log_geb_total ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelB.5 <- feols(
  log_geb_total ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

t1.B <- etable(
  panelB.1, panelB.2, panelB.3, panelB.4, panelB.5,
  keep_raw = "^mw_luecke_g2:post14$",
  digits = 4
)
print(t1.B)

## Panel C: Exclusive marginal employment (annual outcome)

panelC.1 <- feols(
  log_geb_ausschl ~ mw_luecke_g2:post14 | amr + year,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelC.2 <- feols(
  log_geb_ausschl ~ mw_luecke_g2:post14 + east:trend_year | amr + year,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelC.3 <- feols(
  log_geb_ausschl ~ mw_luecke_g2:post14 | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelC.4 <- feols(
  log_geb_ausschl ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelC.5 <- feols(
  log_geb_ausschl ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

t1.C <- etable(
  panelC.1, panelC.2, panelC.3, panelC.4, panelC.5,
  keep_raw = "^mw_luecke_g2:post14$",
  digits = 4
)
print(t1.C)

## Panel D: Regular and exclusive marginal employment (annual outcome)

panelD.1 <- feols(
  log_svgeb_total ~ mw_luecke_g2:post14 | amr + year,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelD.2 <- feols(
  log_svgeb_total ~ mw_luecke_g2:post14 + east:trend_year | amr + year,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelD.3 <- feols(
  log_svgeb_total ~ mw_luecke_g2:post14 | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelD.4 <- feols(
  log_svgeb_total ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east  | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

panelD.5 <- feols(
  log_svgeb_total ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east  | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

t1.D <- etable(
  panelD.1, panelD.2, panelD.3, panelD.4, panelD.5,
  keep_raw = "^mw_luecke_g2:post14$",
  digits = 4
)
print(t1.D)

# Table 2: Unemployment (quarterly Outcome)

table2.1 <- feols(
  log_al_abs_insg_tot ~ mw_luecke_g2:post14 | amr + timeQ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

table2.2 <- feols(
  log_al_abs_insg_tot ~ mw_luecke_g2:post14 | amr + timeQ + east^month,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

table2.3 <- feols(
  log_al_abs_insg_tot ~ mw_luecke_g2:post14 | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

table2.4 <- feols(
  log_al_abs_insg_tot ~ mw_luecke_g2:post14 +
    trend_quarter:empl_share_manutot_2013:east +
    trend_quarter:empl_share_publ_2013:east +
    trend_quarter:empl_share_agric_2013:east +
    trend_quarter:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = panel_data
)

table2.5 <- feols(
  log_al_abs_insg_tot ~ mw_luecke_g2:post14 +
    trend_quarter:empl_share_manutot_2013:east +
    trend_quarter:empl_share_publ_2013:east +
    trend_quarter:empl_share_agric_2013:east +
    trend_quarter:empl_share_trade_2013 +
    pop_share_1864_2013:time_factor:east | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

t2 <- etable(
  table2.1, table2.2, table2.3, table2.4, table2.5,
  keep_raw = "^mw_luecke_g2:post14$",
  digits = 4
)
print(t2)

###############################################
# 4. Continuous Event-Study Models
###############################################

# Event-study models using Specification 5 to reproduce the original figures.
# Note: Bonin et al. (2020) designate Specification 4 as their preferred specification.

# Quarterly outcomes: Q2/2014 is the reference period
# Annual outcomes: 2014 is the reference period

c_event_regular <- feols(
  log_svb_total ~ i(timeQ, mw_luecke, ref = "Q2/2014")
  + trend_quarter:empl_share_manutot_2013:east 
  + trend_quarter:empl_share_publ_2013:east 
  + trend_quarter:empl_share_agric_2013:east 
  + trend_quarter:empl_share_trade_2013:east  
  + time_factor:pop_share_1864_2013:east | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

print(etable(
  c_event_regular,
  keep_raw = "^timeQ::.*:mw_luecke$",
  digits = 4
))

c_event_marginal <- feols(
  log_geb_ausschl ~ i(year, mw_luecke, ref = 2014) +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013:east +
    time_factor:pop_share_1864_2013:east |
    amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

print(etable(
  c_event_marginal,
  keep_raw = "^year::.*:mw_luecke$",
  digits = 4
))

c_event_total_employment <- feols(
  log_svgeb_total ~ i(year, mw_luecke, ref = 2014)
  + trend_year:empl_share_manutot_2013:east 
  + trend_year:empl_share_publ_2013:east 
  + trend_year:empl_share_agric_2013:east 
  + trend_year:empl_share_trade_2013:east  
  + time_factor:pop_share_1864_2013:east | amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

print(etable(
  c_event_total_employment,
  keep_raw = "^year::.*:mw_luecke$",
  digits = 4
))

c_event_unemployment <- feols(
  log_al_abs_insg_tot ~ i(timeQ, mw_luecke, ref = "Q2/2014")
  + trend_quarter:empl_share_manutot_2013:east 
  + trend_quarter:empl_share_publ_2013:east 
  + trend_quarter:empl_share_agric_2013:east 
  + trend_quarter:empl_share_trade_2013:east  
  + time_factor:pop_share_1864_2013:east | amr + timeQ + east^timeQ^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = trimmed_sample
)

print(etable(
  c_event_unemployment,
  keep_raw = "^timeQ::.*:mw_luecke$",
  digits = 4
))


###############################################
# 5. Figures 4 and 5: Continuous Event Studies
###############################################

# Regular employment

p_regular <- plot_eventstudy(
  c_event_regular,
  "(a) Regular employment (in logs)",
  frequency = "quarter"
) +
  scale_y_continuous(
    breaks = seq(-0.06, 0.06, by = 0.02)
  ) +
  coord_cartesian(
    ylim = c(-0.07, 0.065)
  )

# Marginal Employment

p_marginal <- plot_eventstudy(
  c_event_marginal,
  title = "(b) Marginal employment (in logs)",
  frequency = "year"
) +
  scale_y_continuous(
    breaks = seq(-0.4, 0.1, by = 0.1)
  ) +
  coord_cartesian(
    ylim = c(-0.43, 0.12)
  )

# Total employment

p_total_employment <- plot_eventstudy(
  c_event_total_employment,
  "(c) Total employment (regular and marginal, in logs)",
  frequency = "year"
) +
  scale_y_continuous(
    breaks = seq(-0.10, 0.05, by = 0.05)
  ) +
  coord_cartesian(
    ylim = c(-0.105, 0.055)
  )

# Multi-panel: figure 4

figure_4 <- wrap_plots(
  p_regular,
  p_marginal,
  p_total_employment,
  ncol = 1
)

ggsave(
  "figures/figure_4.png",
  figure_4,
  width = 8,
  height = 14,
  dpi = 300
)

# Unemployment: figure 5

png(
  "figures/figure_5.png",
  width = 1800,
  height = 1200,
  res = 150
)

p_unemployment <- plot_eventstudy(
  c_event_unemployment,
  "Total unemployment (in logs)",
  frequency = "quarter"
) +
  scale_y_continuous(
    breaks = seq(-0.4, 0.4, by = 0.2)
  ) +
  coord_cartesian(
    ylim = c(-0.43, 0.43)
  )

print(p_unemployment)

dev.off()

###############################################
# 6. Additional Analysis: Working Hours
###############################################

# Merge time-invariant treatment and baseline controls

amr_controls <- panel_data |>
  filter(year == 2013, month == 12) |>
  select(
    amr,
    mw_luecke,
    mw_luecke_g2,
    east,
    amr_typ,
    weight_pop13,
    pop_share_1864_2013,
    starts_with("empl_share_")
  )

hours_analysis <- hours_data |>
  left_join(amr_controls, by = "amr")

# Prepare annual analysis variables

hours_analysis$trend_year <- hours_analysis$year - 2013
hours_analysis$log_hours <- log(hours_analysis$stunden_je_erwerbstaetigen)

# Pre-treatment period: 2013–2014
# Post-treatment period: 2015–2016

hours_analysis$post14 <- ifelse(
  hours_analysis$year >= 2015,
  1,
  0
)

## Binary DiD: annual analogue of Bonin et al.'s preferred specification

hours_did <- feols(
  log_hours ~ mw_luecke_g2:post14 +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    trend_year:pop_share_1864_2013:east |
    amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = hours_analysis
)

print(etable(
  hours_did,
  keep_raw = "^mw_luecke_g2:post14$",
  digits = 4
))

## Continuous event study: annual analogue of Bonin et al.'s preferred specification

hours_event <- feols(
  log_hours ~ i(year, mw_luecke, ref = 2014) +
    trend_year:empl_share_manutot_2013:east +
    trend_year:empl_share_publ_2013:east +
    trend_year:empl_share_agric_2013:east +
    trend_year:empl_share_trade_2013 +
    trend_year:pop_share_1864_2013:east |
    amr + year + east^year^amr_typ,
  cluster = ~ amr,
  weights = ~ weight_pop13,
  data = hours_analysis
)

print(etable(
  hours_event,
  keep_raw = "^year::.*:mw_luecke$",
  digits = 4
))

## Plotting of the continous event study

p_hours <- plot_eventstudy(
    hours_event,
    title = "Average annual hours worked per employed person",
    frequency = "year",
    reference = "2014"
  )
  
  p_hours$layers <- Filter(
    function(layer) !inherits(layer$geom, "GeomVline"),
    p_hours$layers
  )
  
  p_hours$data$x <- as.numeric(p_hours$data$period)
  
  p_hours <- p_hours +
    scale_x_continuous(
      breaks = 2013:2016,
      labels = as.character(2013:2016),
      expand = expansion(mult = c(0.04, 0.04))
    ) +
    labs(
      x = "Year",
      y = "Coefficient estimate (log points)"
    ) +
    theme(
      axis.text.x = element_text(
        angle = 0,
        hjust = 0.5,
        vjust = 0.5
      )
    )
  
  p_hours <- p_hours +
    geom_vline(
      xintercept = 2014.5,
      linetype = "dashed",
      linewidth = 0.55
    )
  
  png(
    "figures/working_hours.png",
    width = 1800,
    height = 1200,
    res = 150
  )
  
  print(p_hours)
  
dev.off()