testthat::test_that("apply_exclusions drops active camera and run exclusions", {
  dat <- tibble::tibble(
    run_id = 1:3,
    camera = c("a", "b", "c"),
    rd = c(10, 10, 10),
    bok = c(1L, 1L, 0L),
    ti = c(1, 1, 1),
    fi = c(0, 0, 0),
    ft = c("w", "w", "i"),
    bt = c("lithium", "alkaline", "lithium"),
    bb = c("varta", "procell", "energizer"),
    seas = c("summer", "winter", "spring"),
    reg = c("sw", "sw", "ne")
  )

  ex <- tibble::tibble(
    scope = c("camera", "record"),
    id = c("a", "3"),
    reason_code = c("bad_camera", "known_issue"),
    reason_detail = c("camera issue", "record issue"),
    active = c(TRUE, TRUE),
    source = c("test", "test")
  )

  result <- apply_exclusions(dat, ex)
  testthat::expect_equal(nrow(result$data), 1)
  testthat::expect_true(all(result$data$camera == "b"))
  testthat::expect_equal(nrow(result$log), 2)
})
