#!/usr/bin/env Rscript

# Descriptive effect summaries for the manuscript integration pass.
#
# This script deliberately reads the sealed 2026-09-17 sensitivity cohort and
# saved baseline model summaries. It does not refit a model or alter raw data.
# KM intervals below are ordinary pointwise intervals from survival::survfit;
# they do not account for repeated camera identifiers.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/summarise_manuscript_effects.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
setwd(project_root)

if (!requireNamespace("survival", quietly = TRUE)) stop("Package `survival` is required.")

source_dir <- file.path("outputs", "sensitivity", "2026-09-17")
out_dir <- file.path("outputs", "management", "2026-09-18", "field_effects")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cohorts <- readRDS(file.path(source_dir, "cohorts.rds"))
train <- as.data.frame(cohorts$train)
sw <- as.data.frame(cohorts$sw)
cox <- read.csv(file.path("outputs", "tables", "cox_coefficients.csv"),
                stringsAsFactors = FALSE, check.names = FALSE)
pop_files <- c(
  weibull_independent = "weibull_independent_parameters.csv",
  weibull_camera = "weibull_camera_parameters.csv",
  loglogistic_independent = "loglogistic_independent_parameters.csv",
  loglogistic_camera = "loglogistic_camera_parameters.csv"
)

write_csv <- function(x, name) {
  write.csv(x, file.path(out_dir, name), row.names = FALSE, quote = TRUE)
}

# A. Brand/chemistry composition in the canonical training cohort.
chemistry <- as.data.frame(with(train, table(bb = as.character(bb),
                                             chemistry = as.character(bt))),
                           stringsAsFactors = FALSE)
names(chemistry)[3] <- "rows"
chemistry <- chemistry[chemistry$rows > 0, , drop = FALSE]
write_csv(chemistry, "brand_chemistry_counts.csv")

# B. Camera overlap: 428 of 489 training-camera identifiers have >1 brand.
camera_brand_counts <- aggregate(bb ~ camera, train,
                                  function(x) length(unique(as.character(x))))
names(camera_brand_counts)[2] <- "brands"
camera_brand_counts$multibrand <- camera_brand_counts$brands > 1
overlap_summary <- data.frame(
  metric = c("training_rows", "training_cameras", "multibrand_cameras",
             "single_brand_cameras", "multibrand_fraction"),
  value = c(nrow(train), nrow(camera_brand_counts),
            sum(camera_brand_counts$multibrand),
            sum(!camera_brand_counts$multibrand),
            sum(camera_brand_counts$multibrand) / nrow(camera_brand_counts))
)
write_csv(overlap_summary, "camera_brand_overlap_summary.csv")

brands <- sort(unique(as.character(train$bb)))
brand_support <- do.call(rbind, lapply(brands, function(b) {
  ids <- unique(as.character(train$camera[as.character(train$bb) == b]))
  data.frame(
    brand = b,
    cameras = length(ids),
    rows = sum(as.character(train$bb) == b),
    events = sum(train$event[as.character(train$bb) == b]),
    multibrand_cameras = sum(camera_brand_counts$camera %in% ids & camera_brand_counts$multibrand),
    stringsAsFactors = FALSE
  )
}))
write_csv(brand_support, "brand_camera_support.csv")

pair_support <- do.call(rbind, lapply(seq_len(length(brands) - 1), function(i) {
  do.call(rbind, lapply((i + 1):length(brands), function(j) {
    a <- unique(as.character(train$camera[as.character(train$bb) == brands[[i]]]))
    b <- unique(as.character(train$camera[as.character(train$bb) == brands[[j]]]))
    data.frame(brand_a = brands[[i]], brand_b = brands[[j]],
               shared_cameras = length(intersect(a, b)), stringsAsFactors = FALSE)
  }))
}))
write_csv(pair_support, "shared_brand_pair_support.csv")

# C. KM medians and ordinary pointwise 95% CIs for the training brands. These
# refer to time to last confirmed operation, not physical battery exhaustion.
km_one <- function(d, group, flash_label = NA_character_) {
  fit <- survival::survfit(survival::Surv(rd, event) ~ 1, data = d)
  st <- summary(fit)$table
  data.frame(
    cohort = group,
    brand = if (length(unique(as.character(d$bb))) == 1) unique(as.character(d$bb)) else NA_character_,
    flash = flash_label,
    rows = nrow(d),
    cameras = length(unique(as.character(d$camera))),
    events = sum(d$event),
    median_days = unname(st[["median"]]),
    median_ci_low = unname(st[["0.95LCL"]]),
    median_ci_high = unname(st[["0.95UCL"]]),
    interval_note = "ordinary pointwise 95% KM interval; not camera-cluster adjusted",
    endpoint_note = "event is time to last confirmed operation; physical shutdown time is unobserved",
    stringsAsFactors = FALSE
  )
}

