source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)
conf <- config::get(file = conffile)

tascam_dat <- get_data(conf) %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()
tascam_w_dat <- tascam_dat %>%
	filter(ft == "w") %>% droplevels()

km_tascam_w <- survfit(Surv(rd, bdead) ~ bb, data = tascam_w_dat)

cox_tascam_w <- coxph(Surv(rd, bdead) ~ bb + seas + fpd + dpd, data = tascam_w_dat)
cox_tascam_w_df <- get_cox_df(cox_tascam_w, tascam_w_dat, cols = c(1, 2, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

cox_tascam_w_i <- coxph(Surv(rd, bdead) ~ bb + seas + fpd + dpd + bt*seas, data = tascam_w_dat)

cox_tascam_w_seas <- coxph(Surv(rd, bdead) ~ bb + seas, data = tascam_w_dat)
cox_tascam_w_seas_df <- get_cox_df(cox_tascam_w_seas, tascam_w_dat, cols = c(1, 2))

cox_tascam_w_pd <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = tascam_w_dat)
cox_tascam_w_pd_df <- get_cox_df(cox_tascam_w_pd, tascam_w_dat, cols = c(1, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

plot_tc_w_km <- ggsurvplot(fit = km_tascam_w, palette = "Dark2", color = "bb", conf.int = FALSE, legend.title = "Battery Type") 

plot_tc_w_pd_cox <- ggsurvplot(fit = cox_tascam_w_pd_df, palette = "Dark2", color = "bb", linetype = "fpd", conf.int = FALSE, legend.title = "Battery")  +
	facet_grid(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

plot_tc_w_seas_cox <- ggsurvplot(fit = cox_tascam_w_seas_df, palette = "Dark2", color = "bb", conf.int = TRUE, legend.title = "Battery")  +
	facet_grid(~seas)

plot_tc_w_for <- ggforest(cox_tascam_w, data = tascam_w_dat)
