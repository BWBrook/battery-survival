source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

tascam_dat <- get_data("config.yml") %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()
tascam_w_dat <- tascam_dat %>%
	filter(ft == "w") %>% droplevels()

km_tascam_w <- survfit(Surv(rd, bdead) ~ bb + seas, data = tascam_w_dat)

cox_tascam_w <- coxph(Surv(rd, bdead) ~ bb + seas + fpd + dpd, data = tascam_w_dat)
cox_tascam_w_df <- get_cox_df(cox_tascam_w, tascam_w_dat, cols = c(1, 2, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

ggsurvplot(fit = km_tascam_w, color = "bb", linetype = "seas", conf.int = FALSE, legend.title = "Battery")

ggsurvplot(fit = cox_tascam_w_df, color = "bb", linetype = "seas", conf.int = FALSE, legend.title = "Battery")  +
	facet_grid(fpd~dpd)

ggforest(cox_tascam_w, data = tascam_w_dat)
