source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)

ne_dat <- get_data("config.yml") %>%
	filter(reg == "ne") %>% droplevels()

km_ne <- survfit(Surv(rd, bdead) ~ seas, data = ne_dat)

cox_ne <- coxph(Surv(rd, bdead) ~ seas + fpd + dpd, data = ne_dat)
cox_ne_df <- get_cox_df(cox_ne, ne_dat, cols = c(2, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

plot_ne_km <- ggsurvplot(fit = km_ne, palette = "Dark2", color = "seas", conf.int = FALSE, legend.title = "Season")

plot_ne_cox <- ggsurvplot(fit = cox_ne_df, palette = "Dark2", color = "seas", linetype = "fpd", conf.int = FALSE, legend.title = "Season")  +
	facet_wrap(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

plot_ne_for <- ggforest(cox_ne, data = ne_dat)

stan_ne <- stan_surv(Surv(rd, bdead) ~ seas + fpd + dpd, data = ne_dat) 
new_dat <- get_newdat(ne_dat, cols = c(2, 3, 4))
ps_ne <- posterior_survfit(stan_ne, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 600))
#panel_labels <- c('1' = "Maxell", '2' = "Ultra", '3' = "Varta")
# plot(ps_sw) + 
#   ggplot2::facet_wrap(~id, labeller = ggplot2::labeller(id = panel_labels))

ps_ne <- ps_ne %>% mutate(seas = new_dat[id, 1], fpd = new_dat[id, 2], dpd = new_dat[id, 3])

ps_ne %>% 
	ggplot(aes(x = time, y = median)) +
		geom_line(aes(color = seas)) +
		geom_ribbon(aes(ymin = ci_lb, ymax = ci_ub, fill = seas), alpha = 0.2) +
		theme_minimal() + 
		facet_grid(fpd ~ dpd)