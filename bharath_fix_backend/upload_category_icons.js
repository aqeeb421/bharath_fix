const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const sa = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(sa),
  storageBucket: 'bharathfix-735c5.firebasestorage.app',
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

const iconsMapping = [
  {
    docId: 'm1',
    categoryName: 'Refrigerator',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/refrigerator.png',
    storagePath: 'app_images/category_icons/refrigerator.png',
  },
  {
    docId: 'm2',
    categoryName: 'Washing Machine',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/washing_machine.png',
    storagePath: 'app_images/category_icons/washing_machine.png',
  },
  {
    docId: 'm3',
    categoryName: 'Water Purifier',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/water_purifer.png',
    storagePath: 'app_images/category_icons/water_purifier.png',
  },
  {
    docId: 'm4',
    categoryName: 'AC Repair',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/air_condition.png',
    storagePath: 'app_images/category_icons/air_condition.png',
  },
  {
    docId: 'm5',
    categoryName: 'Kitchen Chimney',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/chimney.png',
    storagePath: 'app_images/category_icons/kitchen_chimney.png',
  },
  {
    docId: 'm6',
    categoryName: 'Air Cooler',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/air_cooler.png',
    storagePath: 'app_images/category_icons/air_cooler.png',
  },
  {
    docId: 'm7',
    categoryName: 'Geyser',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/water_heater.png',
    storagePath: 'app_images/category_icons/geyser.png',
  },
  {
    docId: 'm8',
    categoryName: 'Microwave Oven',
    localFile: 'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/icons/microwave.png',
    storagePath: 'app_images/category_icons/microwave_oven.png',
  },
];

async function run() {
  console.log('=== Uploading Category Icons to Firebase Storage & Syncing Firestore ===');

  for (const item of iconsMapping) {
    if (!fs.existsSync(item.localFile)) {
      console.error(`Local file not found: ${item.localFile}`);
      continue;
    }

    const token = crypto.randomUUID();
    const destination = item.storagePath;

    console.log(`\nUploading ${item.categoryName} (${item.docId}) -> ${destination}...`);
    await bucket.upload(item.localFile, {
      destination: destination,
      metadata: {
        contentType: 'image/png',
        metadata: {
          firebaseStorageDownloadTokens: token,
          categoryName: item.categoryName,
          docId: item.docId,
          type: 'category_icon',
        },
      },
    });

    const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(destination)}?alt=media&token=${token}`;
    console.log(`Uploaded! URL: ${downloadUrl}`);

    // Update Firestore document
    const docRef = db.collection('categories').doc(item.docId);
    await docRef.set(
      {
        image: downloadUrl,
        imageUrl: downloadUrl,
        iconUrl: downloadUrl,
      },
      { merge: true }
    );
    console.log(`Updated Firestore categories/${item.docId} with new icon URL.`);
  }

  console.log('\n=== All 8 Category Icons Successfully Uploaded and Firestore Synced! ===');
  process.exit(0);
}

run().catch((err) => {
  console.error('Fatal Error:', err);
  process.exit(1);
});
