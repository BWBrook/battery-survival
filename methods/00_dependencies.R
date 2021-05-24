# note when loading from github - if you are on a Mac you will probably need to install 
# clang and fortran before running this so you can compile R packages from source
if(!require("pacman")) install.packages("pacman")
pacman::p_load(scan("dependencies.txt", what = character(), quiet = TRUE),
			   character.only = TRUE)
pacman::p_load_gh(scan("dependencies_gh.txt", what = character(), quiet = TRUE))