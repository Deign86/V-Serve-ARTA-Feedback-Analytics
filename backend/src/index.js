// V-Serve ARTA Backend API
// Provides HTTP endpoints for Flutter app (especially Windows native)
// Connects to Firebase/Firestore via Admin SDK

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');

// Load dotenv so PORT and other env vars can be set from .env
try {
  require('dotenv').config();
} catch (e) { }

const db = require('./firestore');

const app = express();

// CORS configuration - allow requests from any origin in dev, restrict in production
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://v-serve.vercel.app', 'http://localhost:3000', 'http://localhost:5000']
    : true,
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));

// Collection names (matching existing Firestore structure)
const COLLECTIONS = {
  FEEDBACKS: 'feedbacks',
  SYSTEM_USERS: 'system_users',
  AUDIT_LOGS: 'audit_logs',
  SURVEY_CONFIG: 'survey_config',
  ALERTS: 'alerts',
};

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
 */
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user by email in system_users collection
    const usersSnapshot = await db.collection(COLLECTIONS.SYSTEM_USERS)
      .where('email', '==', email.toLowerCase().trim())
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();

    // Check if user is active
    if (userData.status !== 'Active') {
      return res.status(401).json({ error: 'Account is not active' });
    }

    // Verify password using bcrypt
    const passwordHash = userData.passwordHash;
    if (!passwordHash) {
      return res.status(401).json({ error: 'Account not properly configured' });
    }

    const isValidPassword = await bcrypt.compare(password, passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Update last login timestamp
    await userDoc.ref.update({
      lastLogin: new Date(),
    });

    // Return user data (without password hash)
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
 */
app.get('/users', async (req, res) => {
  try {
    const snapshot = await db.collection(COLLECTIONS.SYSTEM_USERS).get();
    const users = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Don't expose password hash
      passwordHash: undefined,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
      lastLogin: doc.data().lastLogin?.toDate?.()?.toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
    }));

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
 */
app.post('/users', async (req, res) => {
  try {
    const { name, email, password, role, department } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    // Check if email already exists
    const existingUser = await db.collection(COLLECTIONS.SYSTEM_USERS)
      .where('email', '==', email.toLowerCase().trim())
      .limit(1)
      .get();

    if (!existingUser.empty) {
      return res.status(409).json({ error: 'Email already exists' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    const docRef = await db.collection(COLLECTIONS.SYSTEM_USERS).add({
      name,
      email: email.toLowerCase().trim(),
      passwordHash,
      role: role || 'Viewer',
      department: department || '',
      status: 'Active',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    res.status(201).json({
      success: true,
      id: docRef.id,
      user: { id: docRef.id, name, email, role: role || 'Viewer', department },
    });
  } catch (err) {
    console.error('Create user error:', err);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

/**
 * PUT /users/:id
 * Update a system user
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

    const updateData = {
      updatedAt: new Date(),
    };

    if (name) updateData.name = name;
    if (email) updateData.email = email.toLowerCase().trim();
    if (role) updateData.role = role;
    if (department !== undefined) updateData.department = department;
    if (status) updateData.status = status;
    
    // Hash new password if provided
    if (password) {
      updateData.passwordHash = await bcrypt.hash(password, 12);
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
  // PATCH handler - forward to PUT logic
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const docRef = db.collection(COLLECTIONS.SYSTEM_USERS).doc(id);
    const doc = await docRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Handle password update if provided
    if (updates.password) {
      updates.passwordHash = await bcrypt.hash(updates.password, 10);
      delete updates.password;
    }
    
    updates.updatedAt = new Date();
    await docRef.update(updates);
    
    const updatedDoc = await docRef.get();
    const userData = updatedDoc.data();
    
    res.json({
      success: true,
      user: {
        id: updatedDoc.id,
        ...userData,
        passwordHash: undefined,
        createdAt: userData.createdAt?.toDate?.()?.toISOString(),
        lastLogin: userData.lastLogin?.toDate?.()?.toISOString(),
        updatedAt: userData.updatedAt?.toDate?.()?.toISOString(),
      }
    });
  } catch (err) {
    console.error('Patch user error:', err);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

app.delete('/auth/users/:id', (req, res, next) => {
  req.url = `/users/${req.params.id}`;
  app._router.handle(req, res, next);
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
