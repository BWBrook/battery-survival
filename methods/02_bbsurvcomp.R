source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")
                            
battery_dat <- get_data("config.yml") 

km_bat <- survfit(Surv(rd, bdead) ~ bb, data = battery_dat)
wb_bat <- survreg(Surv(rd, bdead) ~ bb, data = battery_dat)
cox_bat <- coxph(Surv(rd, bdead) ~ bb, data = battery_dat)

wb_df <- get_wb_df(wb_bat, battery_dat)
cox_df <- get_cox_df(cox_bat, battery_dat)

ggsurvplot(fit = wb_df, color = "bb", legend.title = "Battery Type") 
ggsurvplot(fit = cox_df, color = "bb", legend.title = "Battery Type")

ggsurvplot(fit = wb_df, color = "bb", linetype = "dashed", legend.title = "Battery Type") +
	geom_line(aes(x = time, y = surv, col = bb), size = 2, alpha = 0.5, data = cox_df) + 
	ggtitle("Semi-parametric (COXPH) vs Parametric (Weibull) survival")

ggsurvplot(fit = km_bat, color = "bb", legend.title = "Battery Type")$plot + 
	geom_line(aes(x = time, y = surv, col = bb), size = 2, alpha = 0.5, data = cox_df) + 
	ggtitle("Semi-parametric (COXPH) vs Non-parametric (KM) survival")