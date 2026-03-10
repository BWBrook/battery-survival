if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

if (file.exists("renv.lock")) {
  options(renv.config.pak.enabled = FALSE)
  source("renv/activate.R")
  renv::restore(prompt = FALSE)
} else {
  message("No renv.lock present yet. Run `just lock` after dependencies are installed.")
}
