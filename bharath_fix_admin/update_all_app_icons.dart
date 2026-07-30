import 'dart:io';
import 'package:image/image.dart';

void main() {
  final srcPath = 'C:/Users/user/.gemini/antigravity-ide/brain/26c91556-597b-421a-a440-4b3454509d15/media__1784612900061.png';
  final srcFile = File(srcPath);
  if (!srcFile.existsSync()) {
    print('Source image not found at $srcPath');
    return;
  }

  final bytes = srcFile.readAsBytesSync();
  final image = decodePng(bytes);
  if (image == null) {
    print('Failed to decode source PNG image');
    return;
  }

  print('Loaded source image (${image.width}x${image.height})');

  void saveResized(String targetPath, int width, int height) {
    final resized = copyResize(image, width: width, height: height);
    final targetFile = File(targetPath);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsBytesSync(encodePng(resized));
    print('Saved $width x $height -> $targetPath');
  }

  final projects = [
    'c:/Users/user/Documents/AntiGravity/bharath_fix',
    'c:/Users/user/Documents/AntiGravity/bharath_fix_technician_app',
    'c:/Users/user/Documents/AntiGravity/bharath_fix_admin',
  ];

  for (final root in projects) {
    print('\n--- Updating icons for $root ---');

    // 1. Assets
    saveResized('$root/assets/images/app_icon.png', 1024, 1024);
    saveResized('$root/assets/images/app_icon_foreground.png', 1024, 1024);

    // 2. Android mipmaps (if android dir exists)
    final androidRes = Directory('$root/android/app/src/main/res');
    if (androidRes.existsSync()) {
      final androidSizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
      };

      for (final entry in androidSizes.entries) {
        final folder = entry.key;
        final size = entry.value;
        saveResized('${androidRes.path}/$folder/ic_launcher.png', size, size);
        saveResized('${androidRes.path}/$folder/ic_launcher_round.png', size, size);
        saveResized('${androidRes.path}/$folder/ic_launcher_foreground.png', size, size);
      }
    }

    // 3. iOS AppIcon set (if ios dir exists)
    final iosAppIconDir = Directory('$root/ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (iosAppIconDir.existsSync()) {
      final iosSizes = {
        'Icon-App-1024x1024@1x.png': 1024,
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-50x50@1x.png': 50,
        'Icon-App-50x50@2x.png': 100,
        'Icon-App-57x57@1x.png': 57,
        'Icon-App-57x57@2x.png': 114,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-72x72@1x.png': 72,
        'Icon-App-72x72@2x.png': 144,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
      };

      for (final entry in iosSizes.entries) {
        saveResized('${iosAppIconDir.path}/${entry.key}', entry.value, entry.value);
      }
    }

    // 4. Web icons (if web dir exists)
    final webDir = Directory('$root/web');
    if (webDir.existsSync()) {
      saveResized('${webDir.path}/favicon.png', 32, 32);
      saveResized('${webDir.path}/icons/Icon-192.png', 192, 192);
      saveResized('${webDir.path}/icons/Icon-512.png', 512, 512);
      saveResized('${webDir.path}/icons/Icon-maskable-192.png', 192, 192);
      saveResized('${webDir.path}/icons/Icon-maskable-512.png', 512, 512);
    }
  }

  print('\nALL_ICONS_UPDATED_SUCCESSFULLY');
}
