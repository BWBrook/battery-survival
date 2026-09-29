#!/usr/bin/env Rscript
# Reuse saved posterior fits; no sampling or changes to archived SA outputs.
args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args)) args[1] else "outputs/sensitivity/2026-09-17"
out <- if (length(args) > 1) args[2] else "outputs/management/2026-09-18"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source("R/sensitivity_camera_fit.R")
source("R/sensitivity_camera_predict.R")
source("R/profile_support.R")
source("R/management_policy.R")
design <- readRDS(file.path(input, "design.rds"))
profiles <- read.csv(file.path(input, "tables", "profiles.csv"))
costs <- read.csv("config/battery_costs.csv")
scenarios <- expand.grid(service_cost = c(80, 450, 900), lost_day_cost = c(1, 3, 10))
X <- cam_new_design(design, profiles)
support <- function(T, profile) {
  management_support(T, profile, design$train)
}
policies <- fixed <- list()
for (family in c("weibull", "loglogistic")) {
  fit <- readRDS(file.path(input, "models", paste0(family, "_camera"), "fit.rds"))
  draws <- cam_extract_draws(fit, design, 1000)
  for (j in seq_len(nrow(profiles))) {
    p <- profiles[j, ]
    mu <- draws$alpha + as.numeric(draws$beta %*% X[j, ])
    sig <- draws$sigma[, match(p$bb, design$brands)]
    cb <- costs$battery_cost[match(p$bb, costs$bb)]
    for (s in seq_len(nrow(scenarios))) {
      cs <- scenarios$service_cost[s]; cd <- scenarios$lost_day_cost[s]
      opt <- management_policy(cs + cb, cd, mu, sig, draws$tau, family)
      vals <- if (is.finite(opt$interval))
        management_loss(opt$interval, cs + cb, cd, mu, sig, draws$tau, family) else
        list(downtime = rep(1, length(mu)), loss = rep(cd, length(mu)))
      key <- data.frame(family, bb = p$bb, ft = p$ft, reg = p$reg,
        service_cost = cs, battery_cost = cb, lost_day_cost = cd)
      policies[[length(policies) + 1L]] <- cbind(key,
        interval = opt$interval, expected_loss = opt$loss,
        loss_low = cam_interval(vals$loss)["low"], loss_high = cam_interval(vals$loss)["high"],
        expected_downtime = mean(vals$downtime), mean_life = opt$mean_life,
        status = opt$status, support(opt$interval, p))
      for (T in c(90, 120, 150)) {
        v <- management_loss(T, cs + cb, cd, mu, sig, draws$tau, family)
        fixed[[length(fixed) + 1L]] <- cbind(key, interval = T,
          expected_loss = mean(v$loss), expected_downtime = mean(v$downtime),
          downtime_low = cam_interval(v$downtime)["low"], downtime_high = cam_interval(v$downtime)["high"],
          effort_inflation = T / mean(v$active), support(T, p))
      }
    }
    cat(family, p$bb, p$ft, "complete\n")
  }
}
policies <- do.call(rbind, policies)
fixed <- do.call(rbind, fixed)
write.csv(policies, file.path(out, "profile_policies.csv"), row.names = FALSE)
write.csv(fixed, file.path(out, "fixed_interval_costs.csv"), row.names = FALSE)
groups <- split(policies, interaction(policies$family, policies$service_cost, policies$lost_day_cost, drop = TRUE))
winners <- do.call(rbind, lapply(groups, function(g) {
  best <- min(g$expected_loss)
  z <- g[abs(g$expected_loss - best) < 1e-9, ]
  z$n_tied <- nrow(z)
  z
}))
write.csv(winners, file.path(out, "joint_policies.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "session-management.txt"))
cat("COMPLETED management synthesis\n")
