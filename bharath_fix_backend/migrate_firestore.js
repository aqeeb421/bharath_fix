/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║         BharathFix — Firestore Pre-Filled Data Migrator      ║
 * ║  Copies catalog / seed data from SOURCE → TARGET Firestore   ║
 * ╚══════════════════════════════════════════════════════════════╝
 *
 * WHAT IT COPIES (pre-filled / catalog data):
 *   ✅ categories
 *   ✅ subCategories  (also as subcategories if they exist at root)
 *   ✅ services
 *   ✅ products
 *   ✅ banners
 *   ✅ coupons
 *   ✅ mainCategories (if exists)
 *   ✅ appConfig      (app-level settings)
 *
 * WHAT IT SKIPS (user / transaction data):
 *   ❌ users          (personal data, new project starts fresh)
 *   ❌ providers      (technician accounts, re-register on new project)
 *   ❌ bookings       (transaction data)
 *   ❌ orders         (transaction data)
 *   ❌ admin_notifications
 *   ❌ broadcast_notifications
 *
 * HOW TO RUN:
 *   1. Place SOURCE project service account key → source_key.json  (this is your current serviceAccountKey.json)
 *   2. Place TARGET project service account key → target_key.json  (download from new Firebase project)
 *   3. node migrate_firestore.js
 *
 * OPTIONAL FLAGS:
 *   node migrate_firestore.js --backup-only    (export to JSON, skip writing to target)
 *   node migrate_firestore.js --dry-run        (show document counts only, no reads/writes)
 */

const admin = require('firebase-admin');
const fs    = require('fs');
const path  = require('path');

// ─────────────────────────────────────────────────────────────
// ⚙️  CONFIGURATION — SET THESE TWO PATHS
// ─────────────────────────────────────────────────────────────
const SOURCE_KEY_PATH = path.resolve(__dirname, 'source_key.json');  // ← Your CURRENT Firestore key
const TARGET_KEY_PATH = path.resolve(__dirname, 'target_key.json');  // ← Your NEW Firestore key
// ─────────────────────────────────────────────────────────────

// Collections to migrate (only pre-filled catalog/seed data)
const COLLECTIONS_TO_MIGRATE = [
  'categories',
  'subcategories',
  'subCategories',
  'services',
  'products',
  'banners',
  'coupons',
  'mainCategories',
  'appConfig',
  'admins',              // ← Admin accounts (for RBAC login)
  'spare_parts_catalog', // ← Spare parts data for technician quotation builder
];

// Known subcollections per parent collection
const SUBCOLLECTIONS_MAP = {
  'categories':    ['subCategories', 'subcategories', 'services'],
  'subcategories': ['services'],
  'subCategories': ['services'],
};

const BATCH_SIZE = 400; // Firestore hard limit is 500; keep buffer

// CLI flags
const BACKUP_ONLY  = process.argv.includes('--backup-only');
const DRY_RUN      = process.argv.includes('--dry-run');
const FROM_BACKUP  = process.argv.find(a => a.startsWith('--from-backup'));  // --from-backup=filename.json

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
function log(emoji, msg) {
  console.log(`${emoji}  ${msg}`);
}

function validateKeyFile(filePath, label) {
  if (!fs.existsSync(filePath)) {
    console.error(`\n❌  ${label} key file NOT found: ${filePath}`);
    console.error(`\n    Steps to get the key:`);
    console.error(`    1. Go to Firebase Console → Your Project → Project Settings`);
    console.error(`    2. Click "Service Accounts" tab`);
    console.error(`    3. Click "Generate New Private Key"`);
    console.error(`    4. Save the file as: ${path.basename(filePath)}\n`);
    process.exit(1);
  }
  const key = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  log('✅', `${label} project: \x1b[36m${key.project_id}\x1b[0m`);
  return key;
}

async function writeBatch(db, collectionPath, docs) {
  let batch      = db.batch();
  let opsInBatch = 0;
  let total      = 0;

  for (const { id, data } of docs) {
    const ref = db.collection(collectionPath).doc(id);
    batch.set(ref, data, { merge: true });
    opsInBatch++;
    total++;

    if (opsInBatch >= BATCH_SIZE) {
      await batch.commit();
      batch      = db.batch();
      opsInBatch = 0;
    }
  }

  if (opsInBatch > 0) await batch.commit();
  return total;
}

async function readCollectionDeep(db, collectionPath, depth = 0) {
  const snap     = await db.collection(collectionPath).get();
  if (snap.empty) return [];

  const collName = collectionPath.split('/').pop();
  const subNames = SUBCOLLECTIONS_MAP[collName] || [];
  const docs     = [];

  for (const doc of snap.docs) {
    const entry = { id: doc.id, data: doc.data(), subcollections: {} };

    if (depth < 2 && subNames.length > 0) {
      for (const subName of subNames) {
        const subPath = `${collectionPath}/${doc.id}/${subName}`;
        try {
          const subSnap = await db.collection(subPath).get();
          if (!subSnap.empty) {
            entry.subcollections[subName] = subSnap.docs.map(sd => ({
              id: sd.id, data: sd.data(),
            }));
          }
        } catch (_) { /* subcollection may not exist */ }
      }
    }

    docs.push(entry);
  }
  return docs;
}

