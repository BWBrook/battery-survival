source("00_dependencies.R")
source("00_data.R")

                            
battery_dat <- get_data("config.yml") 

tab_ft <- table(battery_dat$bb, battery_dat$ft)
tab_bt <- table(battery_dat$bb, battery_dat$bt)
tab_seas <- table(battery_dat$bb, battery_dat$seas)
tab_reg <- table(battery_dat$bb, battery_dat$reg)