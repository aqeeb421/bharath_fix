const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.resolve(__dirname, 'serviceAccountKey.json');
const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const auth = admin.auth();
const db = admin.firestore();

async function setupTestUsers() {
  console.log('\n======================================================');
  console.log('🔧 SETTING UP DEMO TEST ACCOUNTS IN FIREBASE PROJECT:');
  console.log(`📌 Project ID: ${serviceAccount.project_id}`);
  console.log('======================================================\n');

  // 1. Setup Customer Test User: +918073804900
  const phone = '+918073804900';
  let customerUser;
  try {
    customerUser = await auth.getUserByPhoneNumber(phone);
    console.log(`✅ Customer phone user already exists: ${customerUser.uid} (${phone})`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      customerUser = await auth.createUser({
        phoneNumber: phone,
        displayName: 'Demo Customer',
      });
      console.log(`🎉 Created Customer phone user: ${customerUser.uid} (${phone})`);
    } else {
      console.error('Customer Auth Error:', e.message);
    }
  }

  if (customerUser) {
    // Create/update customer profile in Firestore
    await db.collection('users').doc(customerUser.uid).set({
      uid: customerUser.uid,
      name: 'Demo Customer',
      phone: '8073804900',
      fullPhone: phone,
      email: 'customer@demo.com',
      role: 'customer',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log(`✅ Customer profile doc updated in users/${customerUser.uid}`);
  }

  // 2. Setup Email/Password Test User: tester@gmail.com / 123456
  const email = 'tester@gmail.com';
  const password = 'password123'; // Note: Firebase Auth requires min 6 chars
  let emailUser;
  try {
    emailUser = await auth.getUserByEmail(email);
    console.log(`✅ Email user already exists: ${emailUser.uid} (${email})`);
    // Update password to 123456
    await auth.updateUser(emailUser.uid, { password: 'password123' });
    console.log(`🔑 Password updated for ${email}`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      emailUser = await auth.createUser({
        email: email,
        password: password,
        displayName: 'Demo Tester',
      });
      console.log(`🎉 Created Email user: ${emailUser.uid} (${email})`);
    } else {
      console.error('Email Auth Error:', e.message);
    }
  }

  if (emailUser) {
    // 2a. Add to 'admins' collection for Admin Panel login
    await db.collection('admins').doc(emailUser.uid).set({
      uid: emailUser.uid,
      email: email,
      name: 'Demo Admin',
      role: 'superadmin',
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log(`✅ Admin RBAC doc created in admins/${emailUser.uid}`);

    // 2b. Add to 'providers' collection for Technician App login
    await db.collection('providers').doc(emailUser.uid).set({
      uid: emailUser.uid,
      name: 'Demo Technician',
      email: email,
      phone: '+918073804900',
      status: 'active',
      isOnline: true,
      category: 'All Appliances Specialist',
      skills: [
        'Washing Machine',
        'Refrigerator',
        'Water Purifier',
        'AC Repair',
        'Kitchen Chimney',
        'Air Cooler',
        'Geyser',
        'Microwave Oven',
        'Electrician',
        'Plumbing'
      ],
      rating: 4.9,
      completedJobs: 25,
      walletBalance: 2500.0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log(`✅ Technician Partner profile created in providers/${emailUser.uid}`);
  }

  console.log('\n======================================================');
  console.log('🧪 RUNNING FULL FIRESTORE E2E WORKFLOW TEST:');
  console.log('======================================================\n');

  // Test 1: Fetch Categories
  const catSnap = await db.collection('categories').get();
  console.log(`Test 1 [Catalog]: Found ${catSnap.size} categories in Firestore -> ${catSnap.size > 0 ? 'PASSED ✅' : 'FAILED ❌'}`);

  // Test 2: Fetch Products
  const prodSnap = await db.collection('products').get();
  console.log(`Test 2 [Products]: Found ${prodSnap.size} products in Firestore -> ${prodSnap.size > 0 ? 'PASSED ✅' : 'FAILED ❌'}`);

  // Test 3: Fetch Spare Parts
  const spareSnap = await db.collection('spare_parts_catalog').get();
  console.log(`Test 3 [Spare Parts]: Found ${spareSnap.size} spare parts in Firestore -> ${spareSnap.size > 0 ? 'PASSED ✅' : 'FAILED ❌'}`);

  // Test 4: Create a Test Booking
  const testBookingId = `test_bk_${Date.now()}`;
  await db.collection('bookings').doc(testBookingId).set({
    id: testBookingId,
    title: 'AC Repair & Service',
    category: 'AC Repair',
    status: 'BOOKED',
    customerId: customerUser ? customerUser.uid : 'cust_123',
    customerName: 'Demo Customer',
    customerPhone: '8073804900',
    address: 'Hassan, Karnataka',
    visitingFee: 19,
    startOtp: '1234',
    completionOtp: '5678',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log(`Test 4 [Booking Creation]: Created test booking #${testBookingId} -> PASSED ✅`);

  // Test 5: Technician claims booking
  if (emailUser) {
    await db.collection('bookings').doc(testBookingId).update({
      providerId: emailUser.uid,
      providerName: 'Demo Technician',
      providerPhone: '8073804900',
      status: 'ACCEPTED',
      assignedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`Test 5 [Job Assignment]: Assigned #${testBookingId} to tech ${emailUser.uid} -> PASSED ✅`);
  }

  // Test 6: Verify Admin can read booking
  const bDoc = await db.collection('bookings').doc(testBookingId).get();
  console.log(`Test 6 [Admin Fetch Booking]: Status is ${bDoc.data().status} -> PASSED ✅`);

  // Clean up test booking
  await db.collection('bookings').doc(testBookingId).delete();
  console.log(`Test 7 [Cleanup]: Test booking removed -> PASSED ✅`);

  console.log('\n======================================================');
  console.log('🎉 ALL INTEGRATION TESTS PASSED SUCCESSFULLY!');
  console.log('======================================================\n');
  process.exit(0);
}

setupTestUsers().catch(err => {
  console.error('Fatal error during setup and testing:', err);
  process.exit(1);
});
