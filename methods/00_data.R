source("00_dependencies.R")

get_data <- function(conf) {                           
	battery_dat <- readr::read_csv(conf$in_dat,
		col_types = conf$col_types) %>%
	mutate(bdead = as.integer(1 - bok),
		   bb = str_to_title(bb) %>% factor(),
		   fpd = (fi + 1) / rd,
		   dpd = (ti + 1) / rd) %>%
	filter(!(reg == "ne" & bb == "Procell")) %>% # no Procell data in NE
	filter(grepl(conf$region, reg), grepl(conf$ftype, ft), grepl(conf$btype, bb)) %>%
	droplevels() 
	battery_dat
}