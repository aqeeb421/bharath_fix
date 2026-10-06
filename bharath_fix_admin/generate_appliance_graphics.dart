import 'dart:io';

void main() async {
  final Directory targetDir = Directory('web/app_images');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final brainDir1 = 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a';
  final brainDir2 = 'C:/Users/user/.gemini/antigravity-ide/brain/17eb0703-52cc-4d64-8c58-764a633fa8ad';

  // Nested category/sub-category, products/product_type, and banners/top_banner & bottom_banner
  final Map<String, String> nestedMapping = {
    // --- 1. CATEGORIES: categories/category/sub_category.png ---
    // Refrigerator
    'categories/refrigerator/single_door.png': '$brainDir1/single_door_fridge_1784539120885.png',
    'categories/refrigerator/double_door.png': '$brainDir1/double_door_fridge_1784539157416.png',
    'categories/refrigerator/bottom_freezer.png': '$brainDir1/bottom_freezer_fridge_1784539172137.png',
    'categories/refrigerator/triple_door.png': '$brainDir1/s1_4_triple_door_fridge_1784540636893.png',
    'categories/refrigerator/deep_freezer.png': '$brainDir1/deep_freezer_1784539185169.png',

    // Washing Machine
    'categories/washing_machine/top_load.png': '$brainDir1/s2_1_top_load_washer_1784540651858.png',
    'categories/washing_machine/front_load.png': '$brainDir1/s2_2_front_load_washer_1784540666158.png',
    'categories/washing_machine/semi_automatic.png': '$brainDir1/s2_3_semi_auto_washer_1784540680090.png',
    'categories/washing_machine/fully_automatic.png': '$brainDir1/s2_4_fully_auto_washer_1784540695167.png',

    // Water Purifier
    'categories/water_purifier/hot_cool_ro.png': '$brainDir1/s3_1_hot_cool_ro_1784540708036.png',
    'categories/water_purifier/uv_ro_purifier.png': '$brainDir1/s3_2_uv_ro_purifier_1784540723431.png',
    'categories/water_purifier/commercial_plant.png': '$brainDir1/s3_3_commercial_plant_1784540738947.png',

    // AC Repair
    'categories/ac_repair/split_ac.png': '$brainDir1/s4_1_split_ac_1784540751933.png',
    'categories/ac_repair/ductable_ac.png': '$brainDir2/ac_ductable_1791289643420.jpg',

    // Kitchen Chimney
    'categories/kitchen_chimney/analog_control.png': '$brainDir2/chimney_analog_control_1791289546818.jpg',
    'categories/kitchen_chimney/digital_touch.png': '$brainDir2/chimney_digital_touch_1791289568262.jpg',

    // Air Cooler (AUTHENTIC STUDIO PHOTOS)
    'categories/air_cooler/desert_cooler.png': '$brainDir2/air_cooler_desert_1791289463724.jpg',
    'categories/air_cooler/personal_tower_cooler.png': '$brainDir2/air_cooler_tower_1791289482604.jpg',

    // Geyser (AUTHENTIC STUDIO PHOTOS)
    'categories/geyser/instant_geyser.png': '$brainDir2/geyser_instant_1791289596418.jpg',
    'categories/geyser/storage_tank_geyser.png': '$brainDir2/geyser_storage_tank_1791289619780.jpg',

    // Microwave Oven (AUTHENTIC STUDIO PHOTOS)
    'categories/microwave_oven/convection_oven.png': '$brainDir2/microwave_convection_1791289503766.jpg',
    'categories/microwave_oven/solo_grill_microwave.png': '$brainDir2/microwave_grill_solo_1791289523462.jpg',

    // --- 2. PRODUCTS: products/product_type/product_name.png ---
    'products/standard_ro/aquapure_economic_ro.png': '$brainDir2/aquapure_economic_ro_1791289669327.jpg',
    'products/standard_ro/aquashield_copper_ro.png': '$brainDir2/aquashield_copper_ro_1791289716709.jpg',
    'products/uv_purifier/livpure_uv_compact.png': '$brainDir2/livpure_uv_compact_1791289691442.jpg',
    'products/uv_purifier/kent_maxima_pro_ro_uv.png': '$brainDir1/s3_1_hot_cool_ro_1784540708036.png',
    'products/alkaline_special/hydroalkaline_premium.png': '$brainDir2/hydroalkaline_premium_1791289746960.jpg',
    'products/alkaline_special/aquagrand_luxury_custom.png': '$brainDir1/s3_2_uv_ro_purifier_1784540723431.png',

    // --- 3. BANNERS: banners/top_banner and banners/bottom_banner ---
    'banners/top_banner/chimney_cleaning.png': '$brainDir2/chimney_digital_touch_1791289568262.jpg',
    'banners/top_banner/washing_machine_service.png': '$brainDir1/s2_2_front_load_washer_1784540666158.png',
    'banners/bottom_banner/water_purifier_servicing.png': '$brainDir1/s3_2_uv_ro_purifier_1784540723431.png',
  };

  print('Organizing images into categories/, products/<type>/, and banners/<top|bottom>_banner/ ...');
  for (var entry in nestedMapping.entries) {
    final src = File(entry.value);
    final dest = File('${targetDir.path}/${entry.key}');
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }
    if (await src.exists()) {
      await src.copy(dest.path);
      print('✓ Copied ${entry.key}');
    } else {
      print('✗ Missing: ${src.path}');
    }
  }

  print('\nAll files organized in nested categories, products, and banners structures!');
}
