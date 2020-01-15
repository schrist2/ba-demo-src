#!/bin/bash

# Update package index.
sudo apt -y update

# Add NodeJS 12 to package index.
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

# Install required packages.
sudo apt -y install git nodejs nginx

# Copy source code into /var
sudo cp -r ~/code /var/code

# Switch to app source code directory.
cd /var/code

# Install all node modules specified in package.json.
sudo npm install

# Install ExpressJS service.
sudo cp ~/provision/app.service /etc/systemd/system/app.service

# Run ExpressJS Server as service.
sudo systemctl enable app.service
sudo systemctl start app.service

# Install site configuration for nginx.
sudo cp ~/provision/nginx.conf /etc/nginx/sites-enabled/default

# Update nginx to use new site configuration.
sudo service nginx restart
