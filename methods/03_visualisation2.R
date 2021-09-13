# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw_wb")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

# stupid way for now, will make pretty later

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v")

conf <- config::get(file = "config.yml")
dat <- get_data(conf)
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
km_out <- paste0(out_pre, "km.rds")
cox_out <- paste0(out_pre, "cox.rds") 
cox_df_out <- paste0(out_pre, "cox_df.rds")

km_dat <- read_rds(km_out)
cox_dat <- read_rds(cox_out)
cox_df <- read_rds(cox_df_out)


plot_tc_v_km <- ggsurvplot(fit = km_dat, color = "ft", conf.int = FALSE, legend.title = "Flash Type")

plot_tc_v_cox <- ggsurvplot(fit = cox_df, palette = "Dark2", color = "ft", linetype = "fpd", conf.int = FALSE, legend.title = "Battery")  +
	facet_grid(~dpd) + scale_linetype_manual(values = c("dotted", "dashed", "solid"))

plot_tc_v_for <- ggforest(cox_dat, data = dat)


Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_wb")
conf <- config::get(file = "config.yml")
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
stan_out <- paste0(out_pre, "stan.rds")
print(stan_out)
tc_wb_dat <- read_rds(stan_out)

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_bs_5")
conf <- config::get(file = "config.yml")
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
stan_out <- paste0(out_pre, "stan.rds")
print(stan_out)
tc_bs_5_dat <- read_rds(stan_out)

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_bs_7")
conf <- config::get(file = "config.yml")
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
stan_out <- paste0(out_pre, "stan.rds")
print(stan_out)
tc_bs_7_dat <- read_rds(stan_out)

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_ms_5")
conf <- config::get(file = "config.yml")
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
stan_out <- paste0(out_pre, "stan.rds")
print(stan_out)
tc_ms_5_dat <- read_rds(stan_out)

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_ms_7")
conf <- config::get(file = "config.yml")
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
stan_out <- paste0(out_pre, "stan.rds")
print(stan_out)
tc_ms_7_dat <- read_rds(stan_out)

# # # LOO

loo_wb <- loo(tc_wb_dat)
loo_bs_5 <- loo(tc_bs_5_dat)
loo_bs_7 <- loo(tc_bs_7_dat)
loo_ms_5 <- loo(tc_ms_5_dat)
loo_ms_7 <- loo(tc_ms_7_dat)

# Model Comparison

loo_comp <- loo_compare(loo_wb, loo_bs_5, loo_bs_7, loo_ms_5, loo_ms_7)

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

mod_plot <- model_comp(loo_comp)

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v_wb")
conf <- config::get(file = "config.yml")
new_dat <- get_newdat(dat, cols = c(3, 4, 5))

ps_tcv_wb <- rstanarm::posterior_survfit(tc_wb_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
ps_tcv_wb <- ps_tcv_wb %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

ps_tcv_bs5 <- rstanarm::posterior_survfit(tc_bs_5_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
ps_tcv_bs5 <- ps_tcv_bs5 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

ps_tcv_bs7 <- rstanarm::posterior_survfit(tc_bs_7_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
ps_tcv_bs7 <- ps_tcv_bs7 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

ps_tcv_ms5 <- rstanarm::posterior_survfit(tc_ms_5_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
ps_tcv_ms5 <- ps_tcv_ms5 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])

ps_tcv_ms7 <- rstanarm::posterior_survfit(tc_ms_7_dat, newdata = new_dat, times = 0, extrapolate = TRUE, control = list(edist = 400))
ps_tcv_ms7 <- ps_tcv_ms7 %>% mutate(fpd = new_dat[id, 1], dpd = new_dat[id, 2], ft = new_dat[id, 3])


plot_wb <- plot_tc_v_km$plot + 
    geom_line(aes(x = time, y = median, color = ft),
    	data = ps_tcv_wb %>% filter(fpd == 0.7, dpd == 1.44)) +
    geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
    	data = ps_tcv_wb %>% filter(fpd == 0.7, dpd == 1.44)) +
    guides(fill = "none")

plot_bs5 <- plot_tc_v_km$plot + 
    geom_line(aes(x = time, y = median, color = ft),
    	data = ps_tcv_bs5 %>% filter(fpd == 0.7, dpd == 1.44)) +
    geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
    	data = ps_tcv_bs5 %>% filter(fpd == 0.7, dpd == 1.44)) +
    guides(fill = "none")

plot_bs7 <- plot_tc_v_km$plot + 
    geom_line(aes(x = time, y = median, color = ft),
    	data = ps_tcv_bs7 %>% filter(fpd == 0.7, dpd == 1.44)) +
    geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
    	data = ps_tcv_bs7 %>% filter(fpd == 0.7, dpd == 1.44)) +
    guides(fill = "none")

plot_ms5 <- plot_tc_v_km$plot + 
    geom_line(aes(x = time, y = median, color = ft),
    	data = ps_tcv_ms5 %>% filter(fpd == 0.7, dpd == 1.44)) +
    geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
    	data = ps_tcv_ms5 %>% filter(fpd == 0.7, dpd == 1.44)) +
    guides(fill = "none")

plot_ms7 <- plot_tc_v_km$plot + 
    geom_line(aes(x = time, y = median, color = ft),
    	data = ps_tcv_ms7 %>% filter(fpd == 0.7, dpd == 1.44)) +
    geom_ribbon(aes(x = time, y = median, ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2,
    	data = ps_tcv_ms7 %>% filter(fpd == 0.7, dpd == 1.44)) +
    guides(fill = "none")


seven_plot <- cowplot::plot_grid(plot_tc_v_for, mod_plot, plot_bs5, plot_bs7, plot_wb, plot_ms7, plot_ms5,
	labels = c("COX PH", "LOO", "BSpline 5df", "BSpline 7df", "Weibull", "MSpline 7df", "MSpline 5df"),
	hjust = -1,
	ncol = 2)

#panel_labels <- c('1' = "Maxell", '2' = "Ultra", '3' = "Varta")
# plot(ps_sw) + 
#   ggplot2::facet_wrap(~id, labeller = ggplot2::labeller(id = panel_labels))

# ps_tc_v %>% filter(dpd == 1.44) %>%
# 	ggplot(aes(x = time, y = median)) +
# 		geom_line(aes(color = ft)) +
# 		geom_ribbon(aes(ymin = ci_lb, ymax = ci_ub, fill = ft), alpha = 0.2) +
# 		theme_minimal() + 
# 		facet_wrap(~fpd)