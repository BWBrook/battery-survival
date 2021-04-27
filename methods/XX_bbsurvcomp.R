source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

sw_dat <- get_data("config.yml") %>%
	filter(reg == "sw") %>% droplevels()
km_sw <- survfit(Surv(rd, bdead) ~ bb, data = sw_dat)
cox_sw <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = sw_dat)
cox_sw_int <- coxph(Surv(rd, bdead) ~ bb + bb*fpd + bb*dpd, data = sw_dat) 

cox_sw_df <- get_cox_df(cox_sw, sw_dat, cols = c(1, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

ggsurvplot(fit = km_sw, color = "bb", conf.int = FALSE, legend.title = "Battery Type")

ggsurvplot(fit = cox_sw_df, color = "bb", conf.int = FALSE, legend.title = "Battery Type")  +
	facet_grid(fpd~dpd)

ggforest(cox_sw, data = sw_dat)

# battery_dat <- get_data("config.yml") 

# km_bat <- survfit(Surv(rd, bdead) ~ bb, data = battery_dat)
# wb_bat <- survreg(Surv(rd, bdead) ~ bb, data = battery_dat)
# cox_bat <- coxph(Surv(rd, bdead) ~ bb, data = battery_dat)

# cox2_bat <- coxph(Surv(rd, bdead) ~ bb + fpd, data = battery_dat)
# cox3_bat <- coxph(Surv(rd, bdead) ~ bb + dpd, data = battery_dat)

# wb_df <- get_wb_df(wb_bat, battery_dat)
# cox_df <- get_cox_df(cox_bat, battery_dat)

# cox2_df <- get_cox_df(cox2_bat, battery_dat, cols = c(1, 3)) %>%
# 	mutate(fpd = factor(fpd))

# cox3_df <- get_cox_df(cox3_bat, battery_dat, cols = c(1, 4)) %>%
# 	mutate(dpd = factor(dpd))

# # ggsurvplot(fit = wb_df, color = "bb", legend.title = "Battery Type") 
# # ggsurvplot(fit = cox_df, color = "bb", legend.title = "Battery Type")

# plot_surv_svp <- ggsurvplot(fit = wb_df, color = "bb", linetype = "dashed", legend.title = "Battery Type") +
# 	geom_line(aes(x = time, y = surv, col = bb), size = 2, alpha = 0.5, data = cox_df) #+ 
# 	#ggtitle("Semi-parametric (COXPH) vs Parametric (Weibull) survival")

# plot_surv_svn <- ggsurvplot(fit = km_bat, color = "bb", legend.title = "Battery Type")$plot + 
# 	geom_line(aes(x = time, y = surv, col = bb), size = 2, alpha = 0.5, data = cox_df) #+ 
# 	##ggtitle("Semi-parametric (COXPH) vs Non-parametric (KM) survival")

# plot_surv_fpd <- ggsurvplot(fit = cox2_df, color = "bb", linetype = "fpd", conf.int = FALSE, legend.title = "Battery Type") +
# 	scale_linetype_manual(values = c("dotted", "dashed", "solid"))

# plot_surv_dpd <- ggsurvplot(fit = cox3_df, color = "bb", linetype = "dpd", conf.int = FALSE, legend.title = "Battery Type") +
# 	scale_linetype_manual(values = c("dotted", "dashed", "solid"))