km_brand <- do.call(rbind, lapply(brands, function(b) {
  km_one(train[as.character(train$bb) == b, , drop = FALSE], "training_brand")
}))
write_csv(km_brand, "km_brand_medians_pointwise_ci.csv")

# D. SW Varta/white versus training Varta/white. Flash code w is labelled
# white only here because that is the project convention.
varta_train <- train[as.character(train$bb) == "Varta" & train$ft == "w", , drop = FALSE]
varta_sw <- sw[as.character(sw$bb) == "Varta" & sw$ft == "w", , drop = FALSE]
workload_contrast <- rbind(
  data.frame(cohort = "training", brand = "Varta", flash = "white",
             rows = nrow(varta_train), cameras = length(unique(varta_train$camera)),
             events = sum(varta_train$event), workload_variable = "fi_pd",
             workload_mean = mean(varta_train$fi_pd), workload_median = median(varta_train$fi_pd)),
  data.frame(cohort = "SW held region", brand = "Varta", flash = "white",
             rows = nrow(varta_sw), cameras = length(unique(varta_sw$camera)),
             events = sum(varta_sw$event), workload_variable = "fi_pd",
             workload_mean = mean(varta_sw$fi_pd), workload_median = median(varta_sw$fi_pd))
)
write_csv(workload_contrast, "sw_varta_workload_contrast.csv")
write_csv(rbind(km_one(varta_train, "training", "white"),
                km_one(varta_sw, "SW_held_region", "white")),
          "varta_white_km_contrast_pointwise_ci.csv")

# E. Saved baseline Cox associations, retaining robust confidence limits.
# Chemistry is not a separate Cox coefficient because it is brand-aliased.
keep_terms <- c("bbEnergizer", "bbProcell", "bbVarta", "bbWallaby", "ftw",
                "seasspring", "seassummer", "seaswinter", "log_fi_pd", "log_day_pd")
cox_effects <- cox[cox$term %in% keep_terms,
                   c("term", "hr", "hr_low", "hr_high", "p.value"), drop = FALSE]
cox_effects$ci_note <- "region-stratified Cox; camera-cluster robust 95% CI; associational"
write_csv(cox_effects, "cox_effects_saved_robust_ci.csv")

# F. Population AFT brand-location coefficients, comparing saved independent
# and camera-dependent posterior summaries. These are log-time coefficients;
# random effects do not establish causal within-camera identification.
design <- readRDS(file.path(source_dir, "design.rds"))
brand_terms <- as.character(design$columns)[grepl("^bb", as.character(design$columns))]
brand_idx <- match(brand_terms, as.character(design$columns))
brand_betas <- do.call(rbind, lapply(names(pop_files), function(model_id) {
  p <- read.csv(file.path(source_dir, "tables", pop_files[[model_id]]),
               stringsAsFactors = FALSE, check.names = FALSE)
  p <- p[match(paste0("beta[", brand_idx, "]"), p$variable), , drop = FALSE]
  data.frame(model_id = model_id, term = brand_terms,
             mean = p$mean, median = p$median, sd = p$sd,
             q5 = p$q5, q95 = p$q95,
             uncertainty_note = "saved posterior 5%-95% interval; log-time coefficient",
             interpretation_note = "population association; camera random effects do not establish causal within-camera identification",
             stringsAsFactors = FALSE)
}))
write_csv(brand_betas, "aft_population_brand_betas_camera_vs_independent.csv")

metadata <- data.frame(
  item = c("source_cohort", "source_design", "source_cox", "script", "analysis_date",
           "training_rows", "training_cameras", "multibrand_cameras", "raw_event_definition",
           "physical_shutdown_identified", "km_cluster_adjustment", "chemistry_alias"),
  value = c(
    file.path(source_dir, "cohorts.rds"), file.path(source_dir, "design.rds"),
    file.path("outputs", "tables", "cox_coefficients.csv"),
    "scripts/summarise_manuscript_effects.R", "2026-09-18",
    nrow(train), nrow(camera_brand_counts), sum(camera_brand_counts$multibrand),
    "event=1 when camera was found non-operational; rd is last confirmed image duration",
    "no; service date is unavailable and failure time is only bounded after the last image",
    "no; KM intervals are ordinary pointwise intervals under row-level survfit",
    "battery chemistry is determined by brand in the training cohort and is therefore not separately identifiable"
  ), stringsAsFactors = FALSE
)
write_csv(metadata, "analysis_metadata.csv")

cat("Wrote manuscript field-effect summaries to ", out_dir, "\n", sep = "")
cat("Training cameras: ", nrow(camera_brand_counts),
    "; multibrand cameras: ", sum(camera_brand_counts$multibrand), "\n", sep = "")
