// V-Serve ARTA Backend API
// Provides HTTP endpoints for Flutter app (especially Windows native)
// Connects to Firebase/Firestore via Admin SDK

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs'); // Keep for legacy password verification
const admin = require('firebase-admin');

// Load dotenv so PORT and other env vars can be set from .env
try {
  require('dotenv').config();
} catch (e) { }

const db = require('./firestore');

// Get Firebase Auth instance (firestore.js initializes the admin app)
const auth = admin.auth();

// Firebase Auth REST API configuration
// Used to verify email/password credentials via HTTP (server-side)
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY || 'AIzaSyDz4QYoJfpGqPPzXHfGhj7jNFvPNZeZZEI';
const FIREBASE_AUTH_URL = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;

/**
 * Verify user credentials via Firebase Auth REST API
 * @param {string} email - User email
 * @param {string} password - User password
 * @returns {Object|null} - Firebase user data or null if invalid
 */
async function verifyFirebaseCredentials(email, password) {
  try {
    const response = await fetch(FIREBASE_AUTH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      console.log('Firebase Auth error:', error.error?.message || 'Unknown error');
      return null;
    }

    const data = await response.json();
    return {
      uid: data.localId,
      email: data.email,
      idToken: data.idToken,
      refreshToken: data.refreshToken,
    };
  } catch (err) {
    console.error('Firebase Auth verification error:', err);
    return null;
  }
}

const app = express();

