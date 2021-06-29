source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

options(mc.cores = 8)

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

mod_sw <- stan_surv(Surv(rd, bdead) ~ bb + fpd + dpd, data = sw_dat) 
mod_sw_exp      <- update(mod_sw, basehaz = "exp")
mod_sw_weibull  <- update(mod_sw, basehaz = "weibull")
mod_sw_gompertz <- update(mod_sw, basehaz = "gompertz")
mod_sw_bspline  <- update(mod_sw, basehaz = "bs")
mod_sw_mspline1 <- update(mod_sw, basehaz = "ms")
mod_sw_mspline2 <- update(mod_sw, basehaz = "ms", basehaz_ops = list(df = 10))

new_dat <- get_newdat(sw_dat, cols = c(1, 3, 4))
ps_sw <- posterior_survfit(mod_sw, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 600))
panel_labels <- c('1' = "Maxell", '2' = "Ultra", '3' = "Varta")
# plot(ps_sw) + 
#   ggplot2::facet_wrap(~id, labeller = ggplot2::labeller(id = panel_labels))

ps_sw <- ps_sw %>% mutate(bb = new_dat[id, 1], fpd = new_dat[id, 2], dpd = new_dat[id, 3])

ps_sw %>% 
	ggplot(aes(x = time, y = median)) +
		geom_line(aes(color = bb)) +
		geom_ribbon(aes(ymin = ci_lb, ymax = ci_ub, fill = bb), alpha = 0.2) +
		theme_minimal() + 
		facet_grid(fpd ~ dpd)

plot_sw_km$plot +
    geom_line(aes(x = time, y = median, color = bb),
    	data = ps_sw %>% filter(fpd == 1.3, dpd == 1.63)) +
    geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = bb), alpha = 0.2,
    	data = ps_sw %>% filter(fpd == 1.3, dpd == 1.63))