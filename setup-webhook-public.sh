#!/bin/bash

# Setup script for GitHub webhook deployment with public access
# This script:
# 1. Installs webhook listener and necessary tools
# 2. Sets up port forwarding check
# 3. Configures webhook for public access

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
SECRET_TOKEN=$(openssl rand -hex 20)
HOOKS_DIR="$HOME/webhooks"
DEPLOY_SCRIPT="$HOME/deploy-from-github.sh"

# Install required packages
print_status "Installing required packages..."
sudo apt-get update
sudo apt-get install -y webhook curl jq

# Get public IP
print_status "Getting public IP address..."
PUBLIC_IP=$(curl -s https://api.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
  print_error "Could not determine public IP address"
  exit 1
fi
print_success "Public IP: $PUBLIC_IP"

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

# Test port accessibility
print_status "Testing webhook accessibility..."
sleep 5  # Give the service time to start
if curl -s "http://localhost:$WEBHOOK_PORT/hooks/deploy-family-calendar" > /dev/null; then
  print_success "Webhook is running locally"
else
  print_error "Webhook is not responding locally"
fi

print_success "Webhook setup completed!"
print_status "To complete the setup:"
print_status ""
print_status "1. Configure your router to forward port $WEBHOOK_PORT to this Raspberry Pi"
print_status "   - Forward external port $WEBHOOK_PORT to internal IP $(hostname -I | awk '{print $1}')"
print_status "   - Protocol: TCP"
print_status ""
print_status "2. Set up the GitHub webhook:"
print_status "   - Payload URL: http://$PUBLIC_IP:$WEBHOOK_PORT/hooks/deploy-family-calendar"
print_status "   - Content type: application/json"
print_status "   - Secret: $SECRET_TOKEN"
print_status "   - SSL verification: Disabled (using http)"
print_status "   - Events: Just the push event"
print_status ""
print_status "3. Test the connection:"
print_status "   After setting up port forwarding, run:"
print_status "   curl -i http://$PUBLIC_IP:$WEBHOOK_PORT/hooks/deploy-family-calendar"
print_status ""
print_status "4. (Optional) Set up Dynamic DNS if your IP changes frequently"
print_status "   Current webhook logs can be viewed with: journalctl -u webhook -f" 