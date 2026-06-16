ARG BASE_PLATFORM=linux/amd64
FROM --platform=$BASE_PLATFORM rocker/verse:4.6.0

WORKDIR /project

COPY . /project

RUN Rscript --vanilla -e "source('renv/activate.R'); renv::restore(prompt = FALSE)"

EXPOSE 8787
