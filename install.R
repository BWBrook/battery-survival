install.packages('pacman')
pacman::p_load(config, survival, survminer, loo)
pacman::p_install_gh("stan-dev/rstanarm@feature/survival")