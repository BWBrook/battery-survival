source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)
conf <- config::get(file = conffile)

tascam_dat <- get_data(conf) %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()
tascam_v_dat <- tascam_dat %>%
	filter(bb == "Varta") %>% droplevels()

km_tascam_v <- survfit(Surv(rd, bdead) ~ ft, data = tascam_v_dat)

plot_tc_v_km <- ggsurvplot(fit = km_tascam_v, palette = "Dark2", color = "ft", conf.int = FALSE, legend.title = "Flash Type")

cox_tascam_v <- coxph(Surv(rd, bdead) ~ ft*fpd + dpd, data = tascam_v_dat)
cox_tascam_v_df <- get_cox_df(cox_tascam_v, tascam_v_dat, cols = c(3, 4, 5)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd)) 

plot_tc_v_cox <- ggsurvplot(fit = cox_tascam_v_df, palette = "Dark2", color = "ft", linetype = "fpd", conf.int = FALSE, legend.title = "Battery")  +
	facet_grid(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

plot_tc_v_for <- ggforest(cox_tascam_v, data = tascam_v_dat)