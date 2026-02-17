repo_root <- normalizePath(
  file.path(testthat::test_path(), "..", ".."),
  winslash = "/",
  mustWork = TRUE
)

r_dir <- file.path(repo_root, "R")
r_files <- sort(list.files(r_dir, pattern = "\\.R$", full.names = TRUE))

for (f in r_files) {
  source(f, local = .GlobalEnv)
}
