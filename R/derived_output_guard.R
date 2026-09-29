# Resolve existing ancestors as well as the final path so a new child of a
# symlink cannot bypass the sealed-output boundary.
derived_resolve_path <- function(path) {
  suffix <- character()
  path <- path.expand(path)
  while (!file.exists(path) && !dir.exists(path)) {
    parent <- dirname(path)
    if (identical(parent, path)) stop("Cannot resolve output path: ", path)
    suffix <- c(basename(path), suffix)
    path <- parent
  }
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  for (part in suffix) root <- file.path(root, part)
  # Resolve dot components in the not-yet-existing suffix.
  parts <- strsplit(root, "/", fixed = TRUE)[[1L]]
  clean <- character()
  for (part in parts) {
    if (part %in% c("", ".")) next
    if (part == "..") clean <- head(clean, -1L) else clean <- c(clean, part)
  }
  paste0("/", paste(clean, collapse = "/"))
}

assert_derived_output_destination <- function(input, out,
                                             protected = c("outputs/sensitivity",
                                                           "outputs/management/2026-09-18")) {
  destination <- derived_resolve_path(out)
  sealed <- vapply(unique(c(input, protected)), derived_resolve_path, character(1))
  contains <- function(parent, child) identical(parent, child) ||
    startsWith(child, paste0(sub("/$", "", parent), "/"))
  overlap <- vapply(sealed, function(path)
    contains(path, destination) || contains(destination, path), logical(1))
  if (any(overlap)) stop("Derived output overlaps sealed inputs/archive; choose a separate output directory", call. = FALSE)
  invisible(destination)
}
