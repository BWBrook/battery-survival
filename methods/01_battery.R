source("00_dependencies.R")
source("00_data.R")

                            
battery_dat <- get_data("config.yml") 
surv <- seq(.99, .01, by = -.01)
km_bat <- survfit(Surv(rd, bdead) ~ bb, data = battery_dat)
wb_bat <- survreg(Surv(rd, bdead) ~ bb + fpd, data = battery_dat)
cox_bat <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = battery_dat)

newdat <- expand.grid(
	bb = levels(battery_dat$bb),
	#seas = levels(battery_dat$seas),
	fpd = quantile(battery_dat$fpd, probs = c(0.25, 0.5, 0.75)))


t <- predict(wb_bat, type = "quantile", p = 1 - surv, newdata = newdat)
surv_wb_wide <- cbind(newdat, t)
surv_wb <- surv_wb_wide %>% 
	pivot_longer(-c(bb, fpd), names_to = "surv_id", values_to = "time") %>%
	mutate(surv_id = factor(surv_id, levels = seq(1:99))) %>%
	arrange(surv_id)
surv_wb$surv <- surv[as.numeric(surv_wb$surv_id)]
surv_wb[, c("upper", "lower", "std.err", "strata")] <- NA
surv_wb <- as.data.frame(surv_wb)

cox_sf <- survfit(cox_bat, data = battery_dat, newdata = newdat, conf.type = "none")
surv_cox0 <- surv_summary(cox_sf)
surv_cox <- cbind(surv_cox0, newdat[as.character(surv_cox0$strata), ]) %>%
	mutate(fpd = factor(fpd))

battery_dat %>% ggplot(aes(x = rd, y = fpd, color = bdead)) + geom_point() + facet_wrap(~bb)

battery_dat %>% ggplot(aes(x = reg, y = bb)) + geom_jitter()

ggsurvplot(fit = km_bat, conf.int = FALSE, legend.title = NULL, color = "bb", linetype = "fpd")
ggsurvplot_df(fit = surv_wb, conf.int = FALSE, legend.title = NULL, color = "bb", linetype = "dpd") + scale_color_brewer(palette = "Blues")
ggsurvplot_df(surv_cox, color = "bb", linetype = "dpd", legend.title = NULL, censor = FALSE) + scale_linetype_manual(values = c("solid", "dashed", "dotted", "twodash"))
