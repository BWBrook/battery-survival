if(!require("pacman")) install.packages("pacman")
pacman::p_load(scan("dependencies.txt", what = character(), quiet = TRUE),
			   character.only = TRUE)