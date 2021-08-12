# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw_wb")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

# get conf after setting env, if file changes update this function
get_conf <- function(conf_active, conf_file = "config.yml") {
	Sys.setenv(R_CONFIG_ACTIVE = conf_active)
	config::get(file = conf_file)
}

# load km.rds, cox.rds, cox_df.rds or stan.rds
get_survdat <- function(conf, type = "km.rds") {
	out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
	surv_out <- paste0(out_pre, type)
	surv_dat <- read_rds(surv_out)
	surv_dat
}

plot_km <- function(conf_active, color = "ft", conf.int = FALSE, legend.title = "Flash Type") {
	conf <<- get_conf(conf_active)
	dat <- get_data(conf)
	km_dat <- get_survdat(conf, type = "km.rds")
	km_plot <- ggsurvplot(fit = km_dat, data = dat, color = color, conf.int = conf.int, legend.title = legend.title)
	rm(conf, pos = ".GlobalEnv")
	km_plot
}

plot_cox <- function(conf_active, color = "ft", dpd = FALSE, seas = FALSE) {
	conf <- get_conf(conf_active)
	dat <- get_data(conf)
	cox_df <- get_survdat(conf, type = "cox_df.rds")
	coxplot <- ggsurvplot(fit = cox_df, palette = "Dark2", color = color, linetype = "fpd", conf.int = FALSE, legend.title = "Battery")  +
		scale_linetype_manual(values = c("dotted", "dashed", "solid"))
	if(dpd) coxplot <- coxplot + facet_grid(~dpd)
	if(seas) coxplot <- coxplot + facet_grid(~seas)
	coxplot
}

plot_cox_for <- function(conf_active) {
	conf <- get_conf(conf_active)
	dat <- get_data(conf)
	cox_dat <- get_survdat(conf, type = "cox.rds")
	ggforest(cox_dat, data = dat)
}
# km_dat <- get_survdat("tascam_v", type = "km.rds")
# cox_dat <- get_survdat("tascam_v", type = "cox.rds")
# cox_df <- get_survdat("tascam_v", type = "cox_df.rds")

# plot_tc_v_km <- ggsurvplot(fit = km_dat, color = "ft", conf.int = FALSE, legend.title = "Flash Type")

# plot_tc_v_km <- plot_km("tascam_v")
# plot_tc_v_cox <- plot_cox("tascam_v")

# plot_tc_v_cox <- ggsurvplot(fit = cox_df, palette = "Dark2", color = "ft", linetype = "fpd", conf.int = FALSE, legend.title = "Battery")  +
# 	facet_grid(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

# plot_tc_v_for <- ggforest(cox_dat, data = dat)

# tc_wb_dat <- get_survdat("tascam_v_wb", type = "stan.rds")
# tc_bs_5_dat <- get_survdat("tascam_v_bs_5", type = "stan.rds")
# tc_bs_7_dat <- get_survdat("tascam_v_bs_7", type = "stan.rds")
# tc_ms_5_dat <- get_survdat("tascam_v_ms_5", type = "stan.rds")
# tc_ms_7_dat <- get_survdat("tascam_v_ms_7", type = "stan.rds")

# # # LOO

# loo_wb <- loo(tc_wb_dat)
# loo_bs_5 <- loo(tc_bs_5_dat)
# loo_bs_7 <- loo(tc_bs_7_dat)
# loo_ms_5 <- loo(tc_ms_5_dat)
# loo_ms_7 <- loo(tc_ms_7_dat)

# Model Comparison

# loo_comp <- loo_compare(loo_wb, loo_bs_5, loo_bs_7, loo_ms_5, loo_ms_7)

# loo_map_tas %>% loo_compare()
get_loo_dat <- function(loo_comp) {
	loo_comp %>%
		as_tibble(rownames = "mod") %>%
        mutate(mod = as_factor(mod)) 
}


model_comp <- function(loo_comp) {
	loo_dat <- get_loo_dat(loo_comp)
	loo_dat %>%
		ggplot() +
			geom_errorbar(aes(y = mod, 
							  x = elpd_diff,
							  xmin = elpd_diff - se_diff,
							  xmax = elpd_diff + se_diff)) +
			geom_point(aes(y = mod,
						   x = elpd_diff)) +
			theme_minimal()
}

