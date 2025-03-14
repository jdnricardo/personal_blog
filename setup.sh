#!/bin/bash

# Exit on error
set -e

echo "Setting up R environment..."

# Update package list
echo "Updating package list..."
sudo apt-get update

# Remove existing R installation
echo "Removing existing R installation..."
sudo apt-get remove -y r-base r-base-core r-base-dev
sudo apt-get autoremove -y

# Add the CRAN repository key
echo "Adding CRAN repository..."
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# Add the CRAN repository for Ubuntu
echo "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" | sudo tee -a /etc/apt/sources.list.d/cran.list

# Update package list again
sudo apt-get update

# Install R 4.4 and essential dependencies
echo "Installing R 4.4 and dependencies..."
sudo apt-get install -y \
    r-base \
    r-base-dev \
    r-recommended \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev

# Install required R packages for VSCode integration
echo "Installing VSCode-R required packages..."
Rscript -e 'install.packages(c("jsonlite", "rlang", "languageserver", "httpgd"), repos="https://cloud.r-project.org")'

# Install renv if not already installed
echo "Installing renv..."
Rscript -e 'if (!require("renv")) install.packages("renv", repos="https://cloud.r-project.org")'

# Create .Rprofile if it doesn't exist
if [ ! -f .Rprofile ]; then
    echo "Creating .Rprofile..."
    cat > .Rprofile << 'EOL'
# Enable renv for this project
source("renv/activate.R")

# VSCode R Session Watcher setup
if (interactive() && Sys.getenv("TERM_PROGRAM") == "vscode") {
    if ("httpgd" %in% .packages(all.available = TRUE)) {
        options(vsc.plot = FALSE)
        options(device = function(...) {
            httpgd::hgd(silent = TRUE)
            httpgd::hgd_browse()
        })
    }
}
EOL
fi

# Initialize renv if not already initialized
if [ ! -d "renv" ]; then
    echo "Initializing renv..."
    Rscript -e 'renv::init()'
fi

# Verify R version
echo "Verifying R installation..."
R --version

echo "Setup complete! You can now use R and renv in this project."
echo "To restore packages, run: Rscript -e 'renv::restore()'" 