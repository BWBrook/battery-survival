source("00_dependencies.R")
source("00_data.R")
source("00_df_funcs.R")

ne_dat <- get_data("config.yml") %>%
	filter(reg == "ne") %>% droplevels()

km_ne <- survfit(Surv(rd, bdead) ~ seas, data = ne_dat)