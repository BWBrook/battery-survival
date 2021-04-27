source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

tascam_dat <- get_data("config.yml") %>%
	filter(reg %in% c("se", "nw", "ct", "wt")) %>% droplevels()
tascam_i_dat <- tascam_dat %>% 
	filter(ft == "i", bb %in% c("Procell", "Varta"))
tascam_w_dat <- tascam_dat %>%
	filter(ft == "w")


km_tascam_i <- survfit(Surv(rd, bdead) ~ bb, data = tascam_i_dat)
km_tascam_w <- survfit(Surv(rd, bdead) ~ bb + seas, data = tascam_w_dat)