# mod_plot <- model_comp(loo_comp)


get_post_surv <- function(conf_active, vcols = c(3, 4, 5)) {
	conf <- get_conf(conf_active)
	dat <- get_data(conf)
	new_dat <- get_newdat(dat, cols = vcols)
	surv_dat <- get_survdat(conf, type = "stan.rds")
	post_surv <- rstanarm::posterior_survfit(surv_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
	#post_surv <- post_surv %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])
	post_surv
}

plot_stan <- function(conf_stan) {
	post_surv <- get_post_surv(conf_stan)
	stan_plot <- ggplot() + 
		geom_line(aes(x = time, y = median, color = ft),
			data = post_surv %>% filter(fpd == 0.7, dpd == 1.44)) +
		geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
			data = post_surv %>% filter(fpd == 0.7, dpd == 1.44)) +
		guides(fill = "none") + 
		theme_minimal()
	stan_plot
}

# Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_wb")
# conf <- config::get(file = "config.yml")
# new_dat <- get_newdat(dat, cols = c(3, 4, 5))

# ps_tcv_wb <- rstanarm::posterior_survfit(tc_wb_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
# ps_tcv_wb <- ps_tcv_wb %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

# ps_tcv_bs5 <- rstanarm::posterior_survfit(tc_bs_5_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
# ps_tcv_bs5 <- ps_tcv_bs5 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

# ps_tcv_bs7 <- rstanarm::posterior_survfit(tc_bs_7_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
# ps_tcv_bs7 <- ps_tcv_bs7 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

# ps_tcv_ms5 <- rstanarm::posterior_survfit(tc_ms_5_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
# ps_tcv_ms5 <- ps_tcv_ms5 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

# ps_tcv_ms7 <- rstanarm::posterior_survfit(tc_ms_7_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
# ps_tcv_ms7 <- ps_tcv_ms7 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])


# plot_wb <- plot_tc_v_km$plot + 
#     geom_line(aes(x = time, y = median, color = ft),
#     	data = ps_tcv_wb %>% filter(fpd == 0.7, dpd == 1.44)) +
#     geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
#     	data = ps_tcv_wb %>% filter(fpd == 0.7, dpd == 1.44)) +
#     guides(fill = "none")

# plot_bs5 <- plot_tc_v_km$plot + 
#     geom_line(aes(x = time, y = median, color = ft),
#     	data = ps_tcv_bs5 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
#     	data = ps_tcv_bs5 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     guides(fill = "none")

# plot_bs7 <- plot_tc_v_km$plot + 
#     geom_line(aes(x = time, y = median, color = ft),
#     	data = ps_tcv_bs7 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
#     	data = ps_tcv_bs7 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     guides(fill = "none")

# plot_ms5 <- plot_tc_v_km$plot + 
#     geom_line(aes(x = time, y = median, color = ft),
#     	data = ps_tcv_ms5 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
#     	data = ps_tcv_ms5 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     guides(fill = "none")

# plot_ms7 <- plot_tc_v_km$plot + 
#     geom_line(aes(x = time, y = median, color = ft),
#     	data = ps_tcv_ms7 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
#     	data = ps_tcv_ms7 %>% filter(fpd == 0.7, dpd == 1.44)) +
#     guides(fill = "none")


# seven_plot <- cowplot::plot_grid(plot_tc_v_for, mod_plot, plot_bs5, plot_bs7, plot_wb, plot_ms7, plot_ms5,
# 	labels = c("COX PH", "LOO", "BSpline 5df", "BSpline 7df", "Weibull", "MSpline 7df", "MSpline 5df"),
# 	hjust = -1,
# 	ncol = 2)

#panel_labels <- c('1' = "Maxell", '2' = "Ultra", '3' = "Varta")
# plot(ps_sw) + 
#   ggplot2::facet_wrap(~id, labeller = ggplot2::labeller(id = panel_labels))

# ps_tc_v %>% filter(dpd == 1.44) %>%
# 	ggplot(aes(x = time, y = median)) +
# 		geom_line(aes(color = ft)) +
# 		geom_ribbon(aes(ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2) +
# 		theme_minimal() + 
# 		facet_wrap(~fpd)