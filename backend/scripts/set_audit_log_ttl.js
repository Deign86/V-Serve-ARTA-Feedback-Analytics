#!/usr/bin/env node
/**
 * Migration script: Add expiresAt field to existing audit_logs documents
 * This enables Firestore TTL to auto-delete old logs.
 * 
 * Usage:
 *   cd backend
 *   node scripts/set_audit_log_ttl.js
 * 
 * Environment:
 *   AUDIT_LOG_RETENTION_DAYS - Number of days to retain logs (default: 7)
 */

require('dotenv').config();
const db = require('../src/firestore');

const AUDIT_LOG_RETENTION_DAYS = parseInt(process.env.AUDIT_LOG_RETENTION_DAYS || '7', 10);
const BATCH_SIZE = 500;

async function migrateAuditLogs() {
  console.log(`Starting audit log TTL migration...`);
  console.log(`Retention days: ${AUDIT_LOG_RETENTION_DAYS}`);
  
  let totalUpdated = 0;
  let lastDoc = null;
  
  while (true) {
    // Query documents that don't have expiresAt field
    // We paginate through all documents since Firestore doesn't support "field not exists" queries well
    let query = db.collection('audit_logs')
      .orderBy('timestamp', 'desc')
      .limit(BATCH_SIZE);
    
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    
    const snapshot = await query.get();
    
    if (snapshot.empty) {
      console.log('No more documents to process.');
      break;
    }
    
    const batch = db.batch();
    let batchCount = 0;
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Skip if already has expiresAt
      if (data.expiresAt) {
        continue;
      }
      
      // Calculate expiresAt from timestamp
      let timestamp = data.timestamp;
      if (timestamp && timestamp.toDate) {
        timestamp = timestamp.toDate();
      } else if (timestamp && typeof timestamp === 'string') {
        timestamp = new Date(timestamp);
      } else if (!timestamp) {
        // If no timestamp, use document creation time or now
        timestamp = new Date();
      }
      
      const expiresAt = new Date(timestamp.getTime() + AUDIT_LOG_RETENTION_DAYS * 24 * 60 * 60 * 1000);
      
      batch.update(doc.ref, { expiresAt });
      batchCount++;
    }
    
    if (batchCount > 0) {
      await batch.commit();
      totalUpdated += batchCount;
      console.log(`Updated ${batchCount} documents (total: ${totalUpdated})`);
    }
    
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    
    // If we got fewer docs than the batch size, we're done
    if (snapshot.size < BATCH_SIZE) {
      break;
    }
  }
  
  console.log(`\nMigration complete! Total documents updated: ${totalUpdated}`);
  console.log(`\nNext steps:`);
  console.log(`1. Go to Firebase Console > Firestore > Data`);
  console.log(`2. Click on "audit_logs" collection`);
  console.log(`3. Click the "..." menu > "TTL policies"`);
  console.log(`4. Add a new TTL policy with field: "expiresAt"`);
  console.log(`5. Firestore will automatically delete documents when expiresAt passes`);
}

migrateAuditLogs()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Migration failed:', err);
    process.exit(1);
  });
