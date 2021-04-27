source("00_dependencies.R")
source("00_data.R")

                            
sw_dat <- get_data("config.yml") %>%
	filter(reg == "sw") %>% droplevels()
ne_dat <- get_data("config.yml") %>%
	filter(reg == "se") %>% droplevels()
tascam_dat <- get_data("config.yml") %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()


tab_ft <- table(battery_dat$bb, battery_dat$ft)
tab_bt <- table(battery_dat$bb, battery_dat$bt)
tab_seas <- table(battery_dat$bb, battery_dat$seas)
tab_reg <- table(battery_dat$bb, battery_dat$reg)