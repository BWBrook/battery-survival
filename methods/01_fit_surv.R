# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 8)

run_fit <- function(configfile) {
    conf <- config::get(file = configfile)
    dat <- get_data(conf)
    out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
    km_out <- paste0(out_pre, "km.rds")
    cox_out <- paste0(out_pre, "cox.rds") 
    cox_df_out <- paste0(out_pre, "cox_df.rds")

    if(!file.exists(km_out)) {
        km_fit <- survfit(formula(paste(conf$lhs, conf$basic)), data = dat)
        write_rds(km_fit, km_out)
    }

    if(conf$basic != "1") {
        if(!file.exists(cox_out)) {
            cox_fit <- coxph(formula(paste(conf$lhs, conf$form)), data = dat)
            cox_df <- get_cox_df(cox_fit, dat, cols = conf$colv)
            write_rds(cox_fit, cox_out)
            write_rds(cox_df, cox_df_out)   
        }
    }
}

run_fit("config.yml")