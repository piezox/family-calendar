# CLAUDE.md - Family Calendar Server

## Build & Run Commands
- `npm install` - Install dependencies
- `npm start` - Run production server
- `npm run dev` - Run development server with hot reloading via nodemon

## Environment Variables (.env)
Required variables:
- CLIENT_ID - Google OAuth client ID
- CLIENT_SECRET - Google OAuth client secret
- REDIRECT_URI - OAuth redirect URI
- CALENDAR_ID - Google Calendar ID to fetch events from
- GOOGLE_MAPS_API_KEY - For travel time calculations
- HOME_ADDRESS - Base location for travel calculations

## Code Style Guidelines
- **Formatting**: Use 2-space indentation
- **Imports**: Group imports logically (Node built-ins, then external packages, then local modules)
- **Error Handling**: Use try/catch blocks with specific error messages
- **Naming**: camelCase for variables/functions, UPPER_CASE for constants
- **Component Structure**: Express routes grouped by functionality
- **Environment Checks**: Use process.env.NODE_ENV to differentiate between production and development
- **API Responses**: Consistent JSON response structure with appropriate HTTP status codes
- **Comments**: Add descriptive comments for non-obvious functionality
- **File Organization**: Modularize routes and services in larger applications
- **Security**: Never commit .env files or tokens to the repository