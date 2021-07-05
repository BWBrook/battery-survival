source("00_dependencies.R")

get_newdat <- function(battery_dat, cols = 1) {
	var_list <- list(
		bb = levels(battery_dat$bb),
		seas = levels(battery_dat$seas),
		fpd = battery_dat$fpd %>% quantile(probs = c(0.05, 0.5, 0.95)) %>% round(2),
		dpd = battery_dat$dpd %>% quantile(probs = c(0.05, 0.5, 0.95)) %>% round(2),
		ft = levels(battery_dat$ft)
	)
	newdat <- expand.grid(var_list[cols])
	newdat
}

get_surv <- function() {
	surv <- seq(.99, .01, by = -.01)
}

# does not support multiple cols yet
get_wb_df <- function(wb_bat, battery_dat) {
	newdat <- get_newdat(battery_dat)
	surv <- get_surv()
	t <- predict(wb_bat, type = "quantile", p = 1 - surv, newdata = newdat)
	surv_wb_wide <- cbind(newdat, t)
	surv_wb <- surv_wb_wide %>% 
		pivot_longer(-c(bb), names_to = "surv_id", values_to = "time") %>%
		mutate(surv_id = factor(surv_id, levels = seq(1:99))) %>%
		arrange(surv_id)
	surv_wb$surv <- surv[as.numeric(surv_wb$surv_id)]
	surv_wb[, c("upper", "lower", "std.err", "strata")] <- NA
	surv_wb <- as.data.frame(surv_wb)
	surv_wb
}

get_cox_df <- function(cox_bat, battery_dat, cols = 1) {
	newdat <- get_newdat(battery_dat, cols)
	cox_sf <- survfit(cox_bat, data = battery_dat, newdata = newdat, conf.type = "plain")
	surv_cox0 <- surv_summary(cox_sf)
	if(ncol(get_newdat(battery_dat, cols)) == 1) surv_cox <- cbind(surv_cox0, bb = newdat[as.character(surv_cox0$strata), ])
	else surv_cox <- cbind(surv_cox0, newdat[as.character(surv_cox0$strata), ]) 
	if("fpd" %in% names(surv_cox)) surv_cox <- surv_cox %>% mutate(fpd = factor(fpd))
	if("dpd" %in% names(surv_cox)) surv_cox <- surv_cox %>% mutate(dpd = factor(dpd))
	surv_cox
}