## Emails

Below are some recent relevant emails between me (Barry: data collector and supervisor) and Zach, the postdoc who created the repo and did the initial analysis.

## Barry to Zach

I'm looking into writing up the battery survival MS as my next 'to do' project. Sound okay? Anything else that I should know for the write-up? I'm looking forward to finally get this completed 🙂

I have access to the private GitHub repo. Does it need any cleaning up (e.g., archiving the XX_ prefix files?). Do you want me to take charge of re-arranging it?

Regarding data and notes, can you send me what you have, so that I know I'm working with all available information?

## Zach to Barry
 
I’m pretty sure the GitHub repo was set up to just add data in the right directory and run a Docker container to launch RStudio (which is helpful because the survival analysis code wasn’t fully integrated into rstanarm yet).  

Getting the battery survival stuff running is a bit fiddly. I was having trouble building Docker container, so I just used RStudio on my MacBook Air. Everything seems to work fine except the TB data (which I think might not have enough for the Stan analysis, not sure why it was erroring out).

The folder names below are defined in the config.yml and can be changed there if needed:

Create a folder 2022-08-22 under /data in the downloaded repo code and add batt_life_aug22.csv to that folder.

Create a folder 2022-09-05 under /results in the downloaded repo code.

I had this commented in the repo, it was a specific branch of rstanarm:

pacman::p_install_gh("stan-dev/rstanarm@f9047a095f00a2f3d1d0420059dcf52842ad3c42")

BUT I ended up not using it on my MacBook. I just did the following (following the latest advice for survival analysis using rstanarm):

install.packages("rstan")

install.packages("rstanarm", repos = c('https://stan-dev.r-universe.dev', getOption("repos")))

Set env variables in RStudio for the region to process (notes in the individual R files, config.yml enumerates different regions that are setup):

To fit basic survival (not Bayes/Stan) for the SW region:

Sys.setenv(R_CONFIG_ACTIVE = "sw")

source("01_fit_surv.R")

To do rstanarm survival analysis for SW using Weibull... other parametric models include sw_bs_5, sw_bs_7, sw_ms_5, sw_ms_7 (all spline-based models)

NOTE: I had to comment out this line in 02_fit_stan.R because it kept repeatedly building rstanarm:

#source("00_dependencies_gh.R")

Sys.setenv(R_CONFIG_ACTIVE = "sw_wb")

source("02_fit_stan.R")

Four chains should run when you do that. The results are all stored in the results directory defined above and should have sensible names for each model run. When I originally did the analysis I just ran through each of the different models using the methodology above (set environment with model name, source the 02_fit_stan.R file).

I didn’t test out the visualisation code, but I think it should be easy to follow.

Let me know if this makes sense and if you are able to get it going.