// CORS configuration - allow all origins for now (Vercel handles security)
// This ensures both web frontend and Windows app can access the API
app.use(cors({
  origin: true, // Allow all origins
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));

// Collection names (matching existing Firestore structure)
const COLLECTIONS = {
  FEEDBACKS: 'feedbacks',
  SYSTEM_USERS: 'system_users',
  AUDIT_LOGS: 'audit_logs',
  SURVEY_CONFIG: 'survey_config',
  SURVEY_QUESTIONS: 'survey_questions',
  ALERTS: 'alerts',
  PUSH_SUBSCRIPTIONS: 'push_subscriptions',
};

// Web Push support (optional)
let webpush = null;
try {
  webpush = require('web-push');
} catch (e) {
  console.log('web-push module not available; push endpoints will be disabled');
}

// VAPID keys should be set via environment variables in production
const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY || process.env.WEB_PUSH_PUBLIC || null;
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY || process.env.WEB_PUSH_PRIVATE || null;
if (webpush && VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY) {
  try {
    webpush.setVapidDetails(
      process.env.WEB_PUSH_SUBJECT || `mailto:${process.env.ADMIN_EMAIL || 'admin@example.com'}`,
      VAPID_PUBLIC_KEY,
      VAPID_PRIVATE_KEY
    );
    console.log('web-push configured with VAPID keys');
  } catch (e) {
    console.error('Failed to configure web-push VAPID keys:', e);
  }
}

// =============================================================================
// HEALTH CHECK
// =============================================================================

app.get('/ping', (req, res) => {
  res.json({ ok: true, time: new Date().toISOString(), version: '1.1.0' });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

// =============================================================================
// AUTHENTICATION ENDPOINTS
// =============================================================================

/**
 * POST /auth/login
 * Authenticates a user with email and password
 * 
 * Authentication flow:
 * 1. Try Firebase Auth first (new users created via create_firebase_auth_admins.js)
 * 2. Fall back to bcrypt verification (legacy users in Firestore)
 * 
 * This ensures backward compatibility while migrating to Firebase Auth
 */
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    let firebaseUser = null;
    let userDoc = null;
    let userData = null;

    // Step 1: Try Firebase Auth verification first
    firebaseUser = await verifyFirebaseCredentials(normalizedEmail, password);

    if (firebaseUser) {
      // Firebase Auth succeeded - get profile from Firestore
      // Try to find by Firebase UID first, then by email
      const byUidSnapshot = await db.collection(COLLECTIONS.SYSTEM_USERS)
        .doc(firebaseUser.uid)
        .get();

      if (byUidSnapshot.exists) {
        userDoc = byUidSnapshot;
        userData = byUidSnapshot.data();
      } else {
        // Fall back to email lookup (for migration period)
        const byEmailSnapshot = await db.collection(COLLECTIONS.SYSTEM_USERS)
          .where('email', '==', normalizedEmail)
          .limit(1)
          .get();

        if (!byEmailSnapshot.empty) {
          userDoc = byEmailSnapshot.docs[0];
          userData = userDoc.data();
          
          // Migrate: link Firebase UID to existing profile
          await userDoc.ref.update({ firebaseUid: firebaseUser.uid });
        }
      }

      // If no Firestore profile exists, create one from Firebase Auth data
      if (!userData) {
        // Get custom claims for role
        const firebaseUserRecord = await auth.getUser(firebaseUser.uid);
        const claims = firebaseUserRecord.customClaims || {};
        
        userData = {
          name: firebaseUserRecord.displayName || normalizedEmail.split('@')[0],
          email: normalizedEmail,
          role: claims.isAdmin ? 'Administrator' : (claims.role || 'Viewer'),
          department: '',
          status: 'Active',
          firebaseUid: firebaseUser.uid,
          createdAt: new Date(),
        };

        await db.collection(COLLECTIONS.SYSTEM_USERS).doc(firebaseUser.uid).set(userData);
        userDoc = { id: firebaseUser.uid, ref: db.collection(COLLECTIONS.SYSTEM_USERS).doc(firebaseUser.uid) };
      }
    } else {
      // Step 2: Firebase Auth failed - try legacy bcrypt verification
      const usersSnapshot = await db.collection(COLLECTIONS.SYSTEM_USERS)
        .where('email', '==', normalizedEmail)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      userDoc = usersSnapshot.docs[0];
      userData = userDoc.data();

      // Verify password using bcrypt (legacy)
      const passwordHash = userData.passwordHash;
      if (!passwordHash) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const isValidPassword = await bcrypt.compare(password, passwordHash);
      if (!isValidPassword) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }
    }

    // Check if user is active
    if (userData.status && userData.status !== 'Active') {
      return res.status(401).json({ error: 'Account is not active' });
    }

    // Update last login timestamp
    const docRef = userDoc.ref || db.collection(COLLECTIONS.SYSTEM_USERS).doc(userDoc.id);
    await docRef.update({
      lastLogin: new Date(),
    });

    // Return user data (without password hash or tokens)
    res.json({
      success: true,
      user: {
        id: userDoc.id,
        name: userData.name,
        email: userData.email,
        role: userData.role,
        department: userData.department || '',
        createdAt: userData.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
        lastLogin: new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Authentication failed' });
  }
});

/**
 * GET /auth/user
 * Get user by email (for session validation)
 */
app.get('/auth/user', async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const usersSnapshot = await db.collection(COLLECTIONS.SYSTEM_USERS)
      .where('email', '==', email.toLowerCase().trim())
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();

    res.json({
      id: userDoc.id,
      name: userData.name,
      email: userData.email,
      role: userData.role,
      department: userData.department || '',
      status: userData.status,
      createdAt: userData.createdAt?.toDate?.()?.toISOString(),
      lastLogin: userData.lastLogin?.toDate?.()?.toISOString(),
    });
  } catch (err) {
    console.error('Get user error:', err);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

// =============================================================================
// FEEDBACK ENDPOINTS
// =============================================================================

/**
 * POST /feedback
 * Submit a new feedback/survey response
 */
app.post('/feedback', async (req, res) => {
  try {
    const payload = req.body;
    if (!payload || Object.keys(payload).length === 0) {
      return res.status(400).json({ error: 'Empty payload' });
    }

    const docRef = await db.collection(COLLECTIONS.FEEDBACKS).add({
      ...payload,
      createdAt: new Date(),
      submittedAt: payload.submittedAt || new Date().toISOString(),
    });

    const saved = await docRef.get();
    res.status(201).json({ id: docRef.id, data: saved.data() });
  } catch (err) {
    console.error('Create feedback error:', err);
    res.status(500).json({ error: 'Failed to save feedback' });
  }
});

/**
 * GET /feedback/:id
 * Get a specific feedback by ID
 */
app.get('/feedback/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection(COLLECTIONS.FEEDBACKS).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Feedback not found' });
    }

    res.json({ id: doc.id, data: doc.data() });
  } catch (err) {
    console.error('Get feedback error:', err);
    res.status(500).json({ error: 'Failed to read feedback' });
  }
});

/**
 * GET /feedback
 * List feedbacks with optional filtering
 */
app.get('/feedback', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '100', 10), 1000);
    const { startDate, endDate } = req.query;

    let query = db.collection(COLLECTIONS.FEEDBACKS);

    // Date range filtering
    if (startDate) {
      query = query.where('createdAt', '>=', new Date(startDate));
    }
    if (endDate) {
      query = query.where('createdAt', '<=', new Date(endDate));
    }

    // Order by createdAt descending
    query = query.orderBy('createdAt', 'desc').limit(limit);

    const snapshot = await query.get();
    const items = snapshot.docs.map(d => ({
      id: d.id,
      data: {
        ...d.data(),
        createdAt: d.data().createdAt?.toDate?.()?.toISOString(),
        submittedAt: d.data().submittedAt?.toDate?.()?.toISOString() || d.data().submittedAt,
      },
    }));

    res.json({ count: items.length, items });
  } catch (err) {
    console.error('List feedbacks error:', err);
    // Try without ordering if index doesn't exist
    try {
      const limit = Math.min(parseInt(req.query.limit || '100', 10), 1000);
      const snapshot = await db.collection(COLLECTIONS.FEEDBACKS).limit(limit).get();
      const items = snapshot.docs.map(d => ({
        id: d.id,
        data: {
          ...d.data(),
          createdAt: d.data().createdAt?.toDate?.()?.toISOString(),
          submittedAt: d.data().submittedAt?.toDate?.()?.toISOString() || d.data().submittedAt,
        },
      }));
      res.json({ count: items.length, items });
    } catch (fallbackErr) {
      res.status(500).json({ error: 'Failed to list feedbacks' });
    }
  }
});

