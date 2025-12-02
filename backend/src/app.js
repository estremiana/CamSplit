const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import routes
const userRoutes = require('./routes/userRoutes');
const groupRoutes = require('./routes/groupRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const itemRoutes = require('./routes/itemRoutes');
const assignmentRoutes = require('./routes/assignmentRoutes');
const settlementRoutes = require('./routes/settlementRoutes');
const inviteRoutes = require('./routes/inviteRoutes');
const imageRoutes = require('./routes/imageRoutes');

// Import existing routes (to be updated later)
const ocrRoutes = require('./routes/ocrRoutes');

const app = express();

// Middleware
// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow localhost for development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Allow Vercel deployment domain
    if (origin.includes('cam-split.vercel.app')) {
      return callback(null, true);
    }
    
    // Allow Render deployment domain (legacy)
    if (origin.includes('camsplit.onrender.com')) {
      return callback(null, true);
    }
    
    // Allow Flutter app (no origin)
    callback(null, true);
  },
  credentials: true
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'CamSplit API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API routes
app.use('/api/users', userRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api', settlementRoutes);
app.use('/api/invites', inviteRoutes);
app.use('/api/images', imageRoutes);

// Legacy routes (to be updated in Phase 5)
app.use('/api/ocr', ocrRoutes);

// Digital Asset Links for Android Universal Links
app.get('/.well-known/assetlinks.json', (req, res) => {
  res.json([
    {
      "relation": ["delegate_permission/common.handle_all_urls"],
      "target": {
        "namespace": "android_app",
        "package_name": "com.camsplit.app",
        "sha256_cert_fingerprints": [
          "YOUR_ANDROID_SHA256_FINGERPRINT_HERE"
        ]
      }
    }
  ]);
});

// Apple App Site Association for iOS Universal Links
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.json({
    "applinks": {
      "apps": [],
      "details": [
        {
          "appID": "TEAM_ID.com.camsplit.app",
          "paths": ["/join/*"]
        }
      ]
    }
  });
});

