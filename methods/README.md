# research-framework methods directory
This directory is not ignored, files here will be in version control

Main research files go in here. 

Best practice is the config package and create config.yml 

You can then pick different settings based on environment variables:

    Sys.setenv(R_CONFIG_ACTIVE = "model_3")

Number your methods files sequentially in the order they should be run.

    proj_1_fit.R
    proj_2_cv.R
    proj_3.ppc.R
    proj_4_visualisations.R

Store your results in sensible directories in the appropriate results folder.

    ../results/{date}/fitted_models
    ../results/{date}/cv_objects
    ../results/{date}/figures