/**
 * DELETE /feedback/:id
 * Delete a feedback
 */
app.delete('/feedback/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const docRef = db.collection(COLLECTIONS.FEEDBACKS).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Feedback not found' });
    }

    await docRef.delete();
    res.json({ success: true, id });
  } catch (err) {
    console.error('Delete feedback error:', err);
    res.status(500).json({ error: 'Failed to delete feedback' });
  }
});

// =============================================================================
// USER MANAGEMENT ENDPOINTS
// =============================================================================

/**
 * GET /users
 * List all system users
 * Returns users with normalized fields for frontend compatibility
 */
app.get('/users', async (req, res) => {
  try {
    const snapshot = await db.collection(COLLECTIONS.SYSTEM_USERS).get();
    const users = snapshot.docs.map(doc => {
      const data = doc.data();
      
      // Normalize lastLoginAt - handle both Firestore Timestamp and already converted values
      let lastLoginAt = null;
      if (data.lastLogin) {
        lastLoginAt = data.lastLogin?.toDate?.()?.toISOString() || data.lastLogin;
      } else if (data.lastLoginAt) {
        // Handle Firestore Timestamp object
        if (data.lastLoginAt._seconds) {
          lastLoginAt = new Date(data.lastLoginAt._seconds * 1000).toISOString();
        } else if (data.lastLoginAt?.toDate) {
          lastLoginAt = data.lastLoginAt.toDate().toISOString();
        } else {
          lastLoginAt = data.lastLoginAt;
        }
      }
      
      return {
        id: doc.id,
        name: data.name || '',
        email: data.email || '',
        role: data.role || 'Viewer',
        department: data.department || '',
        // Normalize status to isActive boolean for frontend
        isActive: data.status === 'Active',
        status: data.status || 'Active',
        createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
        lastLoginAt: lastLoginAt,
        updatedAt: data.updatedAt?.toDate?.()?.toISOString() || data.updatedAt,
        // Include Firebase UID if available (for reference)
        firebaseUid: data.firebaseUid || null,
      };
    });

    res.json({ count: users.length, users });
  } catch (err) {
    console.error('List users error:', err);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

/**
 * GET /users/:id
 * Get a specific user
 */
app.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection(COLLECTIONS.SYSTEM_USERS).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = doc.data();
    res.json({
      id: doc.id,
      ...userData,
      passwordHash: undefined,
      createdAt: userData.createdAt?.toDate?.()?.toISOString(),
      lastLogin: userData.lastLogin?.toDate?.()?.toISOString(),
      updatedAt: userData.updatedAt?.toDate?.()?.toISOString(),
    });
  } catch (err) {
    console.error('Get user error:', err);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

/**
 * POST /users
 * Create a new system user
 * Creates user in both Firebase Auth and Firestore
 */
app.post('/users', async (req, res) => {
  try {
    const { name, email, password, role, department } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const userRole = role || 'Viewer';
    let firebaseUid = null;

    // Try to create user in Firebase Auth first
    try {
      const firebaseUser = await auth.createUser({
        email: normalizedEmail,
        password: password,
        displayName: name,
        emailVerified: true, // Admin-created users are pre-verified
      });
      firebaseUid = firebaseUser.uid;

      // Set custom claims for role-based access
      await auth.setCustomUserClaims(firebaseUid, {
        role: userRole.toLowerCase(),
        isAdmin: userRole.toLowerCase() === 'administrator',
      });

      console.log(`Created Firebase Auth user: ${normalizedEmail} (UID: ${firebaseUid})`);
    } catch (authError) {
      if (authError.code === 'auth/email-already-exists') {
        // User exists in Firebase Auth - get their UID
        try {
          const existingUser = await auth.getUserByEmail(normalizedEmail);
          firebaseUid = existingUser.uid;
          
          // Update their password and claims
          await auth.updateUser(firebaseUid, {
            password: password,
            displayName: name,
          });
          await auth.setCustomUserClaims(firebaseUid, {
            role: userRole.toLowerCase(),
            isAdmin: userRole.toLowerCase() === 'administrator',
          });
          console.log(`Updated existing Firebase Auth user: ${normalizedEmail}`);
        } catch (updateError) {
          console.error('Failed to update existing Firebase user:', updateError);
          return res.status(409).json({ error: 'Email already exists in authentication system' });
        }
      } else {
        console.error('Firebase Auth error:', authError);
        // Fall back to bcrypt-only mode if Firebase Auth fails
        console.log('Falling back to Firestore-only user creation');
      }
    }

    // Check if user already exists in Firestore
    const existingQuery = await db.collection(COLLECTIONS.SYSTEM_USERS)
      .where('email', '==', normalizedEmail)
      .limit(1)
      .get();

    if (!existingQuery.empty) {
      // Update existing Firestore profile
      const existingDoc = existingQuery.docs[0];
      await existingDoc.ref.update({
        name,
        role: userRole,
        department: department || '',
        status: 'Active',
        firebaseUid: firebaseUid || existingDoc.data().firebaseUid,
        updatedAt: new Date(),
      });
      
      return res.json({
        success: true,
        id: existingDoc.id,
        user: { id: existingDoc.id, name, email: normalizedEmail, role: userRole, department },
        message: 'User updated',
      });
    }

    // Create new Firestore profile
    const userData = {
      name,
      email: normalizedEmail,
      role: userRole,
      department: department || '',
      status: 'Active',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Add Firebase UID if available
    if (firebaseUid) {
      userData.firebaseUid = firebaseUid;
    } else {
      // Fall back to bcrypt password hash if Firebase Auth failed
      userData.passwordHash = await bcrypt.hash(password, 12);
    }

    // Use Firebase UID as document ID if available, otherwise auto-generate
    let docRef;
    if (firebaseUid) {
      docRef = db.collection(COLLECTIONS.SYSTEM_USERS).doc(firebaseUid);
      await docRef.set(userData);
    } else {
      docRef = await db.collection(COLLECTIONS.SYSTEM_USERS).add(userData);
    }

    res.status(201).json({
      success: true,
      id: docRef.id,
      user: { id: docRef.id, name, email: normalizedEmail, role: userRole, department },
    });
  } catch (err) {
    console.error('Create user error:', err);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

/**
 * PUT /users/:id
 * Update a system user
 * Updates both Firebase Auth and Firestore
 */
app.put('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, password, role, department, status } = req.body;

    const docRef = db.collection(COLLECTIONS.SYSTEM_USERS).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const existingData = doc.data();
    const firebaseUid = existingData.firebaseUid || id; // ID might be the Firebase UID

    const updateData = {
      updatedAt: new Date(),
    };

    if (name) updateData.name = name;
    if (email) updateData.email = email.toLowerCase().trim();
    if (role) updateData.role = role;
    if (department !== undefined) updateData.department = department;
    if (status) updateData.status = status;

    // Update Firebase Auth user if they exist
    try {
      const firebaseUpdateData = {};
      if (name) firebaseUpdateData.displayName = name;
      if (email) firebaseUpdateData.email = email.toLowerCase().trim();
      if (password) firebaseUpdateData.password = password;
      if (status === 'Inactive') firebaseUpdateData.disabled = true;
      if (status === 'Active') firebaseUpdateData.disabled = false;

      if (Object.keys(firebaseUpdateData).length > 0) {
        await auth.updateUser(firebaseUid, firebaseUpdateData);
        console.log(`Updated Firebase Auth user: ${firebaseUid}`);
      }

      // Update custom claims if role changed
      if (role) {
        await auth.setCustomUserClaims(firebaseUid, {
          role: role.toLowerCase(),
          isAdmin: role.toLowerCase() === 'administrator',
        });
      }
    } catch (authError) {
      // Firebase Auth user might not exist (legacy user)
      if (authError.code !== 'auth/user-not-found') {
        console.error('Firebase Auth update error:', authError);
      }
      
      // Fall back to bcrypt password hash for legacy users
      if (password) {
        updateData.passwordHash = await bcrypt.hash(password, 12);
      }
    }

    await docRef.update(updateData);

    res.json({ success: true, id });
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

/**
 * DELETE /users/:id
 * Delete a system user (or set status to Inactive)
 * Also handles Firebase Auth user deletion/disabling
 */
app.delete('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { hardDelete } = req.query;

    const docRef = db.collection(COLLECTIONS.SYSTEM_USERS).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = doc.data();
    const firebaseUid = userData.firebaseUid || id;

    // Handle Firebase Auth user
    try {
      if (hardDelete === 'true') {
        await auth.deleteUser(firebaseUid);
        console.log(`Deleted Firebase Auth user: ${firebaseUid}`);
      } else {
        await auth.updateUser(firebaseUid, { disabled: true });
        console.log(`Disabled Firebase Auth user: ${firebaseUid}`);
      }
    } catch (authError) {
      if (authError.code !== 'auth/user-not-found') {
        console.error('Firebase Auth delete/disable error:', authError);
      }
    }

    // Handle Firestore document
    if (hardDelete === 'true') {
      await docRef.delete();
    } else {
      // Soft delete - mark as inactive
      await docRef.update({ status: 'Inactive', updatedAt: new Date() });
    }

    res.json({ success: true, id });
  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// =============================================================================
// USER ROUTE ALIASES (for frontend compatibility)
// Frontend uses /auth/users, backend has /users - support both
// =============================================================================

app.get('/auth/users', (req, res, next) => {
  req.url = '/users';
  app._router.handle(req, res, next);
});

app.post('/auth/users', (req, res, next) => {
  req.url = '/users';
  app._router.handle(req, res, next);
});

app.get('/auth/users/:id', (req, res, next) => {
  req.url = `/users/${req.params.id}`;
  app._router.handle(req, res, next);
});

app.patch('/auth/users/:id', async (req, res) => {
  // PATCH handler - handles partial updates from frontend
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const docRef = db.collection(COLLECTIONS.SYSTEM_USERS).doc(id);
    const doc = await docRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const firestoreUpdates = {
      updatedAt: new Date(),
    };
    
    // Handle password update if provided
    if (updates.password) {
      firestoreUpdates.passwordHash = await bcrypt.hash(updates.password, 10);
    }
    
    // Convert isActive boolean to status string for Firestore storage
    if (updates.isActive !== undefined) {
      firestoreUpdates.status = updates.isActive ? 'Active' : 'Inactive';
    }
    
    // Copy other allowed fields
    if (updates.name) firestoreUpdates.name = updates.name;
    if (updates.email) firestoreUpdates.email = updates.email.toLowerCase().trim();
    if (updates.role) firestoreUpdates.role = updates.role;
    if (updates.department !== undefined) firestoreUpdates.department = updates.department;
    if (updates.status) firestoreUpdates.status = updates.status;
    
    await docRef.update(firestoreUpdates);
    
    const updatedDoc = await docRef.get();
    const userData = updatedDoc.data();
    
    res.json({
      success: true,
      user: {
        id: updatedDoc.id,
        name: userData.name,
        email: userData.email,
        role: userData.role,
        department: userData.department,
        isActive: userData.status === 'Active',
        status: userData.status,
        createdAt: userData.createdAt?.toDate?.()?.toISOString(),
        lastLoginAt: userData.lastLogin?.toDate?.()?.toISOString() || userData.lastLoginAt,
        updatedAt: userData.updatedAt?.toDate?.()?.toISOString(),
      }
    });
  } catch (err) {
    console.error('Patch user error:', err);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

app.delete('/auth/users/:id', async (req, res) => {
  // DELETE handler - full implementation (not a redirect)
  try {
    const { id } = req.params;
    const { hardDelete } = req.query;

    console.log(`DELETE /auth/users/${id} - hardDelete: ${hardDelete}`);

    const docRef = db.collection(COLLECTIONS.SYSTEM_USERS).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log(`User not found: ${id}`);
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = doc.data();
    const firebaseUid = userData.firebaseUid || id;

    // Handle Firebase Auth user
    try {
      if (hardDelete === 'true') {
        await auth.deleteUser(firebaseUid);
        console.log(`Deleted Firebase Auth user: ${firebaseUid}`);
      } else {
        await auth.updateUser(firebaseUid, { disabled: true });
        console.log(`Disabled Firebase Auth user: ${firebaseUid}`);
      }
    } catch (authError) {
      if (authError.code !== 'auth/user-not-found') {
        console.error('Firebase Auth delete/disable error:', authError);
      }
    }

    // Handle Firestore document
    if (hardDelete === 'true') {
      await docRef.delete();
      console.log(`Hard deleted Firestore document: ${id}`);
    } else {
      // Soft delete - mark as inactive
      await docRef.update({ status: 'Inactive', updatedAt: new Date() });
      console.log(`Soft deleted (deactivated) user: ${id}`);
    }

    res.json({ success: true, id });
  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// =============================================================================
// AUDIT LOG ENDPOINTS
// =============================================================================

/**
 * GET /audit-logs
 * List audit logs with filtering
 */
app.get('/audit-logs', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '100', 10), 1000);
    const { actionType, actorId, startDate, endDate } = req.query;

    let query = db.collection(COLLECTIONS.AUDIT_LOGS);

    if (actionType) {
      query = query.where('actionType', '==', actionType);
    }
    if (actorId) {
      query = query.where('actorId', '==', actorId);
    }

    query = query.orderBy('timestamp', 'desc').limit(limit);

    const snapshot = await query.get();
    const logs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate?.()?.toISOString(),
    }));

    res.json({ count: logs.length, logs });
  } catch (err) {
    console.error('List audit logs error:', err);
    // Fallback without ordering
    try {
      const snapshot = await db.collection(COLLECTIONS.AUDIT_LOGS)
        .limit(100)
        .get();
      const logs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate?.()?.toISOString(),
      }));
      res.json({ count: logs.length, logs });
    } catch (fallbackErr) {
      res.status(500).json({ error: 'Failed to list audit logs' });
    }
  }
});

/**
 * POST /audit-logs
 * Create an audit log entry
 */
app.post('/audit-logs', async (req, res) => {
  try {
    const logEntry = req.body;

    if (!logEntry.actionType || !logEntry.actionDescription) {
      return res.status(400).json({ error: 'actionType and actionDescription are required' });
    }

    const docRef = await db.collection(COLLECTIONS.AUDIT_LOGS).add({
      ...logEntry,
      timestamp: new Date(),
    });

    res.status(201).json({ success: true, id: docRef.id });
  } catch (err) {
    console.error('Create audit log error:', err);
    res.status(500).json({ error: 'Failed to create audit log' });
  }
});

// =============================================================================
// SURVEY CONFIG ENDPOINTS
// =============================================================================

/**
 * GET /survey-config
 * Get current survey configuration
 */
app.get('/survey-config', async (req, res) => {
  try {
    const doc = await db.collection(COLLECTIONS.SURVEY_CONFIG).doc('current').get();

    if (!doc.exists) {
      // Return defaults if no config exists
      return res.json({
        ccEnabled: true,
        sqdEnabled: true,
        demographicsEnabled: true,
        suggestionsEnabled: true,
        kioskMode: false,
      });
    }

    res.json(doc.data());
  } catch (err) {
    console.error('Get survey config error:', err);
    res.status(500).json({ error: 'Failed to get survey config' });
  }
});

/**
 * PUT /survey-config
 * Update survey configuration
 */
app.put('/survey-config', async (req, res) => {
  try {
    const config = req.body;

    await db.collection(COLLECTIONS.SURVEY_CONFIG).doc('current').set({
      ...config,
      updatedAt: new Date(),
    }, { merge: true });

    res.json({ success: true });
  } catch (err) {
    console.error('Update survey config error:', err);
    res.status(500).json({ error: 'Failed to update survey config' });
  }
});

// =============================================================================
// SURVEY QUESTIONS ENDPOINTS
// =============================================================================

/**
 * GET /survey-questions
 * Get all survey questions and section configurations
 */
app.get('/survey-questions', async (req, res) => {
  try {
    const doc = await db.collection(COLLECTIONS.SURVEY_QUESTIONS).doc('current').get();

    if (!doc.exists) {
      // Return empty object if no questions configured yet
      return res.json({
        ccQuestions: null,
        sqdQuestions: null,
        ccConfig: null,
        sqdConfig: null,
        profileConfig: null,
        suggestionsConfig: null,
      });
    }

    res.json(doc.data());
  } catch (err) {
    console.error('Get survey questions error:', err);
    res.status(500).json({ error: 'Failed to get survey questions' });
  }
});

/**
 * PUT /survey-questions
 * Update survey questions and section configurations
 */
app.put('/survey-questions', async (req, res) => {
  try {
    const questionsData = req.body;

    await db.collection(COLLECTIONS.SURVEY_QUESTIONS).doc('current').set({
      ...questionsData,
      updatedAt: new Date(),
    }, { merge: true });

    res.json({ success: true });
  } catch (err) {
    console.error('Update survey questions error:', err);
    res.status(500).json({ error: 'Failed to update survey questions' });
  }
});

/**
 * PUT /survey-questions/cc
 * Update CC (Citizen's Charter) questions only
 */
app.put('/survey-questions/cc', async (req, res) => {
  try {
    const { questions, config } = req.body;

    const updateData = { updatedAt: new Date() };
    if (questions !== undefined) updateData.ccQuestions = questions;
    if (config !== undefined) updateData.ccConfig = config;

    await db.collection(COLLECTIONS.SURVEY_QUESTIONS).doc('current').set(updateData, { merge: true });

    res.json({ success: true });
  } catch (err) {
    console.error('Update CC questions error:', err);
    res.status(500).json({ error: 'Failed to update CC questions' });
  }
});

/**
 * PUT /survey-questions/sqd
 * Update SQD (Service Quality Dimensions) questions only
 */
app.put('/survey-questions/sqd', async (req, res) => {
  try {
    const { questions, config } = req.body;

    const updateData = { updatedAt: new Date() };
    if (questions !== undefined) updateData.sqdQuestions = questions;
    if (config !== undefined) updateData.sqdConfig = config;

    await db.collection(COLLECTIONS.SURVEY_QUESTIONS).doc('current').set(updateData, { merge: true });

    res.json({ success: true });
  } catch (err) {
    console.error('Update SQD questions error:', err);
    res.status(500).json({ error: 'Failed to update SQD questions' });
  }
});

/**
 * PUT /survey-questions/profile
 * Update profile section configuration
 */
app.put('/survey-questions/profile', async (req, res) => {
  try {
    const { config } = req.body;

    await db.collection(COLLECTIONS.SURVEY_QUESTIONS).doc('current').set({
      profileConfig: config,
      updatedAt: new Date(),
    }, { merge: true });

    res.json({ success: true });
  } catch (err) {
    console.error('Update profile config error:', err);
    res.status(500).json({ error: 'Failed to update profile config' });
  }
});

/**
 * PUT /survey-questions/suggestions
 * Update suggestions section configuration
 */
app.put('/survey-questions/suggestions', async (req, res) => {
  try {
    const { config } = req.body;

    await db.collection(COLLECTIONS.SURVEY_QUESTIONS).doc('current').set({
      suggestionsConfig: config,
      updatedAt: new Date(),
    }, { merge: true });

    res.json({ success: true });
  } catch (err) {
    console.error('Update suggestions config error:', err);
    res.status(500).json({ error: 'Failed to update suggestions config' });
  }
});

// =============================================================================
// PUSH / Web Push Endpoints
// =============================================================================

// Return VAPID public key for frontend to use when subscribing
app.get('/push/vapidPublicKey', (req, res) => {
  if (!webpush || !VAPID_PUBLIC_KEY) {
    return res.status(503).json({ error: 'Push service not configured' });
  }
  res.json({ publicKey: VAPID_PUBLIC_KEY });
});

// Subscribe endpoint: save subscription object for a user
app.post('/push/subscribe', async (req, res) => {
  try {
    if (!webpush) return res.status(503).json({ error: 'Push service not available' });
    const { userId, email, subscription, fcmToken, platform } = req.body || {};

    // If client is registering an FCM/native token
    if (fcmToken) {
      const id = userId || (email ? email.toLowerCase() : null) || db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc().id;
      await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc(id).set({
        userId: userId || null,
        email: email || null,
        fcmToken,
        platform: platform || 'mobile',
        type: 'fcm',
        enabled: true,
        createdAt: new Date(),
      }, { merge: true });

      return res.json({ success: true, id });
    }

    // Otherwise expect a web Push subscription object
    if (!subscription) return res.status(400).json({ error: 'Subscription object required' });

    const id = userId || (email ? email.toLowerCase() : null) || db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc().id;

    await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc(id).set({
      userId: userId || null,
      email: email || null,
      subscription,
      type: 'web',
      enabled: true,
      createdAt: new Date(),
    }, { merge: true });

    res.json({ success: true, id });
  } catch (err) {
    console.error('Subscribe error:', err);
    res.status(500).json({ error: 'Failed to save subscription' });
  }
});

// Unsubscribe: disable/remove subscription for user
app.post('/push/unsubscribe', async (req, res) => {
  try {
    const { userId } = req.body || {};
    if (!userId) return res.status(400).json({ error: 'userId required' });

    const docRef = db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc(userId);
    const doc = await docRef.get();
    if (!doc.exists) return res.json({ success: true });

    await docRef.delete();
    res.json({ success: true });
  } catch (err) {
    console.error('Unsubscribe error:', err);
    res.status(500).json({ error: 'Failed to unsubscribe' });
  }
});

// Send push (used by admin UI or server-side alerts)
app.post('/push/send', async (req, res) => {
  try {
    if (!webpush) return res.status(503).json({ error: 'Push service not available' });

    const { title, body, targetUserId, payload } = req.body || {};
    const message = {
      title: title || 'V-Serve Alert',
      body: body || '',
      data: payload || {},
    };

    let targets = [];
    if (targetUserId) {
      const doc = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc(targetUserId).get();
      if (doc.exists && doc.data().subscription) targets.push(doc.data());
    } else {
      const snapshot = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).where('enabled', '==', true).get();
      snapshot.forEach(d => targets.push(d.data()));
    }

    const results = [];
    for (const t of targets) {
      try {
        const sub = t.subscription;
        const sent = await webpush.sendNotification(sub, JSON.stringify(message));
        results.push({ id: t.userId || t.email || null, ok: true });
      } catch (sendErr) {
        console.error('Push send error for target:', t, sendErr);
        results.push({ id: t.userId || t.email || null, ok: false, error: String(sendErr) });
      }
    }

    res.json({ success: true, results });
  } catch (err) {
    console.error('Push send endpoint error:', err);
    res.status(500).json({ error: 'Failed to send push' });
  }
});

// Send via FCM (native mobile / desktop that use Firebase Cloud Messaging)
app.post('/push/send-fcm', async (req, res) => {
  try {
    const { title, body, targetUserId, data } = req.body || {};
    if (!admin || !admin.messaging) return res.status(503).json({ error: 'FCM not configured' });

    let tokens = [];
    if (targetUserId) {
      const doc = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).doc(targetUserId).get();
      if (doc.exists && doc.data().fcmToken) tokens.push(doc.data().fcmToken);
    } else {
      const snapshot = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).where('type', '==', 'fcm').where('enabled', '==', true).get();
      snapshot.forEach(d => {
        const s = d.data();
        if (s.fcmToken) tokens.push(s.fcmToken);
      });
    }

    if (tokens.length === 0) return res.json({ success: true, results: [], message: 'No fcm tokens available' });

    // Build payload
    const message = {
      notification: {
        title: title || 'V-Serve Alert',
        body: body || '',
      },
      data: data || {},
    };

    // For multiple tokens use sendMulticast
    const chunkSize = 500; // FCM limit
    const results = [];
    for (let i = 0; i < tokens.length; i += chunkSize) {
      const batch = tokens.slice(i, i + chunkSize);
      const resp = await admin.messaging().sendMulticast({ tokens: batch, ...message });
      results.push({ successCount: resp.successCount, failureCount: resp.failureCount, responses: resp.responses });
    }

    res.json({ success: true, results });
  } catch (err) {
    console.error('FCM send error:', err);
    res.status(500).json({ error: 'Failed to send FCM messages' });
  }
});

// Register device token (unified for web/android/windows)
app.post('/api/register-token', async (req, res) => {
  try {
    const { deviceId, platform, token } = req.body || {};
    if (!deviceId || !platform || !token) return res.status(400).json({ error: 'deviceId, platform and token required' });

    // Upsert by token or deviceId
    const q = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).where('token', '==', token).limit(1).get();
    if (!q.empty) {
      const doc = q.docs[0];
      await doc.ref.update({ platform, lastSeen: new Date(), enabled: true });
      return res.json({ success: true, id: doc.id });
    }

    // Store a new subscription
    const docRef = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS).add({
      deviceId,
      platform,
      token,
      enabled: true,
      createdAt: new Date(),
      lastSeen: new Date(),
    });

    res.json({ success: true, id: docRef.id });
  } catch (err) {
    console.error('Register token error:', err);
    res.status(500).json({ error: 'Failed to register token' });
  }
});

