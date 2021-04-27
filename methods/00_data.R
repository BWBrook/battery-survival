source("00_dependencies.R")

get_data <- function(conffile, part = "ALL") {
	conf <- config::get(file = conffile)                            
	battery_dat <- readr::read_csv(conf$in_dat,
		col_types = conf$col_types) %>%
	mutate(bdead = as.integer(1 - bok),
		   bb = str_to_title(bb) %>% factor(),
		   fpd = (fi + 1) / rd,
		   dpd = (ti + 1) / rd) %>%
	filter(!(reg == "ne" & bb == "Procell")) # no Procell data in NE
	battery_dat
}