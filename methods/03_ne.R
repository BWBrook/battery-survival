source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

ne_dat <- get_data("config.yml") %>%
	filter(reg == "ne") %>% droplevels()

km_ne <- survfit(Surv(rd, bdead) ~ seas, data = ne_dat)

cox_ne <- coxph(Surv(rd, bdead) ~ seas + fpd + dpd, data = ne_dat)
cox_ne_df <- get_cox_df(cox_ne, ne_dat, cols = c(2, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

ggsurvplot(fit = km_ne, color = "seas", conf.int = FALSE, legend.title = "Season")

ggsurvplot(fit = cox_ne_df, color = "seas", conf.int = FALSE, legend.title = "Season")  +
	facet_grid(fpd~dpd)

ggforest(cox_ne, data = ne_dat)