// Universal Links - Web fallback for invite links
app.get('/join/:inviteCode', async (req, res) => {
  const { inviteCode } = req.params;
  
  try {
    // Import the invite service
    const InviteService = require('./services/inviteService');
    
    // Get invite details
    const inviteDetails = await InviteService.getInviteDetails(inviteCode);
    
    if (!inviteDetails || !inviteDetails.success) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Invalid Invitation - CamSplit</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
            .container { max-width: 400px; margin: 50px auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
            .logo { font-size: 24px; font-weight: bold; color: #6366f1; margin-bottom: 20px; }
            .error { color: #ef4444; margin: 20px 0; }
            .download-btn { display: inline-block; background: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 10px; }
            .download-btn:hover { background: #4f46e5; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">CamSplit</div>
            <h2>Invalid Invitation</h2>
            <p class="error">This invitation link is invalid or has expired.</p>
            <p>Download CamSplit to create and manage your own expense groups:</p>
            <a href="https://apps.apple.com/app/camsplit" class="download-btn">Download for iOS</a>
            <a href="https://play.google.com/store/apps/details?id=com.camsplit.app" class="download-btn">Download for Android</a>
          </div>
        </body>
        </html>
      `);
    }
    
    const invite = inviteDetails.data;
    
    // Check if invite is expired
    if (invite.expires_at && new Date(invite.expires_at) < new Date()) {
      return res.status(410).send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Expired Invitation - CamSplit</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
            .container { max-width: 400px; margin: 50px auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
            .logo { font-size: 24px; font-weight: bold; color: #6366f1; margin-bottom: 20px; }
            .error { color: #f59e0b; margin: 20px 0; }
            .download-btn { display: inline-block; background: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 10px; }
            .download-btn:hover { background: #4f46e5; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">CamSplit</div>
            <h2>Invitation Expired</h2>
            <p class="error">This invitation has expired.</p>
            <p>Download CamSplit to create and manage your own expense groups:</p>
            <a href="https://apps.apple.com/app/camsplit" class="download-btn">Download for iOS</a>
            <a href="https://play.google.com/store/apps/details?id=com.camsplit.app" class="download-btn">Download for Android</a>
          </div>
        </body>
        </html>
      `);
    }
    
    // Check if invite has reached max uses
    if (invite.current_uses >= invite.max_uses) {
      return res.status(410).send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Invitation Full - CamSplit</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
            .container { max-width: 400px; margin: 50px auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
            .logo { font-size: 24px; font-weight: bold; color: #6366f1; margin-bottom: 20px; }
            .error { color: #f59e0b; margin: 20px 0; }
            .download-btn { display: inline-block; background: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 10px; }
            .download-btn:hover { background: #4f46e5; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">CamSplit</div>
            <h2>Invitation Full</h2>
            <p class="error">This invitation has reached its maximum number of uses.</p>
            <p>Download CamSplit to create and manage your own expense groups:</p>
            <a href="https://apps.apple.com/app/camsplit" class="download-btn">Download for iOS</a>
            <a href="https://play.google.com/store/apps/details?id=com.camsplit.app" class="download-btn">Download for Android</a>
          </div>
        </body>
        </html>
      `);
    }
    
    // Valid invite - show join page
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Join ${invite.group_name} - CamSplit</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
          .container { max-width: 400px; margin: 50px auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
          .logo { font-size: 24px; font-weight: bold; color: #6366f1; margin-bottom: 20px; }
          .group-name { font-size: 20px; font-weight: 600; margin: 15px 0; color: #1f2937; }
          .group-desc { color: #6b7280; margin: 15px 0; }
          .join-btn { display: inline-block; background: #10b981; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; margin: 15px 10px; font-weight: 600; font-size: 16px; }
          .join-btn:hover { background: #059669; }
          .download-btn { display: inline-block; background: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 10px; }
          .download-btn:hover { background: #4f46e5; }
          .info { background: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0; font-size: 14px; color: #6b7280; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">CamSplit</div>
          <h2>You're invited!</h2>
          <div class="group-name">${invite.group_name}</div>
          ${invite.group_description ? `<div class="group-desc">${invite.group_description}</div>` : ''}
          <div class="info">
            <strong>Tap the button below to join this group in CamSplit</strong><br>
            If you don't have the app, you'll be redirected to download it.
          </div>
          <a href="camsplit://join/${inviteCode}" class="join-btn">Join Group</a>
          <br><br>
          <p>Don't have CamSplit?</p>
          <a href="https://apps.apple.com/app/camsplit" class="download-btn">Download for iOS</a>
          <a href="https://play.google.com/store/apps/details?id=com.camsplit.app" class="download-btn">Download for Android</a>
        </div>
        <script>
          // Auto-redirect to app if possible
          setTimeout(() => {
            window.location.href = 'camsplit://join/${inviteCode}';
          }, 2000);
        </script>
      </body>
      </html>
    `);
    
  } catch (error) {
    console.error('Error handling invite link:', error);
    res.status(500).send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Error - CamSplit</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
          .container { max-width: 400px; margin: 50px auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
          .logo { font-size: 24px; font-weight: bold; color: #6366f1; margin-bottom: 20px; }
          .error { color: #ef4444; margin: 20px 0; }
          .download-btn { display: inline-block; background: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 10px; }
          .download-btn:hover { background: #4f46e5; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">CamSplit</div>
          <h2>Something went wrong</h2>
          <p class="error">Unable to load invitation details.</p>
          <p>Download CamSplit to create and manage your own expense groups:</p>
          <a href="https://apps.apple.com/app/camsplit" class="download-btn">Download for iOS</a>
          <a href="https://play.google.com/store/apps/details?id=com.camsplit.app" class="download-btn">Download for Android</a>
        </div>
      </body>
      </html>
    `);
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  
  // Handle specific error types
  if (error.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: error.errors
    });
  }
  
  if (error.name === 'UnauthorizedError') {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized access'
    });
  }
  
  // Default error response
  res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : error.message
  });
});

module.exports = app;

// Only start the server if this file is run directly
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  const HOST = process.env.HOST || '0.0.0.0'; // Listen on all network interfaces
  app.listen(PORT, HOST, () => {
    console.log(`🚀 CamSplit API server running on ${HOST}:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
    console.log(`🌐 External access: http://YOUR_COMPUTER_IP:${PORT}/api`);
  });
} 