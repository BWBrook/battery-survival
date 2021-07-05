# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)
conf <- config::get(file = "config.yml")

dat <- get_data(conf) 
km_fit <- survfit(formula(paste(conf$lhs, conf$basic)), data = dat)
cox_fit <- coxph(formula(paste(conf$lhs, conf$form)), data = dat)
cox_df <- get_cox_df(cox_fit, dat, cols = conf$colv) 
