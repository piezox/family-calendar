const express = require('express');
const { google } = require('googleapis');
const { OAuth2Client } = require('google-auth-library');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const session = require('express-session');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: process.env.SESSION_SECRET || 'family-calendar-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: process.env.NODE_ENV === 'production',
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// Password protection middleware
const passwordProtect = (req, res, next) => {
  // Skip authentication for login page and login POST request
  if (req.path === '/login' || req.path === '/auth/login') {
    return next();
  }
  
  // Check if user is authenticated
  if (req.session.authenticated) {
    return next();
  }
  
  // Redirect to login page
  res.redirect('/login');
};

// Apply password protection to all routes except static files
app.use(express.static('public'));
app.use(passwordProtect);

// OAuth2 setup
const oauth2Client = new OAuth2Client(
  process.env.CLIENT_ID,
  process.env.CLIENT_SECRET,
  process.env.REDIRECT_URI
);

// Token storage path - use environment variable in production
const TOKEN_PATH = process.env.NODE_ENV === 'production' 
  ? process.env.TOKEN_DATA // Store token in environment variable in production
  : path.join(__dirname, 'token.json'); // Use file in development

// Check if we have a stored token
let tokenExists = false;
try {
  let tokenData;
  if (process.env.NODE_ENV === 'production' && process.env.TOKEN_DATA) {
    // In production, get token from environment variable
    tokenData = process.env.TOKEN_DATA;
    oauth2Client.setCredentials(JSON.parse(tokenData));
    tokenExists = true;
  } else {
    // In development, get token from file
    tokenData = fs.readFileSync(TOKEN_PATH);
    oauth2Client.setCredentials(JSON.parse(tokenData));
    tokenExists = true;
  }
} catch (error) {
  console.log('No token found, authentication will be required');
}

// Calendar API setup
const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

// Routes
app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.post('/auth/login', (req, res) => {
  const { password } = req.body;
  const correctPassword = process.env.APP_PASSWORD || 'family';
  
  if (password === correctPassword) {
    req.session.authenticated = true;
    res.redirect('/');
  } else {
    res.redirect('/login?error=1');
  }
});

app.get('/logout', (req, res) => {
  req.session.authenticated = false;
  res.redirect('/login');
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Auth routes
app.get('/auth/status', (req, res) => {
  res.json({ authenticated: tokenExists });
});

app.get('/auth/url', (req, res) => {
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: ['https://www.googleapis.com/auth/calendar.readonly'],
    prompt: 'consent' // Force to get refresh token
  });
  res.json({ url: authUrl });
});

app.get('/auth/callback', async (req, res) => {
  const { code } = req.query;
  try {
    const { tokens } = await oauth2Client.getToken(code);
    oauth2Client.setCredentials(tokens);
    
    // Store token for future use
    if (process.env.NODE_ENV === 'production') {
      // In production, we should store this securely
      console.log('Token received in production. Update TOKEN_DATA environment variable with:');
      console.log(JSON.stringify(tokens));
      // You would typically store this in a secure parameter store or database in production
    } else {
      // In development, store in file
      fs.writeFileSync(TOKEN_PATH, JSON.stringify(tokens));
    }
    tokenExists = true;
    
    res.redirect('/');
  } catch (error) {
    console.error('Error retrieving access token', error);
    res.status(500).send('Authentication failed');
  }
});

// Simple function to estimate travel time without any API calls
function estimateTravelTime(destination) {
  // Check for common locations and return hardcoded estimates
  if (destination.includes("Stanford")) {
    return {
      duration: "15 mins",
      distance: "5.5 miles",
      mode: "driving (estimated)"
    };
  } else if (destination.includes("Palo Alto")) {
    return {
      duration: "10 mins",
      distance: "3.5 miles",
      mode: "driving (estimated)"
    };
  } else if (destination.includes("Menlo Park")) {
    return {
      duration: "12 mins",
      distance: "4 miles",
      mode: "driving (estimated)"
    };
  } else if (destination.includes("San Jose")) {
    return {
      duration: "25 mins",
      distance: "15 miles",
      mode: "driving (estimated)"
    };
  } else if (destination.includes("San Francisco")) {
    return {
      duration: "45 mins",
      distance: "35 miles",
      mode: "driving (estimated)"
    };
  } else {
    // Default estimate for unknown locations
    return {
      duration: "20 mins",
      distance: "10 miles",
      mode: "driving (estimated)"
    };
  }
}

// Calendar API routes
app.get('/api/events/today', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const response = await calendar.events.list({
      calendarId: process.env.CALENDAR_ID,
      timeMin: today.toISOString(),
      timeMax: tomorrow.toISOString(),
      singleEvents: true,
      orderBy: 'startTime',
    });
    
    // Process each event to add duration and travel time
    const eventsWithDetails = await Promise.all(response.data.items.map(async event => {
      const start = new Date(event.start.dateTime || event.start.date);
      const end = new Date(event.end.dateTime || event.end.date);
      const duration = (end - start) / (1000 * 60); // Duration in minutes

      let travelTime = null;
      if (event.location) {
        // Use our simple estimation instead of API call
        travelTime = estimateTravelTime(event.location);
        console.log('Estimated travel time for:', event.location);
        console.log('Estimate:', travelTime);
      }

      return {
        summary: event.summary,
        start: start,
        end: end,
        displayTime: start.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
        duration: `${duration} minutes`,
        location: event.location || 'No location specified',
        travelTime,
        description: event.description || ''
      };
    }));
    
    res.json(eventsWithDetails);
  } catch (error) {
    console.error('Error fetching events', error);
    
    // Handle token expiration
    if (error.response && error.response.status === 401) {
      // Try to refresh the token
      try {
        const tokens = JSON.parse(fs.readFileSync(TOKEN_PATH));
        if (tokens.refresh_token) {
          oauth2Client.setCredentials({
            refresh_token: tokens.refresh_token
          });
          await oauth2Client.refreshAccessToken();
          // Retry the request
          return res.redirect('/api/events/today');
        }
      } catch (refreshError) {
        console.error('Error refreshing token', refreshError);
        tokenExists = false;
      }
    }
    
    res.status(500).json({ error: 'Failed to fetch events' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
