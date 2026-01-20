# Taktica Production Dockerfile
FROM rocker/shiny:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c( \
    'shiny', \
    'shinydashboard', \
    'plotly', \
    'reactable', \
    'dplyr', \
    'arrow', \
    'lubridate', \
    'shinyWidgets', \
    'httr', \
    'jsonlite', \
    'logger', \
    'config', \
    'DT', \
    'forecast', \
    'ggplot2', \
    'tidyr', \
    'scales', \
    'glue', \
    'purrr', \
    'tibble' \
), repos='https://cran.rstudio.com/')"

# Create application directory
RUN mkdir -p /srv/shiny-server/taktica

# Copy application files
COPY app/ /srv/shiny-server/taktica/app/
COPY R/ /srv/shiny-server/taktica/R/
COPY config/ /srv/shiny-server/taktica/config/
COPY data/ /srv/shiny-server/taktica/data/
COPY DESCRIPTION /srv/shiny-server/taktica/
COPY .Renviron /srv/shiny-server/taktica/

# Set working directory
WORKDIR /srv/shiny-server/taktica

# Create logs and data directories
RUN mkdir -p /var/log/taktica /data/taktica && \
    chown -R shiny:shiny /var/log/taktica /data/taktica /srv/shiny-server/taktica

# Set environment variables
ENV R_CONFIG_ACTIVE=production
ENV TAKTICA_LOG_LEVEL=INFO

# Expose port
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
