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

  if (fs.existsSync(serviceAccountPath)) {
    // Prefer explicit service account JSON for server usage
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log(`Initialized Firebase Admin using service account at: ${serviceAccountPath}`);
  } else {
    // Fall back to Application Default Credentials (ADC) if available
    // e.g. set by `gcloud auth application-default login` or via environment
    try {
      admin.initializeApp();
      console.log('Initialized Firebase Admin using Application Default Credentials');
    } catch (err) {
      console.error('Failed to initialize Firebase Admin. Provide a serviceAccountKey.json or set ADC.');
      throw err;
    }
  }

  return admin.firestore();
}

module.exports = initFirestore();
