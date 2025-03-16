# Family Calendar

A simple calendar application that integrates with Google Calendar API to display your family's events.

## Features

- OAuth2 authentication with Google
- Display today's calendar events
- Simple travel time estimation
- Clean, responsive UI

## Project Structure

- **family-calendar-server**: The Node.js application code

## Local Development

1. **Install dependencies**:
   ```
   cd family-calendar
   npm install
   ```

2. **Set up environment variables**:
   Create a `.env` file in the family-calendar-server directory with:
   ```
   CLIENT_ID=your_google_oauth_client_id
   CLIENT_SECRET=your_google_oauth_client_secret
   REDIRECT_URI=http://localhost:3000/auth/callback
   CALENDAR_ID=your_google_calendar_id
   ```

3. **Run the server**:
   ```
   npm start
   ```
   or for development with auto-reload:
   ```
   npm run dev
   ```

4. **Access the application**:
   Open http://localhost:3000 in your browser

## Deployment to Raspberry Pi

This project uses GitHub for source code management and includes scripts to automate the deployment process to a Raspberry Pi.

### 1. Push Your Code to GitHub

First, create a GitHub repository and push your code:

```bash
# Initialize Git repository (if not already done)
git init

# Add all files
git add .

# Commit changes
git commit -m "Initial commit"

# Add GitHub remote (replace with your repository URL)
git remote add origin https://github.com/yourusername/family-calendar.git

# Push to GitHub
git push -u origin main
```

### 2. Set Up Your Raspberry Pi

1. **Set up SSH access** to your Raspberry Pi from your Mac
2. **Transfer the setup script** to your Raspberry Pi:
   ```bash
   scp pi-setup.sh pi@raspberrypi.local:~/
   ```

3. **Run the setup script** on your Raspberry Pi:
   ```bash
   ssh pi@raspberrypi.local "chmod +x ~/pi-setup.sh && ~/pi-setup.sh"
   ```

   This will:
   - Install Node.js 20.x
   - Install Git and PM2
   - Set up Nginx as a reverse proxy with proper configuration
   - Configure the application to start on boot

### 3. Deploy Your Application

#### Option 1: Manual Deployment

1. **Transfer the deployment script** to your Raspberry Pi:
   ```bash
   scp deploy-from-github.sh pi@raspberrypi.local:~/
   ```

2. **Update the GitHub repository URL** in the deployment script:
   ```bash
   ssh pi@raspberrypi.local "sed -i 's|https://github.com/yourusername/family-calendar.git|https://github.com/YOUR_ACTUAL_USERNAME/family-calendar.git|g' ~/deploy-from-github.sh"
   ```

3. **Run the deployment script** on your Raspberry Pi:
   ```bash
   ssh pi@raspberrypi.local "chmod +x ~/deploy-from-github.sh && ~/deploy-from-github.sh"
   ```

#### Option 2: Automatic Deployment with GitHub Webhooks

1. **Transfer the webhook setup script** to your Raspberry Pi:
   ```bash
   scp setup-webhook.sh pi@raspberrypi.local:~/
   ```

2. **Run the webhook setup script** on your Raspberry Pi:
   ```bash
   ssh pi@raspberrypi.local "chmod +x ~/setup-webhook.sh && ~/setup-webhook.sh"
   ```

3. **Configure the GitHub webhook** using the information provided by the script

### 4. Set Up Environment Variables

SSH into your Raspberry Pi and create a `.env` file:

```bash
ssh pi@raspberrypi.local
cd ~/family-calendar
nano .env
```

Add your environment variables:

```
PORT=3000
CLIENT_ID=your_client_id_here
CLIENT_SECRET=your_client_secret_here
REDIRECT_URI=http://raspberrypi.local/auth/callback
CALENDAR_ID=your_calendar_id_here
NODE_ENV=production
```

### 5. Access Your Application

You can now access your application at:
- `http://raspberrypi.local` (if your Pi's hostname is "raspberrypi")
- `http://your-raspberry-pi-ip` (using the Pi's IP address)

### 6. Update Your Application

With the GitHub-based deployment:

1. Make changes to your code locally
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Your update message"
   git push
   ```

3. If you set up the webhook, the application will deploy automatically
4. If not, run the deployment script on your Raspberry Pi:
   ```bash
   ssh pi@raspberrypi.local "~/deploy-from-github.sh"
   ```

### Useful Commands

When SSH'd into your Raspberry Pi:
- **View running processes**: `pm2 list`
- **Restart application**: `pm2 restart family-calendar`
- **View application logs**: `pm2 logs family-calendar`
- **Monitor application**: `pm2 monit` 