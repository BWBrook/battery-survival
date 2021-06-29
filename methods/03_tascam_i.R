source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

options(mc.cores = 8)

tascam_dat <- get_data("config.yml") %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()
tascam_i_dat <- tascam_dat %>% 
	filter(ft == "i", bb %in% c("Procell", "Varta")) %>% droplevels()

cox_tascam_i <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = tascam_i_dat)
cox_tascam_i_df <- get_cox_df(cox_tascam_i, tascam_i_dat, cols = c(1, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

km_tascam_i <- survfit(Surv(rd, bdead) ~ bb, data = tascam_i_dat)

plot_tc_i_km <- ggsurvplot(fit = km_tascam_i, palette = "Dark2", color = "bb", conf.int = FALSE, legend.title = "Battery")

plot_tc_i_cox <- ggsurvplot(fit = cox_tascam_i_df, palette = "Dark2", color = "bb", linetype = "fpd", conf.int = FALSE, legend.title = "Battery")  +
	facet_wrap(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

plot_tc_i_for <- ggforest(cox_tascam_i, data = tascam_i_dat)

stan_tc_i <- stan_surv(Surv(rd, bdead) ~ bb + fpd + dpd, data = tascam_i_dat) 
new_dat <- get_newdat(tascam_i_dat, cols = c(1, 3, 4))
ps_tascam_i <- posterior_survfit(stan_tascam_i, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 600))
