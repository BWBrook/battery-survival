source("00_dependencies.R")
source("00_data.R")

battery_dat <- get_data("config.yml") 
cox_bat <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = battery_dat)

ggforest(cox_bat, data = battery_dat)