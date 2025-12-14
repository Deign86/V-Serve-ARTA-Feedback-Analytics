# Backend (Firebase/Firestore) Integration

This folder contains the Node/Express backend that connects to Firebase using the Admin SDK.

## Architecture

The backend provides HTTP endpoints for the Flutter app (Windows, Web, Mobile). All platforms use HTTP for cross-compatibility.

### Authentication Flow

1. **Flutter app** sends email/password to backend via HTTP (`POST /auth/login`)
2. **Backend** verifies credentials via Firebase Auth REST API
3. **Backend** returns user profile data from Firestore
4. **Flutter app** stores session locally

This keeps the Flutter app Firebase-free while using Firebase Auth for secure password management.

## Endpoints

- `GET /ping` - Health check
- `POST /auth/login` - Authenticate user (Firebase Auth + legacy bcrypt fallback)
- `GET /auth/user` - Get user by email
- `POST /users` - Create user (creates in Firebase Auth + Firestore)
- `GET /users` - List all users
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete/disable user
- `POST /feedback` - Submit survey feedback
- `GET /feedback` - List feedbacks
- `GET /audit-logs` - List audit logs
- `GET /survey-config` - Get survey configuration
- `PUT /survey-config` - Update survey configuration

## Quick Start (Windows PowerShell)

### 1. Install dependencies

```powershell
cd backend
npm install
```

### 2. Configure Firebase

**Option A: Service Account (Recommended)**

1. Go to Firebase Console → Project Settings → Service accounts
2. Click "Generate new private key"
3. Save as `backend/serviceAccountKey.json`

**Option B: Environment Variables**

Set these in `.env` or system environment:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### 3. Set up the Firebase API Key

Add to `.env`:
```
FIREBASE_API_KEY=your-web-api-key
```

Get this from Firebase Console → Project Settings → General → Web API Key

### 4. Create admin users

```powershell
# Edit .env with your admin credentials (see .env.example)
# Then run:
node scripts/create_firebase_auth_admins.js
```

This creates users in **Firebase Authentication** (persistent across deployments).

### 5. Run the server

```powershell
# Development (auto-restart)
npm run dev

# Production
npm start
```

## Admin User Management

### Creating Initial Admin Users

```powershell
# 1. Copy and edit .env
cp .env.example .env
# Edit ADMIN_EMAIL, ADMIN_PASSWORD, etc.

# 2. Run the setup script
node scripts/create_firebase_auth_admins.js

# 3. Delete .env for security (optional)
```

### Why Firebase Auth?

| Old Approach (bcrypt in Firestore) | New Approach (Firebase Auth) |
|-----------------------------------|------------------------------|
| Need to seed users each deployment | Users persist automatically |
| Manual password hashing | Firebase handles security |
| Passwords stored in Firestore | Passwords stored securely by Firebase |

### Legacy Support

The backend supports both:
- **Firebase Auth users** (new) - verified via Firebase Auth REST API
- **Bcrypt users** (legacy) - verified via bcrypt hash comparison

Existing bcrypt users will continue to work until migrated.

## Security Notes

- **Never commit** `serviceAccountKey.json` or `.env` to version control
- Delete `.env` after creating admin users
- In production, use environment-based secrets (Vercel, etc.)

## Deployment (Vercel)

The backend is configured for Vercel serverless deployment:

```powershell
# Deploy
vercel --prod

# Set secrets
vercel secrets add firebase-service-account-json "$(cat serviceAccountKey.json)"
vercel env add FIREBASE_API_KEY
```
