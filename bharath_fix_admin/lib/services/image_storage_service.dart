import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ImageStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Helper to convert human-readable item titles into clean, standardized storage slugs.
  /// e.g. "Air Cooler - Desert Cooler" -> "air_cooler_desert_cooler"
  static String sanitizeSlug(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Format an organized, semantic Firebase Storage path for an item.
  /// e.g. folder: "categories", categoryName: "Air Cooler", itemName: "Desert Cooler"
  /// -> "app_images/categories/air_cooler/desert_cooler.png"
  static String formatItemStoragePath({
    required String subFolder,
    required String itemName,
    String? categoryName,
    String extension = 'png',
  }) {
    final itemSlug = sanitizeSlug(itemName);
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final catSlug = sanitizeSlug(categoryName);
      return 'app_images/$subFolder/$catSlug/$itemSlug.$extension';
    }
    return 'app_images/$subFolder/$itemSlug.$extension';
  }

  /// Picks an image from the device/desktop and uploads it directly to Firebase Storage
  /// using the semantic category/sub-category naming convention.
  /// Returns the permanent public download URL, or null if cancelled/failed.
  static Future<String?> pickAndUploadImage({
    required BuildContext context,
    String subFolder = 'catalog',
    String? itemName,
    String? categoryName,
    void Function(bool isUploading)? onLoadingChanged,
  }) async {
    try {
      // 1. Pick Image File
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true, // Needed for Flutter Web
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = result.files.single;
      Uint8List fileBytes = file.bytes ?? Uint8List(0);

      if (fileBytes.isEmpty && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes.isEmpty || !isValidImageBytes(fileBytes)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected file is not a valid image format (PNG, JPEG, WebP required).'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      onLoadingChanged?.call(true);

      // 2. Prepare Storage Path using Semantic Category/Subcategory Structure
      final extension = (file.extension ?? 'png').toLowerCase();
      final String storagePath;
      if (itemName != null && itemName.trim().isNotEmpty) {
        storagePath = formatItemStoragePath(
          subFolder: subFolder,
          itemName: itemName.trim(),
          categoryName: categoryName,
          extension: extension,
        );
      } else {
        final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        storagePath = 'app_images/$subFolder/${timestamp}_$sanitizedName';
      }

      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: extension == 'jpg' || extension == 'jpeg' ? 'image/jpeg' : 'image/$extension',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': file.name,
          'itemName': itemName ?? file.name,
          'category': categoryName ?? subFolder,
          'storagePath': storagePath,
        },
      );

      // 3. Upload Data to Firebase Storage
      final uploadTask = ref.putData(fileBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      onLoadingChanged?.call(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded to Storage: $storagePath'),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      onLoadingChanged?.call(false);
      debugPrint('Firebase Storage Error [${e.code}]: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'object-not-found' || e.code == 'bucket-not-found'
                  ? 'Firebase Storage bucket not configured. Please enable Storage in Firebase Console.'
                  : 'Storage upload failed: ${e.message ?? e.code}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    } catch (e) {
      onLoadingChanged?.call(false);
      debugPrint('General Image Upload Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Complete list of all appliance catalog items with nested category/sub-category paths
  static final List<Map<String, String>> catalogImageDefinitions = [
    // --- REFRIGERATORS ---
    {'storagePath': 'categories/refrigerator/single_door.png', 'legacyCode': 's1_1.png', 'category': 'm1', 'subId': 's1_1', 'name': 'Single Door'},
    {'storagePath': 'categories/refrigerator/double_door.png', 'legacyCode': 's1_2.png', 'category': 'm1', 'subId': 's1_2', 'name': 'Double Door'},
    {'storagePath': 'categories/refrigerator/bottom_freezer.png', 'legacyCode': 's1_3.png', 'category': 'm1', 'subId': 's1_3', 'name': 'Bottom Freezer'},
    {'storagePath': 'categories/refrigerator/triple_door.png', 'legacyCode': 's1_4.png', 'category': 'm1', 'subId': 's1_4', 'name': 'Triple Door'},
    {'storagePath': 'categories/refrigerator/deep_freezer.png', 'legacyCode': 's1_5.png', 'category': 'm1', 'subId': 's1_5', 'name': 'Deep Freezer'},

    // --- WASHING MACHINES ---
    {'storagePath': 'categories/washing_machine/top_load.png', 'legacyCode': 's2_1.png', 'category': 'm2', 'subId': 's2_1', 'name': 'Top Load'},
    {'storagePath': 'categories/washing_machine/front_load.png', 'legacyCode': 's2_2.png', 'category': 'm2', 'subId': 's2_2', 'name': 'Front Load'},
    {'storagePath': 'categories/washing_machine/semi_automatic.png', 'legacyCode': 's2_3.png', 'category': 'm2', 'subId': 's2_3', 'name': 'Semi-Automatic'},
    {'storagePath': 'categories/washing_machine/fully_automatic.png', 'legacyCode': 's2_4.png', 'category': 'm2', 'subId': 's2_4', 'name': 'Fully Automatic'},

    // --- WATER PURIFIERS ---
    {'storagePath': 'categories/water_purifier/hot_cool_ro.png', 'legacyCode': 's3_1.png', 'category': 'm3', 'subId': 's3_1', 'name': 'Hot and Cool RO'},
    {'storagePath': 'categories/water_purifier/uv_ro_purifier.png', 'legacyCode': 's3_2.png', 'category': 'm3', 'subId': 's3_2', 'name': 'UV RO Purifier'},
    {'storagePath': 'categories/water_purifier/commercial_plant.png', 'legacyCode': 's3_3.png', 'category': 'm3', 'subId': 's3_3', 'name': 'Commercial Plant'},

    // --- AC REPAIR ---
    {'storagePath': 'categories/ac_repair/split_ac.png', 'legacyCode': 's4_1.png', 'category': 'm4', 'subId': 's4_1', 'name': 'Split AC'},
    {'storagePath': 'categories/ac_repair/ductable_ac.png', 'legacyCode': 's4_2.png', 'category': 'm4', 'subId': 's4_2', 'name': 'Ductable AC'},

    // --- KITCHEN CHIMNEY ---
    {'storagePath': 'categories/kitchen_chimney/analog_control.png', 'legacyCode': 's5_1.png', 'category': 'm5', 'subId': 's5_1', 'name': 'Analog Control'},
    {'storagePath': 'categories/kitchen_chimney/digital_touch.png', 'legacyCode': 's5_2.png', 'category': 'm5', 'subId': 's5_2', 'name': 'Digital Touch'},

    // --- AIR COOLER (AUTHENTIC DEDICATED APPLIANCES) ---
    {'storagePath': 'categories/air_cooler/desert_cooler.png', 'legacyCode': 's6_1.png', 'category': 'm6', 'subId': 's6_1', 'name': 'Desert Cooler'},
    {'storagePath': 'categories/air_cooler/personal_tower_cooler.png', 'legacyCode': 's6_2.png', 'category': 'm6', 'subId': 's6_2', 'name': 'Personal Tower Cooler'},

    // --- GEYSER (AUTHENTIC DEDICATED APPLIANCES) ---
    {'storagePath': 'categories/geyser/instant_geyser.png', 'legacyCode': 's7_1.png', 'category': 'm7', 'subId': 's7_1', 'name': 'Instant Geyser'},
    {'storagePath': 'categories/geyser/storage_tank_geyser.png', 'legacyCode': 's7_2.png', 'category': 'm7', 'subId': 's7_2', 'name': 'Storage Tank Geyser'},

    // --- MICROWAVE OVEN (AUTHENTIC DEDICATED APPLIANCES) ---
    {'storagePath': 'categories/microwave_oven/convection_oven.png', 'legacyCode': 's8_1.png', 'category': 'm8', 'subId': 's8_1', 'name': 'Convection Oven'},
    {'storagePath': 'categories/microwave_oven/solo_grill_microwave.png', 'legacyCode': 's8_2.png', 'category': 'm8', 'subId': 's8_2', 'name': 'Solo / Grill Microwave'},

    // --- RETAIL PRODUCTS (SALES ITEMS - products/product_type/product_name.png) ---
    {'storagePath': 'products/standard_ro/aquapure_economic_ro.png', 'legacyCode': 's3_1.png', 'productId': 'p1', 'name': 'AquaPure Economic RO'},
    {'storagePath': 'products/uv_purifier/livpure_uv_compact.png', 'legacyCode': 's3_2.png', 'productId': 'p2', 'name': 'LivPure UV Compact'},
    {'storagePath': 'products/standard_ro/aquashield_copper_ro.png', 'legacyCode': 's3_3.png', 'productId': 'p3', 'name': 'AquaShield Copper RO'},
    {'storagePath': 'products/alkaline_special/hydroalkaline_premium.png', 'legacyCode': 's3_1.png', 'productId': 'p4', 'name': 'HydroAlkaline Premium'},
    {'storagePath': 'products/uv_purifier/kent_maxima_pro_ro_uv.png', 'legacyCode': 's3_2.png', 'productId': 'p5', 'name': 'Kent Maxima Pro RO+UV'},
    {'storagePath': 'products/alkaline_special/aquagrand_luxury_custom.png', 'legacyCode': 's3_3.png', 'productId': 'p6', 'name': 'AquaGrand Luxury Custom'},

    // --- PROMOTIONAL BANNERS (banners/top_banner/ and banners/bottom_banner/) ---
    {'storagePath': 'banners/top_banner/chimney_cleaning.png', 'legacyCode': 's5_2.png', 'bannerId': 'banner_0', 'name': 'Chimney Cleaning Banner'},
    {'storagePath': 'banners/top_banner/washing_machine_service.png', 'legacyCode': 's2_2.png', 'bannerId': 'banner_1', 'name': 'Washing Machine Banner'},
    {'storagePath': 'banners/bottom_banner/water_purifier_servicing.png', 'legacyCode': 's3_2.png', 'bannerId': 'banner_2', 'name': 'RO Purifier Banner'},
  ];

  /// Validates that raw bytes correspond to a genuine image format (PNG, JPEG, WebP)
  /// and NEVER an HTML fallback response (e.g. Flutter Web dev server index.html ~1253 bytes).
  static bool isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 100) return false;

    // Check for HTML text signatures: "<!DOCTYPE", "<html", "<head"
    if (bytes[0] == 0x3C) { // '<'
      return false;
    }

    // PNG signature: 0x89 0x50 0x4E 0x47 (\x89PNG)
    final isPng = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
    if (isPng) return true;

    // JPEG signature: 0xFF 0xD8 0xFF
    final isJpg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    if (isJpg) return true;

    // WebP signature: "RIFF" .... "WEBP"
    final isWebp = bytes.length > 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50;
    if (isWebp) return true;

    return false;
  }

  /// Synchronizes all catalog, category, subcategory, retail product, and banner images
  /// with their respective semantic item names into Firebase Storage.
  /// Automatically updates all Firestore documents with the new permanent Firebase Storage download URLs.
  static Future<Map<String, dynamic>> migrateNetlifyImagesToFirebaseStorage({
    required void Function(String status, double progress) onProgress,
  }) async {
    final Map<String, String> urlMapping = {};
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    int successCount = 0;

    for (int i = 0; i < catalogImageDefinitions.length; i++) {
      final def = catalogImageDefinitions[i];
      final storagePath = def['storagePath']!;
      final legacyCode = def['legacyCode']!;
      final itemName = def['name'] ?? storagePath;

      onProgress(
        'Processing $itemName (${storagePath.split('/').last}) (${i + 1}/${catalogImageDefinitions.length})...',
        (i + 1) / (catalogImageDefinitions.length + 5),
      );

      Uint8List? imageBytes;

      // Priority 1: Load directly from Flutter asset bundle (Offline, reliable, never returns index.html)
      try {
        final assetData = await rootBundle.load('assets/app_images/$storagePath');
        final bytes = assetData.buffer.asUint8List();
        if (isValidImageBytes(bytes)) {
          imageBytes = bytes;
          debugPrint('✓ Sourced from bundle assets: assets/app_images/$storagePath (${bytes.length} bytes)');
        }
      } catch (_) {}

      // Priority 2: Load legacy code from Flutter asset bundle
      if (imageBytes == null || imageBytes.isEmpty) {
        try {
          final assetData = await rootBundle.load('assets/app_images/$legacyCode');
          final bytes = assetData.buffer.asUint8List();
          if (isValidImageBytes(bytes)) {
            imageBytes = bytes;
            debugPrint('✓ Sourced legacy from bundle assets: assets/app_images/$legacyCode (${bytes.length} bytes)');
          }
        } catch (_) {}
      }

      // Priority 3: Try web/app_images directly via rootBundle
      if (imageBytes == null || imageBytes.isEmpty) {
        try {
          final assetData = await rootBundle.load('web/app_images/$storagePath');
          final bytes = assetData.buffer.asUint8List();
          if (isValidImageBytes(bytes)) {
            imageBytes = bytes;
            debugPrint('✓ Sourced from web/app_images bundle: $storagePath (${bytes.length} bytes)');
          }
        } catch (_) {}
      }

      // Priority 4: Try local web server semantic URL (STRICT VALIDATION to reject index.html SPA fallback!)
      if (imageBytes == null || imageBytes.isEmpty) {
        try {
          final semanticUrl = '${Uri.base.origin}/app_images/$storagePath';
          final res = await http.get(Uri.parse(semanticUrl)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 && isValidImageBytes(res.bodyBytes)) {
            imageBytes = res.bodyBytes;
            debugPrint('✓ Sourced via web server URL: $semanticUrl (${res.bodyBytes.length} bytes)');
          }
        } catch (_) {}
      }

      // Priority 5: Try local web server legacy code (STRICT VALIDATION to reject index.html SPA fallback!)
      if (imageBytes == null || imageBytes.isEmpty) {
        try {
          final legacyUrl = '${Uri.base.origin}/app_images/$legacyCode';
          final res = await http.get(Uri.parse(legacyUrl)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 && isValidImageBytes(res.bodyBytes)) {
            imageBytes = res.bodyBytes;
            debugPrint('✓ Sourced via web server legacy URL: $legacyUrl (${res.bodyBytes.length} bytes)');
          }
        } catch (_) {}
      }

      // Priority 6: Remote Netlify fallback URL (STRICT VALIDATION)
      if (imageBytes == null || imageBytes.isEmpty) {
        try {
          final netlifyUrl = 'https://bharath-fix.netlify.app/app_images/$legacyCode';
          final res = await http.get(Uri.parse(netlifyUrl)).timeout(const Duration(seconds: 6));
          if (res.statusCode == 200 && isValidImageBytes(res.bodyBytes)) {
            imageBytes = res.bodyBytes;
            debugPrint('✓ Sourced from Netlify fallback: $netlifyUrl (${res.bodyBytes.length} bytes)');
          }
        } catch (_) {}
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          final ref = storage.ref().child('app_images/$storagePath');
          await ref.putData(
            imageBytes,
            SettableMetadata(
              contentType: 'image/png',
              customMetadata: {
                'itemName': itemName,
                'storagePath': storagePath,
                'uploadedAt': DateTime.now().toIso8601String(),
              },
            ),
          );
          final downloadUrl = await ref.getDownloadURL();
          urlMapping[storagePath] = downloadUrl;
          urlMapping[legacyCode] = downloadUrl;
          urlMapping['https://bharath-fix.netlify.app/app_images/$legacyCode'] = downloadUrl;
          if (def.containsKey('productId')) {
            urlMapping['product_${def['productId']}'] = downloadUrl;
          }
          if (def.containsKey('bannerId')) {
            urlMapping['banner_${def['bannerId']}'] = downloadUrl;
          }
          successCount++;
          debugPrint('✅ Uploaded semantic asset [$storagePath] -> $downloadUrl');
        } on FirebaseException catch (e) {
          debugPrint('Firebase Storage error for $storagePath [${e.code}]: ${e.message}');
        } catch (e) {
          debugPrint('Error uploading $storagePath: $e');
        }
      } else {
        debugPrint('⚠️ Could not obtain bytes for $storagePath (tried $legacyCode)');
      }
    }

    onProgress('Updating Firestore categories and subcategories with semantic URLs...', 0.85);

    // Update Categories & Subcategories
    int updatedDocs = 0;
    try {
      final categoriesSnap = await firestore.collection('categories').get();
      for (final doc in categoriesSnap.docs) {
        final data = doc.data();
        bool modified = false;

        final subCats = data['subCategories'] as List<dynamic>?;
        if (subCats != null) {
          final updatedSubCats = <Map<String, dynamic>>[];
          for (final sub in subCats) {
            if (sub is Map) {
              final subMap = Map<String, dynamic>.from(sub);
              final subId = subMap['id']?.toString() ?? '';
              
              // Find matching definition
              final matchingDef = catalogImageDefinitions.firstWhere(
                (d) => d['subId'] == subId,
                orElse: () => {},
              );

              if (matchingDef.isNotEmpty && urlMapping.containsKey(matchingDef['storagePath'])) {
                subMap['image'] = urlMapping[matchingDef['storagePath']];
                subMap['placeholderImage'] = urlMapping[matchingDef['storagePath']];
                modified = true;
              }
              updatedSubCats.add(subMap);
            }
          }
          if (modified) {
            data['subCategories'] = updatedSubCats;
          }
        }

        if (modified) {
          await doc.reference.update(data);
          updatedDocs++;
        }
      }
    } catch (e) {
      debugPrint('Error updating categories: $e');
    }

    onProgress('Updating Firestore products with dedicated Water Purifier and Appliance photos...', 0.92);

    // Update Products (Fixes microwave/fridge mismatches!)
    try {
      final productsSnap = await firestore.collection('products').get();
      for (final doc in productsSnap.docs) {
        final prodId = doc.id;
        final matchingDef = catalogImageDefinitions.firstWhere(
          (d) => d['productId'] == prodId,
          orElse: () => {},
        );

        if (matchingDef.isNotEmpty && urlMapping.containsKey(matchingDef['storagePath'])) {
          final newUrl = urlMapping[matchingDef['storagePath']]!;
          await doc.reference.update({
            'imageUrl': newUrl,
            'image': newUrl,
          });
          updatedDocs++;
        }
      }
    } catch (e) {
      debugPrint('Error updating products: $e');
    }

    onProgress('Updating Firestore promotional banners...', 0.98);

    // Update Banners
    try {
      final bannersSnap = await firestore.collection('banners').get();
      for (final doc in bannersSnap.docs) {
        final bannerId = doc.id;
        final matchingDef = catalogImageDefinitions.firstWhere(
          (d) => d['bannerId'] == bannerId,
          orElse: () => {},
        );

        if (matchingDef.isNotEmpty && urlMapping.containsKey(matchingDef['storagePath'])) {
          final newUrl = urlMapping[matchingDef['storagePath']]!;
          await doc.reference.update({'image': newUrl});
          updatedDocs++;
        }
      }
    } catch (e) {
      debugPrint('Error updating banners: $e');
    }

    onProgress('Complete! All items migrated to semantic Firebase Storage paths.', 1.0);
    return {
      'imagesUploaded': successCount,
      'docsUpdated': updatedDocs,
    };
  }
}
