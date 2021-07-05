# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw")
source("00_dependencies.R")
source("00_dependencies_gh.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)
conf <- config::get(file = "config.yml")

dat <- get_data(conf) 

bayes_fit <- rstanarm::stan_surv(formula(paste(conf$lhs, conf$form)),
    basehaz = conf$haz,
    data = dat) 
bayes_fit_weibull  <- update(bayes_fit, basehaz = "weibull")
bayes_fit_bspline  <- update(bayes_fit, basehaz = "bs")
bayes_fit_mspline1 <- update(bayes_fit, basehaz = "ms")
bayes_fit_mspline2 <- update(bayes_fit, basehaz = "ms", basehaz_ops = list(df = 10))