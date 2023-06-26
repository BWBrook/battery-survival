FROM rocker/verse:4.2.2

COPY install.R /install.R
RUN Rscript install.R