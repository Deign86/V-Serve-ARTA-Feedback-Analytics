const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// Load environment variables from .env when present
try {
  require('dotenv').config();
} catch (e) {
  // ignore if dotenv isn't available — it's optional in some environments
}

// Allow overriding the service account path from env (SERVICE_ACCOUNT_PATH)
const envPath = process.env.SERVICE_ACCOUNT_PATH;
const defaultPath = path.join(__dirname, '..', 'serviceAccountKey.json');
const serviceAccountPath = envPath ? path.resolve(envPath) : defaultPath;

function initFirestore() {
  if (admin.apps.length) return admin.firestore();

  // Option 1: Use FIREBASE_SERVICE_ACCOUNT_JSON env var (for Vercel/serverless)
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('Initialized Firebase Admin using FIREBASE_SERVICE_ACCOUNT_JSON env var');
      return admin.firestore();
    } catch (err) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON:', err.message);
    }
  }

  // Option 2: Use individual env vars for service account fields
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          // Handle escaped newlines in private key
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      console.log('Initialized Firebase Admin using individual env vars');
      return admin.firestore();
    } catch (err) {
      console.error('Failed to init with individual env vars:', err.message);
    }
  }

  // Option 3: Use serviceAccountKey.json file (for local dev)
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log(`Initialized Firebase Admin using service account at: ${serviceAccountPath}`);
    return admin.firestore();
  }

  // Option 4: Fall back to Application Default Credentials (ADC)
  try {
    admin.initializeApp();
    console.log('Initialized Firebase Admin using Application Default Credentials');
    return admin.firestore();
  } catch (err) {
    console.error('Failed to initialize Firebase Admin. Set FIREBASE_SERVICE_ACCOUNT_JSON env var or provide serviceAccountKey.json');
    throw err;
  }
}

module.exports = initFirestore();