// Unified send endpoint - queues for windows and sends via FCM for web/android
app.post('/api/send-notification', async (req, res) => {
  try {
    const { title, body, platforms } = req.body || {};
    const alert = {
      title: title || 'V-Serve Alert',
      body: body || '',
      createdAt: new Date(),
      platforms: platforms || ['web','android','windows'],
    };

    // Store alert for Windows clients to poll
    await db.collection(COLLECTIONS.ALERTS).add(alert);

    // Send FCM to web/android tokens
    const fcmSnapshot = await db.collection(COLLECTIONS.PUSH_SUBSCRIPTIONS)
      .where('platform', 'in', ['web','android'])
      .where('enabled', '==', true)
      .get();

    const tokens = [];
    fcmSnapshot.forEach(d => { const s = d.data(); if (s.token) tokens.push(s.token); });

    const results = [];
    if (tokens.length > 0 && admin && admin.messaging) {
      const chunkSize = 500;
      for (let i=0;i<tokens.length;i+=chunkSize) {
        const batch = tokens.slice(i,i+chunkSize);
        const message = {
          notification: { title: alert.title, body: alert.body },
          android: { priority: 'high' },
          webpush: { headers: { Urgency: 'high' } },
          tokens: batch,
        };
        const resp = await admin.messaging().sendMulticast(message);
        results.push({ successCount: resp.successCount, failureCount: resp.failureCount });
      }
    }

    res.json({ success: true, stored: true, fcmResults: results });
  } catch (err) {
    console.error('send-notification error:', err);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

// GET alerts for polling (Windows clients)
app.get('/api/alerts', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '20', 10), 100);
    const snapshot = await db.collection(COLLECTIONS.ALERTS).orderBy('createdAt', 'desc').limit(limit).get();
    const items = snapshot.docs.map(d => ({
      id: d.id,
      title: d.data().title,
      body: d.data().body,
      createdAt: d.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));
    res.json({ success: true, count: items.length, items });
  } catch (err) {
    console.error('Get alerts error:', err);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// =============================================================================
// SERVER STARTUP
// =============================================================================

// For Vercel, we export the app instead of listening
if (process.env.VERCEL) {
  module.exports = app;
} else {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`V-Serve Backend listening on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

// Export for Vercel serverless
module.exports = app;
