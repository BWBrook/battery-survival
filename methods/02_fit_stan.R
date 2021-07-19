# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw_wb")
source("00_dependencies.R")
source("00_dependencies_gh.R")
source("00_data.R")
source("00_functions.R")

options(mc.cores = 4)

print(normal())

fit_stan <- function(configfile) {
    conf <- config::get(file = configfile)
    dat <- get_data(conf) 
    out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
    stan_out <- paste0(out_pre, "stan.rds")
    if(is.null(conf$form)) form <- conf$basic
    else form <- conf$form

    if(!file.exists(stan_out)) {
        stanform <- formula(paste(conf$lhs, form))
        stan_fit <- rstanarm::stan_surv(stanform,
            basehaz = conf$haz,
            basehaz_ops = conf$opts,
            prior = conf$prior,
            data = dat,
            chains = conf$chains,
            cores = conf$cores,
            seed = conf$seed,
            iter = conf$iter) 
    write_rds(stan_fit, stan_out)
    }
}

fit_stan("config.yml")