async function writeCollectionDeep(targetDb, collectionPath, docs) {
  if (docs.length === 0) return 0;

  const flatDocs = docs.map(d => ({ id: d.id, data: d.data }));
  let written    = await writeBatch(targetDb, collectionPath, flatDocs);

  // NOTE: writeBatch may return 0 if all operations are no-ops — still counts as success

  for (const doc of docs) {
    for (const [subName, subDocs] of Object.entries(doc.subcollections || {})) {
      const subPath = `${collectionPath}/${doc.id}/${subName}`;
      const flat    = subDocs.map(sd => ({ id: sd.id, data: sd.data }));
      written += await writeBatch(targetDb, subPath, flat);
    }
  }

  return written;
}

// ─────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────
async function main() {
  console.log('\n\x1b[34m╔══════════════════════════════════════════════════╗');
  console.log('║    BharathFix  Firestore Data Migrator  v1.0     ║');
  console.log('╚══════════════════════════════════════════════════╝\x1b[0m\n');

  if (BACKUP_ONLY) log('📦', '\x1b[33mMode: BACKUP ONLY (no writes)\x1b[0m');
  if (DRY_RUN)     log('🔍', '\x1b[33mMode: DRY RUN (shows counts, no reads/writes)\x1b[0m');
  if (FROM_BACKUP) log('♻️ ', `\x1b[33mMode: FROM BACKUP — skipping source read\x1b[0m`);

  // 1. Validate key files
  const needSourceKey = !FROM_BACKUP && !DRY_RUN;  // skip source if re-using backup
  const sourceKey = needSourceKey ? validateKeyFile(SOURCE_KEY_PATH, 'SOURCE') : null;
  const targetKey = (!BACKUP_ONLY && !DRY_RUN) ? validateKeyFile(TARGET_KEY_PATH, 'TARGET') : null;

  // 2. Initialize Firebase Admin apps
  let sourceApp = null;
  if (sourceKey) {
    sourceApp = admin.initializeApp(
      { credential: admin.credential.cert(sourceKey) }, 'source'
    );
  }

  let targetApp = null;
  if (targetKey) {
    targetApp = admin.initializeApp(
      { credential: admin.credential.cert(targetKey) }, 'target'
    );
  }

  const sourceDb = sourceApp ? admin.app('source').firestore() : null;
  const targetDb = targetApp ? admin.app('target').firestore() : null;

  if (DRY_RUN) {
    log('📊', 'Collections that will be migrated:');
    COLLECTIONS_TO_MIGRATE.forEach(c => console.log(`      • ${c}`));
    console.log('\n✅  Dry run complete. Run without --dry-run to migrate.\n');
    process.exit(0);
  }

  // 3. Read from SOURCE
  const allData = {};
  const summary = [];

  // ── If --from-backup flag is provided, load existing JSON instead of reading source
  if (FROM_BACKUP) {
    const backupArg  = FROM_BACKUP.split('=')[1];
    const backupFile = backupArg || (() => {
      // Auto-find latest backup in current directory
      const files = fs.readdirSync(__dirname)
        .filter(f => f.startsWith('firestore_backup_') && f.endsWith('.json'))
        .sort().reverse();
      return files[0];
    })();

    if (!backupFile) {
      console.error('\n❌  No backup file found. Run without --from-backup first to create one.\n');
      process.exit(1);
    }

    const backupPath = path.resolve(__dirname, backupFile);
    if (!fs.existsSync(backupPath)) {
      console.error(`\n❌  Backup file not found: ${backupPath}\n`);
      process.exit(1);
    }

    log('📂', `Loading backup: \x1b[36m${backupFile}\x1b[0m`);
    const raw = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

    // Convert raw JSON back to { id, data, subcollections } format
    for (const [collName, docs] of Object.entries(raw)) {
      allData[collName] = docs;  // already in correct format from backup
      const totalSub = docs.reduce(
        (acc, d) => acc + Object.values(d.subcollections || {}).reduce((a, sd) => a + sd.length, 0), 0
      );
      summary.push({ collection: collName, docs: docs.length, subDocs: totalSub });
      console.log(`   ✅  Loaded '${collName}': ${docs.length} docs${totalSub > 0 ? ` + ${totalSub} sub-docs` : ''}`);
    }

    // Skip to write phase
  } else {
    console.log('\n\x1b[34m──────────────────────────────────────────────────\x1b[0m');
    log('📡', 'Reading pre-filled data from SOURCE Firestore...');
    console.log('\x1b[34m──────────────────────────────────────────────────\x1b[0m\n');

    for (const collName of COLLECTIONS_TO_MIGRATE) {
      process.stdout.write(`  📂 Reading '${collName}'... `);
      try {
        const docs = await readCollectionDeep(sourceDb, collName);
        if (docs.length === 0) {
          console.log(`\x1b[90m(empty, skipped)\x1b[0m`);
          continue;
        }

        const totalSub = docs.reduce(
          (acc, d) => acc + Object.values(d.subcollections).reduce((a, sd) => a + sd.length, 0),
          0
        );

        console.log(`\x1b[32m${docs.length} docs\x1b[0m${totalSub > 0 ? ` \x1b[90m+ ${totalSub} sub-docs\x1b[0m` : ''}`);
        allData[collName] = docs;
        summary.push({ collection: collName, docs: docs.length, subDocs: totalSub });
      } catch (err) {
        console.log(`\x1b[31mERROR: ${err.message}\x1b[0m`);
      }
    }
  } // end else (not FROM_BACKUP)

  // 4. Print summary
  console.log('\n\x1b[34m──────────────────────────────────────────────────\x1b[0m');
  log('📊', 'READ SUMMARY:');
  let totalDocCount = 0;
  for (const s of summary) {
    console.log(`   ✅  ${s.collection.padEnd(22)} \x1b[32m${s.docs} docs\x1b[0m ${s.subDocs > 0 ? `\x1b[90m+ ${s.subDocs} sub-docs\x1b[0m` : ''}`);
    totalDocCount += s.docs + s.subDocs;
  }
  console.log(`\n   📦  Total to migrate: \x1b[33m${totalDocCount} documents\x1b[0m`);

  // 5. Always save a JSON backup first
  const backupFile = `firestore_backup_${Date.now()}.json`;
  const backupPath = path.resolve(__dirname, backupFile);
  fs.writeFileSync(backupPath, JSON.stringify(allData, null, 2), 'utf8');
  log('💾', `Backup saved → \x1b[36m${backupFile}\x1b[0m`);

  if (BACKUP_ONLY) {
    console.log('\n✅  Backup complete. No writes performed.\n');
    process.exit(0);
  }

  // 6. Write to TARGET
  console.log('\n\x1b[34m──────────────────────────────────────────────────\x1b[0m');
  log('🚀', `Writing to TARGET Firestore (\x1b[36m${targetKey.project_id}\x1b[0m)...`);
  console.log('\x1b[34m──────────────────────────────────────────────────\x1b[0m\n');

  let totalWritten = 0;

  for (const [collName, docs] of Object.entries(allData)) {
    process.stdout.write(`  ✍️  Writing '${collName}'... `);
    try {
      const written = await writeCollectionDeep(targetDb, collName, docs);
      console.log(`\x1b[32m${written} docs written ✅\x1b[0m`);
      totalWritten += written;
    } catch (err) {
      const msg = err.message || '';
      console.log(`\x1b[31mFAILED ❌\x1b[0m`);

      // Helpful diagnosis for the most common errors
      if (msg.includes('NOT_FOUND') || msg.includes('5 NOT_FOUND')) {
        console.log(`
  \x1b[33m⚠️  Firestore database not initialized in target project!\x1b[0m
  \x1b[90m  Fix: Open Firebase Console → Select project '${targetKey.project_id}'
        → Click "Firestore Database" in the left menu
        → Click "Create database"
        → Choose "Start in production mode"
        → Select region (e.g. asia-south1 for India)
        → Click "Enable"
        → Then re-run: node migrate_firestore.js --from-backup\x1b[0m
`);
        process.exit(1);  // Stop immediately — all collections will fail the same way
      } else if (msg.includes('PERMISSION_DENIED')) {
        console.log(`
  \x1b[33m⚠️  Permission denied on target Firestore!\x1b[0m
  \x1b[90m  Fix: Ensure the service account in target_key.json has
        "Firebase Admin" or "Cloud Datastore Owner" role in IAM.\x1b[0m
`);
      } else {
        console.log(`       \x1b[31mError: ${msg}\x1b[0m`);
      }
    }
  }

  // 7. Final report
  console.log('\n\x1b[32m╔══════════════════════════════════════════════════╗');
  console.log(`║  ✅  MIGRATION COMPLETE!                          ║`);
  console.log(`║  📄  Documents written : ${String(totalWritten).padEnd(24)} ║`);
  console.log(`║  💾  Backup file       : ${backupFile.slice(0, 24).padEnd(24)} ║`);
  console.log('╚══════════════════════════════════════════════════╝\x1b[0m\n');

  process.exit(0);
}

main().catch(err => {
  console.error('\n\x1b[31m❌  Fatal error:\x1b[0m', err.message);
  process.exit(1);
});
