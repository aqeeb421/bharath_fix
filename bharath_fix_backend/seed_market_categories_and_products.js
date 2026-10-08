const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(sa)
  });
}

const db = admin.firestore();

const CATEGORIES = [
  {
    id: 'cat_water_purifier',
    name: 'Water Purifier',
    iconName: 'water_drop_rounded',
    description: 'RO, UV, Copper & Alkaline Home Water Purifiers',
    gradientStart: 0xFF0D47A1,
    gradientEnd: 0xFF1976D2,
    order: 1,
    isActive: true,
  },
  {
    id: 'cat_cctv',
    name: 'CCTV Security Cameras',
    iconName: 'videocam_rounded',
    description: '4K Wi-Fi, Outdoor PTZ & HD DVR Security Systems',
    gradientStart: 0xFF1B5E20,
    gradientEnd: 0xFF388E3C,
    order: 2,
    isActive: true,
  },
  {
    id: 'cat_chimney',
    name: 'Chimney',
    iconName: 'soup_kitchen_rounded',
    description: 'Auto-clean, Filterless & Motion Gesture Kitchen Chimneys',
    gradientStart: 0xFFD84315,
    gradientEnd: 0xFFFF5722,
    order: 3,
    isActive: true,
  },
  {
    id: 'cat_stabilizer',
    name: 'Voltage Stabilizers',
    iconName: 'bolt_rounded',
    description: 'AC, Refrigerator & Mainline Voltage Regulators',
    gradientStart: 0xFFE65100,
    gradientEnd: 0xFFFFA000,
    order: 4,
    isActive: true,
  },
  {
    id: 'cat_ro_spares',
    name: 'Water Purifier Spare Parts',
    iconName: 'build_rounded',
    description: 'RO Membranes, Pre-filters, Carbon Cartridges & Booster Pumps',
    gradientStart: 0xFF00695C,
    gradientEnd: 0xFF00897B,
    order: 5,
    isActive: true,
  },
  {
    id: 'cat_geyser',
    name: 'Geysers (Gas & Electric)',
    iconName: 'local_fire_department_rounded',
    description: 'Storage, Instant Electric & Gas Water Heaters',
    gradientStart: 0xFFC2185B,
    gradientEnd: 0xFFE91E63,
    order: 6,
    isActive: true,
  },
  {
    id: 'cat_solar',
    name: 'Solar Solutions',
    iconName: 'wb_sunny_rounded',
    description: 'Solar Water Heaters, Rooftop PV Panels & Green Power Systems',
    gradientStart: 0xFFF57F17,
    gradientEnd: 0xFFFBC02D,
    order: 7,
    isActive: true,
  },
];

