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

This project uses GitHub for source code management and deployment to a Raspberry Pi.

### 1. Repository Information

This project is hosted at: https://github.com/piezox/family-calendar.git

If you haven't already, clone the repository to your development machine:
```bash
git clone https://github.com/piezox/family-calendar.git
cd family-calendar
```

### 2. Set Up Your Raspberry Pi

1. **Set up SSH access** to your Raspberry Pi from your Mac

2. **Clone and run the setup script**:
   ```bash
   # Connect to your Pi
   ssh pi@raspberrypi.local

   # Clone the repository
   git clone https://github.com/piezox/family-calendar.git
   cd family-calendar

   # Make the setup script executable and run it
   chmod +x pi-setup.sh && ./pi-setup.sh
   ```

   This script will automatically:
   - Install Node.js 20.x
   - Install Git and PM2
   - Set up Nginx as a reverse proxy
   - Configure the application to start on boot
   - Set up PM2 for process management

### 3. Configure Your Application

1. **Set up environment variables**:
   ```bash
   # Create and edit .env file
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

2. **Start the application**:
   ```bash
   # Install dependencies and start
   npm install --production
   pm2 start server.js --name family-calendar
   ```

3. **Set up kiosk mode** (optional):
   If you want the calendar to automatically start in full-screen mode when the Raspberry Pi boots:
   ```bash
   # Make the script executable and run it
   chmod +x setup-kiosk.sh && ./setup-kiosk.sh
   ```

   This script will:
   - Install Chromium browser if needed
   - Configure autostart for kiosk mode
   - Disable screen blanking and cursor
   - Set up full-screen mode

   After running this script, the calendar will automatically launch in full-screen mode on next boot.

### 4. Access Your Application

You can now access your application at:
- `http://raspberrypi.local` (if your Pi's hostname is "raspberrypi")
- `http://your-raspberry-pi-ip` (using the Pi's IP address)

### 5. Update Your Application

To update your application with the latest changes:

1. **Push your changes** to GitHub from your development machine:
   ```bash
   git add .
   git commit -m "Your update message"
   git push
   ```

2. **Pull and restart** on your Raspberry Pi:
   ```bash
   # Connect to your Pi
   ssh pi@raspberrypi.local

   # Make sure you're in the correct directory
   cd ~/family-calendar    # This is important! The repository must exist here

   # Check if you're in a git repository (should show the branch name)
   git status

   # If the repository doesn't exist, clone it first:
   # cd ~
   # git clone https://github.com/piezox/family-calendar.git
   # cd family-calendar

   # Pull the latest changes
   git pull

   # Install any new dependencies
   npm install --production

   # Restart the application
   pm2 restart family-calendar
   ```

### Useful Commands

When SSH'd into your Raspberry Pi:
- **View running processes**: `pm2 list`
- **View application logs**: `pm2 logs family-calendar`
- **Monitor application**: `pm2 monit`
- **View Nginx logs**: `sudo tail -f /var/log/nginx/error.log` 