#!/bin/bash

# Comprehensive setup script for Family Calendar on Raspberry Pi
# This script:
# 1. Installs Node.js 20.x
# 2. Installs PM2 for process management
# 3. Sets up Nginx as a reverse proxy with proper configuration
# 4. Configures the application to start on boot

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

# Update package lists
print_status "Updating package lists..."
sudo apt-get update

# Check if Node.js is installed and remove if it's an old version
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  print_status "Current Node.js version: $NODE_VERSION"
  
  # If it's not version 20, remove it
  if [[ ! $NODE_VERSION == v20* ]]; then
    print_status "Removing old Node.js version..."
    
    # Stop any running Node.js applications
    if command -v pm2 &> /dev/null; then
      print_status "Stopping PM2 processes..."
      pm2 stop all
      pm2 save
    fi
    
    # Remove Node.js and npm
    print_status "Removing Node.js packages..."
    sudo apt-get remove -y nodejs npm
    
    # Remove Node.js source repository
    print_status "Removing Node.js repository..."
    sudo rm -f /etc/apt/sources.list.d/nodesource.list
    
    # Clean up apt
    print_status "Cleaning up apt..."
    sudo apt-get autoremove -y
    sudo apt-get clean
    
    # Update package lists
    print_status "Updating package lists..."
    sudo apt-get update
  else
    print_status "Node.js 20.x is already installed. Skipping installation."
  fi
fi

# Install Node.js 20.x if not already installed
if ! command -v node &> /dev/null || [[ ! $(node -v) == v20* ]]; then
  print_status "Installing Node.js 20.x..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  print_success "Node.js 20.x installed successfully."
fi

# Install Git if not already installed
if ! command -v git &> /dev/null; then
  print_status "Installing Git..."
  sudo apt-get install -y git
  print_success "Git installed successfully."
else
  print_status "Git is already installed."
fi

# Install PM2
print_status "Installing PM2..."
if ! command -v pm2 &> /dev/null; then
  sudo npm install -g pm2
  print_success "PM2 installed successfully."
else
  print_status "PM2 is already installed."
fi

# Install Nginx
print_status "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
  sudo apt-get install -y nginx
  print_success "Nginx installed successfully."
else
  print_status "Nginx is already installed."
fi

# Configure Nginx
print_status "Configuring Nginx..."

# Disable the default site
if [ -f /etc/nginx/sites-enabled/default ]; then
  print_status "Disabling the default Nginx site..."
  sudo rm /etc/nginx/sites-enabled/default
fi

# Create our site configuration
print_status "Creating family-calendar Nginx configuration..."
sudo tee /etc/nginx/sites-available/family-calendar > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;  # This will match any hostname

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable our site
if [ ! -f /etc/nginx/sites-enabled/family-calendar ]; then
  print_status "Enabling the family-calendar site..."
  sudo ln -s /etc/nginx/sites-available/family-calendar /etc/nginx/sites-enabled/
fi

# Test Nginx configuration
print_status "Testing Nginx configuration..."
sudo nginx -t

# Restart Nginx
print_status "Restarting Nginx..."
sudo systemctl restart nginx

# Create application directory
print_status "Creating application directory..."
mkdir -p ~/family-calendar

# Configure PM2 to start on boot
print_status "Configuring PM2 to start on boot..."
pm2 startup | grep "sudo" | bash
pm2 save

print_success "Raspberry Pi setup completed successfully!"
print_status "Next steps:"
print_status "1. Clone your GitHub repository: git clone https://github.com/yourusername/family-calendar.git ~/family-calendar"
print_status "2. Create a .env file in ~/family-calendar with your Google API credentials"
print_status "3. Start your application: cd ~/family-calendar && pm2 start server.js --name family-calendar"
print_status "4. Access your application at http://raspberrypi.local or http://$(hostname -I | awk '{print $1}')" 