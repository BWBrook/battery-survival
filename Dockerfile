FROM rocker/verse:4.5.2

WORKDIR /project

COPY . /project

RUN Rscript --vanilla -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"
RUN Rscript --vanilla -e "if (file.exists('renv.lock')) renv::restore(prompt = FALSE)"

EXPOSE 8787
