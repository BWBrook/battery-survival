testthat::test_that("derived outputs cannot overwrite sealed inputs, including through symlinks", {
  root <- tempfile("derived-guard-")
  input <- file.path(root, "sealed")
  dir.create(input, recursive = TRUE)
  sentinel <- file.path(input, "sentinel.txt")
  writeLines("unchanged", sentinel)
  alias <- file.path(root, "alias")
  file.symlink(input, alias)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  testthat::expect_silent(assert_derived_output_destination(input, file.path(root, "new"), protected = character()))
  for (out in c(input, file.path(input, "new"), root, file.path(alias, "new"))) {
    testthat::expect_error(assert_derived_output_destination(input, out, protected = character()), "overlaps sealed")
  }
  testthat::expect_identical(readLines(sentinel), "unchanged")
  testthat::expect_false(dir.exists(file.path(input, "new")))
})
