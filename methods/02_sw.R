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
