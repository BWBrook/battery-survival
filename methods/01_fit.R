# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)
conf <- config::get(file = conffile)

sw_dat <- get_data(conf) %>%
	filter(reg == "sw") %>% droplevels()
km_sw <- survfit(Surv(rd, bdead) ~ bb, data = sw_dat)
cox_sw <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = sw_dat)
cox_sw_int <- coxph(Surv(rd, bdead) ~ bb + bb*fpd + bb*dpd, data = sw_dat) 

cox_sw_df <- get_cox_df(cox_sw, sw_dat, cols = c(1, 3, 4)) %>%
	mutate(fpd = factor(fpd), dpd = factor(dpd))

mod_sw <- stan_surv(Surv(rd, bdead) ~ bb + fpd + dpd, data = sw_dat) 
mod_sw_weibull  <- update(mod_sw, basehaz = "weibull")
mod_sw_bspline  <- update(mod_sw, basehaz = "bs")
mod_sw_mspline1 <- update(mod_sw, basehaz = "ms")
mod_sw_mspline2 <- update(mod_sw, basehaz = "ms", basehaz_ops = list(df = 10))