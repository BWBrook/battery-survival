# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw_wb")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

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