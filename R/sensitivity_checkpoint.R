# Immutable identity for sensitivity-analysis output directories.
#
# A completed sensitivity run is a sealed set of inputs and fits.  The
# signature is deliberately stored outside the model subdirectories so that
# the runner and direct cam_fit_models() calls enforce the same contract.

checkpoint_signature_file <- function(output_dir) {
  file.path(output_dir, "checkpoint-signature.rds")
}

checkpoint_hash_raw <- function(raw) {
  path <- tempfile("sensitivity-signature-")
  on.exit(unlink(path), add = TRUE)
  con <- file(path, open = "wb")
  writeBin(raw, con)
  close(con)
  value <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  if (length(value) != 1L || !grepl("^[0-9a-f]{64}\\s", value)) {
    stop("Unable to calculate SHA-256 for sensitivity checkpoint signature",
         call. = FALSE)
  }
  sub("\\s+.*$", "", value)
}

checkpoint_hash_object <- function(object) {
  checkpoint_hash_raw(serialize(object, NULL, version = 2))
}

checkpoint_model_hash <- function(model_path) {
  if (!file.exists(model_path)) {
    stop("Stan model source is missing: ", model_path, call. = FALSE)
  }
  checkpoint_hash_raw(readBin(model_path, what = "raw", n = file.info(model_path)$size))
}

checkpoint_design_identity <- function(design) {
  required <- c("train", "formula", "centres", "columns", "brands", "cameras", "X")
  missing <- setdiff(required, names(design))
  if (length(missing)) {
    stop("Camera design is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  list(
    train = design$train,
    formula = paste(deparse(design$formula), collapse = " "),
    centres = unname(design$centres),
    columns = unname(design$columns),
    brands = unname(design$brands),
    cameras = unname(design$cameras),
    X = unname(design$X)
  )
}

checkpoint_config_identity <- function(cfg) {
  value <- cfg
  # The destination is an output location, rather than a fit identity.  This
  # permits a compatible sealed run to be copied to a new output directory.
  value$output_dir <- NULL
  value
}

checkpoint_function_identity <- function(name) {
  fn <- get(name, envir = .GlobalEnv)
  if (!is.function(fn)) {
    stop("Sensitivity fit function is unavailable: ", name, call. = FALSE)
  }
  list(name = name, formals = formals(fn), body = deparse(body(fn)))
}

checkpoint_expected_signature <- function(design, cfg,
                                          model_path = "models/stan/camera_aft.stan") {
  model_path <- normalizePath(model_path, winslash = "/", mustWork = FALSE)
  identity <- list(
    version = 1L,
    design = checkpoint_design_identity(design),
    config = checkpoint_config_identity(cfg),
    fit_functions = lapply(
      c("cam_stan_data", "cam_fit_models", "sa_aft_formula",
        "cam_design", "cam_new_design"),
      checkpoint_function_identity
    ),
    stan_model = list(path = model_path, sha256 = checkpoint_model_hash(model_path))
  )
  list(version = identity$version, sha256 = checkpoint_hash_object(identity),
       identity = identity)
}

checkpoint_guard <- function(design, cfg, output_dir,
                             model_path = "models/stan/camera_aft.stan") {
  expected <- checkpoint_expected_signature(design, cfg, model_path)
  signature_file <- checkpoint_signature_file(output_dir)

  if (file.exists(signature_file)) {
    recorded <- tryCatch(readRDS(signature_file), error = function(e) e)
    if (inherits(recorded, "error") ||
        !identical(recorded$version, expected$version) ||
        !identical(recorded$sha256, expected$sha256)) {
      stop("Sensitivity output checkpoint signature mismatch; use a new output directory",
           call. = FALSE)
    }
    return(invisible(expected))
  }

  existing <- if (dir.exists(output_dir)) {
    list.files(output_dir, all.files = TRUE, recursive = TRUE, no.. = TRUE)
  } else character()
  if (length(existing)) {
    stop("Existing sensitivity output lacks checkpoint signature; use a new output directory",
         call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(expected, signature_file)
  invisible(expected)
}