const SAMPLE_PRODUCTS = [
  {
    id: 'prod_sample_ro_01',
    name: 'AquaShield Pro 10L RO+UV+Copper',
    subCategory: 'Water Purifier',
    price: '₹7,999',
    originalPrice: '₹11,499',
    discountPercentage: 30,
    image: 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=500',
    description: 'Multi-stage RO+UV+Copper filtration with active mineralizer and 10-liter food-grade tank. Includes bundled same-day doorstep installation kit & demo.',
    stockQuantity: 8,
    inStock: true,
    warrantyPeriod: '1 Year Comprehensive Warranty',
    deliveryDays: 1,
    isInstallationNeeded: true,
    isInstallationFree: true,
    installationFee: 'FREE',
  },
  {
    id: 'prod_sample_cctv_01',
    name: 'Guardian 4K Wi-Fi Outdoor Smart Camera',
    subCategory: 'CCTV Security Cameras',
    price: '₹2,499',
    originalPrice: '₹3,999',
    discountPercentage: 37,
    image: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=500',
    description: 'Full-color night vision, 360-degree pan-tilt, AI human motion detection with 2-way audio. Certified technician installs & configures family smartphones.',
    stockQuantity: 4,
    inStock: true,
    warrantyPeriod: '1 Year Doorstep Replacement Warranty',
    deliveryDays: 1,
    isInstallationNeeded: true,
    isInstallationFree: true,
    installationFee: 'FREE',
  },
  {
    id: 'prod_sample_chimney_01',
    name: 'AeroClean 60cm Filterless Auto-Clean Chimney',
    subCategory: 'Chimney',
    price: '₹8,499',
    originalPrice: '₹13,999',
    discountPercentage: 39,
    image: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=500',
    description: 'Motion gesture sensor control with thermal auto-clean oil collector (1200 m³/hr suction). Bundled doorstep technician ducting & mounting included.',
    stockQuantity: 5,
    inStock: true,
    warrantyPeriod: '1 Year Product + 5 Year Motor Warranty',
    deliveryDays: 1,
    isInstallationNeeded: true,
    isInstallationFree: true,
    installationFee: 'FREE',
  },
  {
    id: 'prod_sample_stabilizer_01',
    name: 'VoltSafe 4kVA Heavy Duty AC Stabilizer',
    subCategory: 'Voltage Stabilizers',
    price: '₹2,199',
    originalPrice: '₹3,499',
    discountPercentage: 37,
    image: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=500',
    description: 'Digital display with micro-controlled high and low voltage cutoff protection. Suitable for up to 1.5 Ton inverter and non-inverter air conditioners.',
    stockQuantity: 12,
    inStock: true,
    warrantyPeriod: '3 Years Comprehensive Replacement Warranty',
    deliveryDays: 1,
    isInstallationNeeded: true,
    isInstallationFree: true,
    installationFee: 'FREE',
  },
  {
    id: 'prod_sample_ro_spare_01',
    name: 'AquaPure 80 GPD RO Membrane & Pre-Filter Kit',
    subCategory: 'Water Purifier Spare Parts',
    price: '₹899',
    originalPrice: '₹1,699',
    discountPercentage: 47,
    image: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500',
    description: 'Universal 80 GPD high TDS rejection Thin-Film Composite RO membrane bundled with 5-micron spun polypropylene sediment filter and activated carbon block.',
    stockQuantity: 25,
    inStock: true,
    warrantyPeriod: '6 Months Performance Warranty',
    deliveryDays: 1,
    isInstallationNeeded: true,
    isInstallationFree: false,
    installationFee: '₹149',
  },
  {
    id: 'prod_sample_geyser_01',
    name: 'ThermoHeat 15L 5-Star Storage Electric Geyser',
    subCategory: 'Geysers (Gas & Electric)',
    price: '₹5,699',
    originalPrice: '₹8,999',
    discountPercentage: 36,
    image: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500',
    description: 'High-grade glass-lined anti-rust storage tank with heavy PUF insulation and preset thermal cutoff. Bundled inlet/outlet plumbing kit included.',
    stockQuantity: 6,
    inStock: true,
    warrantyPeriod: '2 Years Product + 5 Years Tank Warranty',
    deliveryDays: 1,
    isInstallationNeeded: true,
    isInstallationFree: true,
    installationFee: 'FREE',
  },
  {
    id: 'prod_sample_solar_01',
    name: 'SunPower 100L ETC Solar Water Heating System',
    subCategory: 'Solar Solutions',
    price: '₹14,999',
    originalPrice: '₹22,000',
    discountPercentage: 31,
    image: 'https://images.unsplash.com/photo-1509391365360-2e959784a276?w=500',
    description: 'Evacuated Tube Collector (ETC) technology with food-grade stainless steel inner tank. Zero electricity cost with doorstep rooftop installation service.',
    stockQuantity: 3,
    inStock: true,
    warrantyPeriod: '5 Years Manufacturer Comprehensive Warranty',
    deliveryDays: 2,
    isInstallationNeeded: true,
    isInstallationFree: true,
    installationFee: 'FREE',
  },
];

async function seedData() {
  console.log('🚀 Seeding market_categories into Firestore...');
  for (const cat of CATEGORIES) {
    await db.collection('market_categories').doc(cat.id).set(cat, { merge: true });
    console.log(`  ✅ Category: ${cat.name} (${cat.id})`);
  }

  console.log('🚀 Seeding sample products into Firestore...');
  for (const prod of SAMPLE_PRODUCTS) {
    await db.collection('products').doc(prod.id).set(prod, { merge: true });
    console.log(`  ✅ Product: ${prod.name} [${prod.subCategory}] (${prod.id})`);
  }

  // Update existing products to have subCategory 'Water Purifier' if missing or different
  const existingProds = await db.collection('products').get();
  for (const doc of existingProds.docs) {
    const data = doc.data();
    if (!data.subCategory || data.subCategory === 'All' || data.subCategory === 'RO' || data.subCategory.toLowerCase().includes('water')) {
      await doc.ref.set({ subCategory: 'Water Purifier' }, { merge: true });
    }
  }

  // Bump catalog version to notify clients
  await db.collection('banners').doc('catalog_metadata').set({
    version: admin.firestore.FieldValue.increment(1),
    lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  console.log('🎉 Successfully seeded market categories and sample products, and bumped catalog version!');
}

seedData().catch(err => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
