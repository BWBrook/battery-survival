source("00_dependencies.R")

zscore <- function(x)
	(x - mean(x)) / sd(x) # z-score normalization

get_data <- function(conffile) {
	conf <- config::get(file = conffile)                            
	battery_dat <- readr::read_csv(conf$in_dat,
		col_types = conf$col_types) %>%
	mutate(bdead = 1 - bok,
		   bb = str_to_title(bb) %>% factor(),
		   fpd = (fi + 1) / rd,
		   dpd = (ti + 1) / rd) %>%
	filter(!(reg == "ne" & bb == "Procell")) # no Procell data in NE
	#battery_dat$dpd <- zscore(log((battery_dat$ti-battery_dat$fi+1)/battery_dat$rd)) # derived predictor, day images per day (trigger rate), logged and normalised
	#battery_dat$fpd <- zscore(log((battery_dat$fi+1)/battery_dat$rd)) # derived predictor, flash images per day, logged and normalised
	battery_dat
}