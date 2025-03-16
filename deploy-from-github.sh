#!/bin/bash

# Deployment script for Family Calendar on Raspberry Pi
# This script:
# 1. Pulls the latest code from GitHub
# 2. Installs dependencies
# 3. Restarts the application with PM2

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
  echo -e "${YELLOW}[STATUS]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
APP_DIR="$HOME/family-calendar"
GITHUB_REPO="https://github.com/piezox/family-calendar.git" 
APP_NAME="family-calendar"

# Check if the application directory exists
if [ ! -d "$APP_DIR" ]; then
  print_status "Application directory does not exist. Cloning repository..."
  git clone $GITHUB_REPO $APP_DIR
  cd $APP_DIR
else
  print_status "Application directory exists. Pulling latest changes..."
  cd $APP_DIR
  git pull
fi

# Install dependencies
print_status "Installing dependencies..."
npm install --production

# Check if the application is already running with PM2
if pm2 list | grep -q "$APP_NAME"; then
  print_status "Restarting application with PM2..."
  pm2 restart $APP_NAME
else
  print_status "Starting application with PM2..."
  pm2 start server.js --name $APP_NAME
  pm2 save
fi

print_success "Deployment completed successfully!"
print_status "You can access your application at http://raspberrypi.local or http://$(hostname -I | awk '{print $1}')"
print_status "To view application logs, run: pm2 logs $APP_NAME" 