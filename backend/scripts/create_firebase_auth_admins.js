/**
 * Create Firebase Auth Admin Users Script
 * 
 * This script creates admin accounts in Firebase Authentication.
 * Unlike Firestore-only users, Firebase Auth users persist across deployments
 * and don't need re-seeding.
 * 
 * The script:
 * 1. Creates users in Firebase Authentication (email/password)
 * 2. Sets custom claims for role-based access
 * 3. Creates/updates a profile document in Firestore (system_users collection)
 * 
 * Usage:
 *   cd backend
 *   npm install
 *   
 *   # Option 1: Set environment variables directly
 *   set ADMIN_EMAIL=admin@vserve.gov.ph
 *   set ADMIN_PASSWORD=Admin@2024!Secure
 *   node scripts/create_firebase_auth_admins.js
 *   
 *   # Option 2: Create a .env file in the backend folder
 *   node scripts/create_firebase_auth_admins.js
 * 
 * Environment Variables:
 *   ADMIN_NAME, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_DEPARTMENT (for admin user)
 *   VIEWER_NAME, VIEWER_EMAIL, VIEWER_PASSWORD, VIEWER_DEPARTMENT (for viewer user)
 * 
 * Note: Requires a valid serviceAccountKey.json in the backend folder or
 * set SERVICE_ACCOUNT_PATH environment variable.
 */

const path = require('path');
const admin = require('firebase-admin');

// Load environment variables from .env file if it exists
try {
  require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
} catch (e) {
  // dotenv not installed or .env not found - use system environment variables
}

// Initialize Firebase Admin SDK
function initFirebase() {
  if (admin.apps.length) return;

  const envPath = process.env.SERVICE_ACCOUNT_PATH;
  const defaultPath = path.join(__dirname, '..', 'serviceAccountKey.json');
  const serviceAccountPath = envPath ? path.resolve(envPath) : defaultPath;

  // Try environment variable first (for CI/CD)
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('Initialized Firebase Admin using FIREBASE_SERVICE_ACCOUNT_JSON env var');
      return;
    } catch (err) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON:', err.message);
    }
  }

  // Try individual env vars
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      console.log('Initialized Firebase Admin using individual env vars');
      return;
    } catch (err) {
      console.error('Failed to init with individual env vars:', err.message);
    }
  }

  // Try service account file
  const fs = require('fs');
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log(`Initialized Firebase Admin using service account at: ${serviceAccountPath}`);
    return;
  }

  throw new Error('No Firebase credentials found. Provide serviceAccountKey.json or set environment variables.');
}

// Build admin users array from environment variables
function buildAdminUsers() {
  const users = [];
  
  // Admin user (Full access)
  if (process.env.ADMIN_EMAIL && process.env.ADMIN_PASSWORD) {
    users.push({
      name: process.env.ADMIN_NAME || 'Admin User',
      email: process.env.ADMIN_EMAIL,
      password: process.env.ADMIN_PASSWORD,
      role: 'administrator',
      department: process.env.ADMIN_DEPARTMENT || 'IT Administration',
    });
  }
  
  // Viewer user (Read-only access)
  if (process.env.VIEWER_EMAIL && process.env.VIEWER_PASSWORD) {
    users.push({
      name: process.env.VIEWER_NAME || 'Viewer User',
      email: process.env.VIEWER_EMAIL,
      password: process.env.VIEWER_PASSWORD,
      role: 'viewer',
      department: process.env.VIEWER_DEPARTMENT || 'Building Permits',
    });
  }
  
  return users;
}

/**
 * Create or update a user in Firebase Authentication
 * @param {Object} userData - User data with email, password, name, role, department
 * @returns {Object} - Created/updated user record
 */
