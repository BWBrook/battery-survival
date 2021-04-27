source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

tascam_dat <- get_data("config.yml") %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()
tascam_i_dat <- tascam_dat %>% 
	filter(ft == "i", bb %in% c("Procell", "Varta")) %>% droplevels()

cox_tascam_i <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = tascam_i_dat)
cox_tascam_i_df <- get_cox_df(cox_tascam_i, tascam_i_dat, cols = c(1, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

km_tascam_i <- survfit(Surv(rd, bdead) ~ bb, data = tascam_i_dat)

ggsurvplot(fit = km_tascam_i, color = "bb", conf.int = FALSE, legend.title = "Battery")

ggsurvplot(fit = cox_tascam_i_df, color = "bb", conf.int = FALSE, legend.title = "Battery")  +
	facet_grid(fpd~dpd)

ggforest(cox_tascam_i, data = tascam_i_dat)

