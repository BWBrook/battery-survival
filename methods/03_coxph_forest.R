source("00_dependencies.R")
source("00_data.R")

battery_dat <- get_data("config.yml") 
cox_bat <- coxph(Surv(rd, bdead) ~ bb + fpd + dpd, data = battery_dat)


varta_dat <- battery_dat %>% 
	filter(bb %in% c("varta")) %>% 
	mutate(bb = fct_drop(bb))

procell_dat <- battery_dat %>% 
	filter(bb %in% c("procell")) %>% 
	mutate(bb = fct_drop(bb))

both_dat <- battery_dat %>% 
	filter(bb %in% c("varta", "procell")) %>% 
	mutate(bb = fct_drop(bb))

varta_bat <- coxph(Surv(rd, bdead) ~ seas, data = varta_dat)
procell_bat <- coxph(Surv(rd, bdead) ~ seas, data = procell_dat)

both_bat <- coxph(Surv(rd, bdead) ~ bb + seas, data = both_dat)

ggforest(cox_bat, data = battery_dat)

ggforest(varta_bat, data = varta_dat)
ggforest(procell_bat, data = procell_dat)
ggforest(both_bat, data = both_dat)