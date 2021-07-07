# Variables are loaded from config.yml by setting environment. 
# Sys.setenv(R_CONFIG_ACTIVE = "sw_wb")
source("00_dependencies.R")
source("00_data.R")
source("00_functions.R")

# stupid way for now, will make pretty later

Sys.setenv(R_CONFIG_ACTIVE = "tascam_v")

conf <- config::get(file = "config.yml")
out_pre <- paste0(conf$out_dir, conf$run_date, "_", conf$name, "_") 
km_out <- paste0(out_pre, "km.rds")
cox_out <- paste0(out_pre, "cox.rds") 
cox_df_out <- paste0(out_pre, "cox_df.rds")

km_dat <- read_rds(km_out)
cox_dat <- read_rds(cox_out)
cox_df <- read_rds(cox_df_out)