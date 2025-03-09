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
   cd family-calendar-server
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

## Simplified Deployment to AWS Lightsail with Bitnami Node.js

Since you already have familycal.piezo.cc associated with your Lightsail instance, here's a simplified deployment process:

### 1. Push Your Code to GitHub

```bash
# Initialize Git repository (if not already done)
cd family-calendar-server
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

### 2. Set Up on Your Lightsail Instance

Connect to your Lightsail instance via SSH and run:

```bash
# Create projects directory
sudo mkdir -p /opt/bitnami/projects
sudo chown $USER /opt/bitnami/projects
cd /opt/bitnami/projects

# Clone your repository
git clone https://github.com/yourusername/family-calendar.git
cd family-calendar

# Create .env file
cat > .env << EOF
PORT=3000
CLIENT_ID=your_client_id_here
CLIENT_SECRET=your_client_secret_here
REDIRECT_URI=https://familycal.piezo.cc/auth/callback
CALENDAR_ID=your_calendar_id_here
NODE_ENV=production
EOF

# Install dependencies
npm install

# Install Forever and start your app
sudo npm install -g forever
forever start server.js
```

### 3. Configure Apache Virtual Host for familycal.piezo.cc

```bash
# Create HTTP virtual host
sudo nano /opt/bitnami/apache/conf/vhosts/familycal-http-vhost.conf
```

Add the following content:
```
<VirtualHost *:80>
  ServerName familycal.piezo.cc
  DocumentRoot "/opt/bitnami/projects/family-calendar/public"
  <Directory "/opt/bitnami/projects/family-calendar/public">
    Require all granted
  </Directory>
  ProxyPass / http://localhost:3000/
  ProxyPassReverse / http://localhost:3000/
</VirtualHost>
```

```bash
# Create HTTPS virtual host
sudo nano /opt/bitnami/apache/conf/vhosts/familycal-https-vhost.conf
```

Add the following content:
```
<VirtualHost *:443>
  ServerName familycal.piezo.cc
  SSLEngine on
  SSLCertificateFile "/opt/bitnami/apache/conf/bitnami/certs/server.crt"
  SSLCertificateKeyFile "/opt/bitnami/apache/conf/bitnami/certs/server.key"
  DocumentRoot "/opt/bitnami/projects/family-calendar/public"
  <Directory "/opt/bitnami/projects/family-calendar/public">
    Require all granted
  </Directory>
  ProxyPass / http://localhost:3000/
  ProxyPassReverse / http://localhost:3000/
</VirtualHost>
```

### 4. Set Up HTTPS and Restart Apache

```bash
# Configure Let's Encrypt certificate
sudo /opt/bitnami/bncert-tool
# Follow the prompts, entering familycal.piezo.cc when asked for domains

# Restart Apache
sudo /opt/bitnami/ctlscript.sh restart apache
```

### 5. Set Up Authentication

1. Visit https://familycal.piezo.cc in your browser
2. Click the "Authenticate" button and follow the Google OAuth flow
3. After authentication, you'll see a message with a TOKEN_DATA value
4. Update your .env file with this value:
   ```bash
   nano /opt/bitnami/projects/family-calendar/.env
   # Add: TOKEN_DATA=the_token_value_from_the_message
   ```
5. Restart your application: `forever restart server.js`

### 6. Update Your Application (When Needed)

When you make changes to your code:

1. Push changes to GitHub:
   ```bash
   git add .
   git commit -m "Your update message"
   git push
   ```

2. Pull changes on your server:
   ```bash
   cd /opt/bitnami/projects/family-calendar
   git pull
   npm install  # If dependencies changed
   forever restart server.js
   ```

### Useful Commands

- **View running processes**: `forever list`
- **Restart application**: `forever restart server.js`
- **View Apache logs**: `sudo tail -f /opt/bitnami/apache/logs/error_log`
- **Restart Apache**: `sudo /opt/bitnami/ctlscript.sh restart apache` 