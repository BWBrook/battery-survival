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

plot_sw_km <- ggsurvplot(fit = km_sw, palette = "Dark2", color = "bb", conf.int = FALSE, legend.title = "Battery Type")

plot_sw_cox <- ggsurvplot(fit = cox_sw_df, palette = "Dark2", color = "bb", linetype = "fpd", conf.int = FALSE, legend.title = "Battery Type")  +
	facet_wrap(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

plot_sw_for <- ggforest(cox_sw, data = sw_dat)
