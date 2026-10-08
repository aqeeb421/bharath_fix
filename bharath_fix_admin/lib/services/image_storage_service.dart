import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

      if (fileBytes.isEmpty && !kIsWeb && file.path != null) {
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
}
