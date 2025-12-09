/**
 * Seed Admin Users Script
 * 
 * This script creates admin accounts in Firestore with hashed passwords.
 * Users are configured via environment variables or a .env file.
 * 
 * Usage:
 *   cd backend
 *   npm install
 *   
 *   # Option 1: Set environment variables directly
 *   set ADMIN_EMAIL=admin@example.com
 *   set ADMIN_PASSWORD=securePassword123
 *   node scripts/seed_admin_users.js
 *   
 *   # Option 2: Create a .env file in the backend folder (see .env.example)
 *   node scripts/seed_admin_users.js
 * 
 * Environment Variables (all optional - will skip if not set):
 *   ADMIN_NAME, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_DEPARTMENT
 *   EDITOR_NAME, EDITOR_EMAIL, EDITOR_PASSWORD, EDITOR_DEPARTMENT
 *   ANALYST_NAME, ANALYST_EMAIL, ANALYST_PASSWORD, ANALYST_DEPARTMENT
 *   VIEWER_NAME, VIEWER_EMAIL, VIEWER_PASSWORD, VIEWER_DEPARTMENT
 * 
 * Note: Requires a valid serviceAccountKey.json in the backend folder or
 * set SERVICE_ACCOUNT_PATH environment variable to the path of your service account key.
 */

const crypto = require('crypto');
const path = require('path');

// Load environment variables from .env file if it exists
try {
  require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
} catch (e) {
  // dotenv not installed or .env not found - use system environment variables
}

const db = require('../src/firestore');

// Hash password using SHA-256 (matches the Flutter app's hashing)
function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

// Build admin users array from environment variables
function buildAdminUsers() {
  const users = [];
  
  // Admin user
  if (process.env.ADMIN_EMAIL && process.env.ADMIN_PASSWORD) {
    users.push({
      name: process.env.ADMIN_NAME || 'Admin User',
      email: process.env.ADMIN_EMAIL,
      password: process.env.ADMIN_PASSWORD,
      role: 'Administrator',
      department: process.env.ADMIN_DEPARTMENT || 'IT Administration',
      status: 'Active',
    });
  }
  
  // Editor user
  if (process.env.EDITOR_EMAIL && process.env.EDITOR_PASSWORD) {
    users.push({
      name: process.env.EDITOR_NAME || 'Editor User',
      email: process.env.EDITOR_EMAIL,
      password: process.env.EDITOR_PASSWORD,
      role: 'Editor',
      department: process.env.EDITOR_DEPARTMENT || 'Business Licensing',
      status: 'Active',
    });
  }
  
  // Analyst user
  if (process.env.ANALYST_EMAIL && process.env.ANALYST_PASSWORD) {
    users.push({
      name: process.env.ANALYST_NAME || 'Analyst User',
      email: process.env.ANALYST_EMAIL,
      password: process.env.ANALYST_PASSWORD,
      role: 'Analyst',
      department: process.env.ANALYST_DEPARTMENT || 'Data Analytics',
      status: 'Active',
    });
  }
  
  // Viewer user
  if (process.env.VIEWER_EMAIL && process.env.VIEWER_PASSWORD) {
    users.push({
      name: process.env.VIEWER_NAME || 'Viewer User',
      email: process.env.VIEWER_EMAIL,
      password: process.env.VIEWER_PASSWORD,
      role: 'Viewer',
      department: process.env.VIEWER_DEPARTMENT || 'Building Permits',
      status: 'Active',
    });
  }
  
  return users;
}

const adminUsers = buildAdminUsers();

async function seedAdminUsers() {
  console.log('=== Starting Admin User Seeding ===\n');

  if (adminUsers.length === 0) {
    console.log('⚠️  No users configured!');
    console.log('\nPlease set environment variables or create a .env file.');
    console.log('Required variables for each user type:');
    console.log('  ADMIN_EMAIL, ADMIN_PASSWORD');
    console.log('  EDITOR_EMAIL, EDITOR_PASSWORD');
    console.log('  ANALYST_EMAIL, ANALYST_PASSWORD');
    console.log('  VIEWER_EMAIL, VIEWER_PASSWORD');
    console.log('\nOptional variables:');
    console.log('  ADMIN_NAME, ADMIN_DEPARTMENT (same pattern for other roles)');
    console.log('\nSee .env.example for a template.');
    process.exit(1);
  }

  try {
    const collection = db.collection('system_users');

    const createdUsers = [];
    for (const user of adminUsers) {
      // Check if user already exists
      const existingQuery = await collection
        .where('email', '==', user.email.toLowerCase())
        .limit(1)
        .get();

      if (!existingQuery.empty) {
        console.log(`⚠️  User already exists: ${user.email} (skipping)`);
        continue;
      }

      // Create user with hashed password
      const userData = {
        name: user.name,
        email: user.email.toLowerCase(),
        passwordHash: hashPassword(user.password),
        role: user.role,
        department: user.department,
        status: user.status,
        createdAt: new Date(),
        lastLoginAt: null,
      };

      const docRef = await collection.add(userData);
      console.log(`✅ Created user: ${user.email} (${user.role}) - ID: ${docRef.id}`);
      createdUsers.push(user);
    }

    console.log('\n=== Admin User Seeding Complete ===');
    if (createdUsers.length > 0) {
      console.log('\nCreated users:');
      console.log('----------------------------------------');
      createdUsers.forEach(u => {
        console.log(`${u.role}: ${u.email}`);
      });
      console.log('----------------------------------------');
      console.log('\n⚠️  SECURITY NOTE: Store passwords securely and delete .env after seeding!');
    } else {
      console.log('\nNo new users were created (all already exist).');
    }

  } catch (error) {
    console.error('Error seeding admin users:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run the seeding
seedAdminUsers();
