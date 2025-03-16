#!/bin/bash

# Setup script for GitHub webhook deployment
# This script:
# 1. Installs webhook listener
# 2. Configures it to run the deployment script when triggered
# 3. Sets up systemd service to run the webhook listener

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
WEBHOOK_PORT=9000
SECRET_TOKEN=$(openssl rand -hex 20)  # Generate a random secret token
HOOKS_DIR="$HOME/webhooks"
DEPLOY_SCRIPT="$HOME/deploy-from-github.sh"

# Install webhook if not already installed
if ! command -v webhook &> /dev/null; then
  print_status "Installing webhook..."
  sudo apt-get install -y webhook
  print_success "Webhook installed successfully."
else
  print_status "Webhook is already installed."
fi

# Create hooks directory
print_status "Creating hooks directory..."
mkdir -p $HOOKS_DIR

# Create webhook configuration
print_status "Creating webhook configuration..."
cat > $HOOKS_DIR/hooks.json << EOF
[
  {
    "id": "deploy-family-calendar",
    "execute-command": "$DEPLOY_SCRIPT",
    "command-working-directory": "$HOME",
    "response-message": "Deploying family-calendar application...",
    "trigger-rule": {
      "match": {
        "type": "payload-hash-sha1",
        "secret": "$SECRET_TOKEN",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature"
        }
      }
    }
  }
]
EOF

# Make deploy script executable
print_status "Making deploy script executable..."
chmod +x $DEPLOY_SCRIPT

# Create systemd service file
print_status "Creating systemd service file..."
sudo tee /etc/systemd/system/webhook.service > /dev/null << EOF
[Unit]
Description=Webhook for GitHub deployments
After=network.target

[Service]
User=$(whoami)
ExecStart=/usr/bin/webhook -hooks $HOOKS_DIR/hooks.json -port $WEBHOOK_PORT -verbose
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the webhook service
print_status "Starting webhook service..."
sudo systemctl daemon-reload
sudo systemctl enable webhook
sudo systemctl start webhook

print_success "Webhook setup completed successfully!"
print_status "GitHub Webhook URL: http://$(hostname -I | awk '{print $1}'):$WEBHOOK_PORT/hooks/deploy-family-calendar"
print_status "Secret Token: $SECRET_TOKEN"
print_status ""
print_status "To set up the webhook in GitHub:"
print_status "1. Go to your GitHub repository"
print_status "2. Click on 'Settings' > 'Webhooks' > 'Add webhook'"
print_status "3. Set Payload URL to the webhook URL above"
print_status "4. Set Content type to 'application/json'"
print_status "5. Set Secret to the secret token above"
print_status "6. Select 'Just the push event'"
print_status "7. Ensure 'Active' is checked"
print_status "8. Click 'Add webhook'" 