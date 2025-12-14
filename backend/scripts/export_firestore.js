/**
 * Export Firestore database to JSON format
 * 
 * Usage: node scripts/export_firestore.js [collection_name]
 * 
 * If no collection name is provided, exports all collections.
 * Output is saved to backend/exports/ directory.
 */

const fs = require('fs');
const path = require('path');
const db = require('../src/firestore');

const EXPORTS_DIR = path.join(__dirname, '..', 'exports');

// Ensure exports directory exists
if (!fs.existsSync(EXPORTS_DIR)) {
  fs.mkdirSync(EXPORTS_DIR, { recursive: true });
}

/**
 * Export a single collection to JSON
 */
async function exportCollection(collectionName) {
  console.log(`Exporting collection: ${collectionName}...`);
  
  const snapshot = await db.collection(collectionName).get();
  const documents = [];
  
  snapshot.forEach(doc => {
    documents.push({
      id: doc.id,
      ...doc.data()
    });
  });
  
  console.log(`  Found ${documents.length} documents`);
  return documents;
}

/**
 * Get all collection names in the database
 */
async function getAllCollections() {
  const collections = await db.listCollections();
  return collections.map(col => col.id);
}

/**
 * Export entire database or specific collection
 */
async function exportDatabase(specificCollection = null) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  
  try {
    if (specificCollection) {
      // Export single collection
      const data = await exportCollection(specificCollection);
      const filename = `${specificCollection}_${timestamp}.json`;
      const filepath = path.join(EXPORTS_DIR, filename);
      
      fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
      console.log(`\n✓ Exported to: ${filepath}`);
      console.log(`  Total documents: ${data.length}`);
      
    } else {
      // Export all collections
      const collectionNames = await getAllCollections();
      console.log(`Found ${collectionNames.length} collections: ${collectionNames.join(', ')}\n`);
      
      const fullExport = {};
      let totalDocs = 0;
      
      for (const name of collectionNames) {
        const data = await exportCollection(name);
        fullExport[name] = data;
        totalDocs += data.length;
      }
      
      const filename = `firestore_full_export_${timestamp}.json`;
      const filepath = path.join(EXPORTS_DIR, filename);
      
      fs.writeFileSync(filepath, JSON.stringify(fullExport, null, 2));
      console.log(`\n✓ Exported to: ${filepath}`);
      console.log(`  Total collections: ${collectionNames.length}`);
      console.log(`  Total documents: ${totalDocs}`);
    }
    
    console.log('\nExport completed successfully!');
    
  } catch (error) {
    console.error('Export failed:', error.message);
    process.exit(1);
  }
}

// Main execution
const collectionArg = process.argv[2];
exportDatabase(collectionArg).then(() => {
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});
