source("00_dependencies.R")
source("00_data.R")

battery_dat <- get_data("config.yml") 
cox_bat <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = battery_dat)


varta_dat <- battery_dat %>% 
	filter(bb %in% c("Varta")) %>% 
	mutate(bb = fct_drop(bb))

procell_dat <- battery_dat %>% 
	filter(bb %in% c("Procell")) %>% 
	mutate(bb = fct_drop(bb))

both_dat <- battery_dat %>% 
	filter(bb %in% c("Varta", "Procell")) %>% 
	mutate(bb = fct_drop(bb))

varta_seas <- coxph(Surv(rd, bdead) ~ seas + fpd + dpd, data = varta_dat)
procell_seas <- coxph(Surv(rd, bdead) ~ seas + fpd + dpd, data = procell_dat)
both_seas <- coxph(Surv(rd, bdead) ~ bb + seas + fpd + dpd, data = both_dat)

bat_type <- coxph(Surv(rd, bdead) ~ bt + fpd + dpd, data = battery_dat)

varta_reg <- coxph(Surv(rd, bdead) ~ reg + fpd + dpd, data = both_dat)

plot_for <- ggforest(cox_bat, data = battery_dat)

plot_for_seas_v <- ggforest(varta_seas, data = varta_dat)
plot_for_seas_p <- ggforest(procell_seas, data = procell_dat)
plot_for_seas_b <- ggforest(both_seas, data = both_dat)

plot_for_bt <- ggforest(bat_type, data = battery_dat)

plot_for_reg <- ggforest(varta_reg, data = varta_dat)