async function createOrUpdateAuthUser(userData) {
  const auth = admin.auth();
  const db = admin.firestore();
  
  let userRecord;
  let isNewUser = false;
  
  try {
    // Try to get existing user
    userRecord = await auth.getUserByEmail(userData.email.toLowerCase());
    console.log(`  Found existing Firebase Auth user: ${userData.email}`);
    
    // Update password if user exists
    userRecord = await auth.updateUser(userRecord.uid, {
      password: userData.password,
      displayName: userData.name,
    });
    console.log(`  Updated password and display name for: ${userData.email}`);
    
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      // Create new user
      userRecord = await auth.createUser({
        email: userData.email.toLowerCase(),
        password: userData.password,
        displayName: userData.name,
        emailVerified: true, // Admin-created users are pre-verified
      });
      isNewUser = true;
      console.log(`  Created new Firebase Auth user: ${userData.email}`);
    } else {
      throw error;
    }
  }
  
  // Set custom claims for role-based access
  await auth.setCustomUserClaims(userRecord.uid, {
    role: userData.role,
    isAdmin: userData.role === 'administrator',
  });
  console.log(`  Set custom claims: role=${userData.role}, isAdmin=${userData.role === 'administrator'}`);
  
  // Create/update profile in Firestore (system_users collection)
  const profileData = {
    name: userData.name,
    email: userData.email.toLowerCase(),
    role: userData.role === 'administrator' ? 'Administrator' : 'Viewer',
    department: userData.department,
    status: 'Active',
    firebaseUid: userRecord.uid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  
  if (isNewUser) {
    profileData.createdAt = admin.firestore.FieldValue.serverTimestamp();
  }
  
  // Use the Firebase Auth UID as the document ID for easy lookups
  await db.collection('system_users').doc(userRecord.uid).set(profileData, { merge: true });
  console.log(`  Updated Firestore profile for: ${userData.email}`);
  
  return { userRecord, isNewUser };
}

async function main() {
  console.log('=== Firebase Auth Admin User Setup ===\n');
  
  initFirebase();
  
  const users = buildAdminUsers();
  
  if (users.length === 0) {
    console.log('⚠️  No users configured!');
    console.log('\nPlease set environment variables or create a .env file.');
    console.log('Required variables for each user type:');
    console.log('  ADMIN_EMAIL, ADMIN_PASSWORD');
    console.log('  VIEWER_EMAIL, VIEWER_PASSWORD');
    console.log('\nOptional variables:');
    console.log('  ADMIN_NAME, ADMIN_DEPARTMENT');
    console.log('  VIEWER_NAME, VIEWER_DEPARTMENT');
    console.log('\nSee .env.example for a template.');
    process.exit(1);
  }
  
  const results = {
    created: [],
    updated: [],
    errors: [],
  };
  
  for (const user of users) {
    console.log(`\nProcessing: ${user.email} (${user.role})`);
    try {
      const { userRecord, isNewUser } = await createOrUpdateAuthUser(user);
      if (isNewUser) {
        results.created.push({ email: user.email, role: user.role, uid: userRecord.uid });
      } else {
        results.updated.push({ email: user.email, role: user.role, uid: userRecord.uid });
      }
    } catch (error) {
      console.error(`  ❌ Error: ${error.message}`);
      results.errors.push({ email: user.email, error: error.message });
    }
  }
  
  console.log('\n=== Summary ===');
  
  if (results.created.length > 0) {
    console.log('\n✅ Created users:');
    results.created.forEach(u => console.log(`   - ${u.email} (${u.role}) [UID: ${u.uid}]`));
  }
  
  if (results.updated.length > 0) {
    console.log('\n🔄 Updated users:');
    results.updated.forEach(u => console.log(`   - ${u.email} (${u.role}) [UID: ${u.uid}]`));
  }
  
  if (results.errors.length > 0) {
    console.log('\n❌ Errors:');
    results.errors.forEach(u => console.log(`   - ${u.email}: ${u.error}`));
  }
  
  console.log('\n=== Setup Complete ===');
  console.log('\n📝 Notes:');
  console.log('   - Users can now sign in using Firebase Authentication');
  console.log('   - Custom claims (role) are set for server-side verification');
  console.log('   - Profile data is stored in Firestore (system_users collection)');
  console.log('   - These users persist across deployments - no re-seeding needed!');
  
  process.exit(results.errors.length > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
