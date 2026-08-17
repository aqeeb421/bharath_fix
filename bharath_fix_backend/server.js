/**
 * BharathFix Centralized Backend Server & FCM Push Notification Engine
 * Entry Point (server.js)
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const FcmEngine = require('./services/fcm_engine');
const createAdminRoutes = require('./routes/admin_routes');

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS & JSON parsing
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
let fcmEngine = null;
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './serviceAccountKey.json';
const absoluteKeyPath = path.resolve(__dirname, serviceAccountPath);

if (fs.existsSync(absoluteKeyPath)) {
  try {
    const serviceAccount = require(absoluteKeyPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin SDK Initialized Successfully!');

    // Initialize & Start FCM Real-Time Event Engine
    fcmEngine = new FcmEngine(admin);
    fcmEngine.startListener();
  } catch (error) {
    console.error('❌ Error initializing Firebase Admin SDK:', error.message);
  }
} else {
  console.log('\n================================================================');
  console.log('⚠️  NOTICE: serviceAccountKey.json not found in server root.');
  console.log('👉 To enable live FCM push notifications & Firestore sync:');
  console.log('   1. Go to Firebase Console -> Project Settings -> Service Accounts');
  console.log('   2. Click "Generate New Private Key"');
  console.log(`   3. Save the downloaded JSON file as: ${absoluteKeyPath}`);
  console.log('================================================================\n');

  // Initialize Firebase Admin without credentials for development fallback
  try {
    admin.initializeApp();
    fcmEngine = new FcmEngine(admin);
  } catch (_) {
    console.log('ℹ️ Server running in Standalone REST API Mode.');
  }
}

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'BharathFix Centralized Backend & FCM Engine',
    timestamp: new Date().toISOString(),
    firebaseAdminActive: admin.apps.length > 0,
    fcmEngineListening: fcmEngine ? fcmEngine.isListening : false
  });
});

// Admin REST APIs
if (admin.apps.length > 0 && fcmEngine) {
  app.use('/api/admin', createAdminRoutes(admin, fcmEngine));
} else {
  app.use('/api/admin', (req, res) => {
    res.status(503).json({
      success: false,
      message: 'Firebase Admin SDK not initialized. Please provide serviceAccountKey.json.'
    });
  });
}

// Default 404 Route
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start HTTP Server
app.listen(PORT, () => {
  console.log(`🚀 BharathFix Backend Server listening on http://localhost:${PORT}`);
  console.log(`📊 Health Check: http://localhost:${PORT}/health`);

  // Render.com Free Tier Keep-Alive Self-Ping (Prevents server from sleeping after 15 min idle)
  const renderExternalUrl = process.env.RENDER_EXTERNAL_URL || process.env.SERVER_URL;
  if (renderExternalUrl) {
    const healthEndpoint = `${renderExternalUrl.replace(/\/$/, '')}/health`;
    const TEN_MINUTES = 10 * 60 * 1000;

    console.log(`⏰ Initialized Keep-Alive Self-Ping for Render: ${healthEndpoint} (Interval: 10m)`);

    setInterval(() => {
      const httpClient = healthEndpoint.startsWith('https') ? require('https') : require('http');
      httpClient.get(healthEndpoint, (res) => {
        console.log(`⏰ Keep-Alive Ping Sent to ${healthEndpoint} -> HTTP ${res.statusCode}`);
      }).on('error', (err) => {
        console.error(`⚠️ Keep-Alive Ping Failed: ${err.message}`);
      });
    }, TEN_MINUTES);
  } else {
    console.log('💡 TIP: Set RENDER_EXTERNAL_URL environment variable on Render dashboard to enable automated keep-alive self-pings.');
  }
});
