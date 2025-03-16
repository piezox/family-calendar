#!/bin/bash

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

# Install Chromium browser if not already installed
print_status "Checking for Chromium browser..."
if ! command -v chromium-browser &> /dev/null; then
    print_status "Installing Chromium browser..."
    sudo apt-get update
    sudo apt-get install -y chromium-browser
    print_success "Chromium browser installed successfully."
else
    print_status "Chromium browser is already installed."
fi

# Create autostart directory
print_status "Creating autostart directory..."
mkdir -p ~/.config/autostart

# Create desktop entry for kiosk mode
print_status "Creating kiosk mode desktop entry..."
cat > ~/.config/autostart/calendar-kiosk.desktop << EOL
[Desktop Entry]
Type=Application
Name=Family Calendar
Exec=chromium-browser --kiosk --no-first-run --disable-infobars --noerrdialogs --disable-translate --disable-features=TranslateUI --disable-sync --disable-suggestions-service http://raspberrypi.local
X-GNOME-Autostart-enabled=true
EOL

print_status "Setting correct permissions..."
chmod +x ~/.config/autostart/calendar-kiosk.desktop

# Disable screen saver and screen blanking
print_status "Disabling screen saver and screen blanking..."
if ! grep -q "xserver-command=X -s 0 -dpms" /etc/lightdm/lightdm.conf 2>/dev/null; then
    sudo sed -i '/^\[Seat:\*\]/a xserver-command=X -s 0 -dpms' /etc/lightdm/lightdm.conf
fi

# Disable cursor
print_status "Creating script to hide cursor..."
cat > ~/.config/autostart/hide-cursor.desktop << EOL
[Desktop Entry]
Type=Application
Name=Hide Cursor
Exec=unclutter -idle 0
X-GNOME-Autostart-enabled=true
EOL

# Install unclutter if not present
if ! command -v unclutter &> /dev/null; then
    print_status "Installing unclutter to hide cursor..."
    sudo apt-get install -y unclutter
fi

print_success "Kiosk mode setup completed successfully!"
print_status "The Family Calendar will start in kiosk mode on next boot."
print_status "To test without rebooting, you can run:"
print_status "chromium-browser --kiosk --no-first-run --disable-infobars --noerrdialogs http://raspberrypi.local" 