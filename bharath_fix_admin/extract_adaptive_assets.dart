import 'dart:io';
import 'package:image/image.dart';

void main() {
  final srcPath = 'C:/Users/user/.gemini/antigravity-ide/brain/26c91556-597b-421a-a440-4b3454509d15/media__1784612900061.png';
  final srcFile = File(srcPath);
  if (!srcFile.existsSync()) {
    print('Source image not found!');
    return;
  }

  final image = decodePng(srcFile.readAsBytesSync());
  if (image == null) {
    print('Failed to decode image');
    return;
  }

  final cornerPixel = image.getPixel(200, 200);
  final r = cornerPixel.r.toInt();
  final g = cornerPixel.g.toInt();
  final b = cornerPixel.b.toInt();
  final bgHex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  print('Detected background color: $bgHex (R:$r, G:$g, B:$b)');

  // Create transparent foreground image
  final fgImage = Image(width: image.width, height: image.height, numChannels: 4);
  
  // Make background pixels transparent, keep white logo pixels
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final pr = p.r.toInt();
      final pg = p.g.toInt();
      final pb = p.b.toInt();
      
      // Calculate color distance to background
      final diff = (pr - r).abs() + (pg - g).abs() + (pb - b).abs();
      
      if (diff < 60) {
        // Transparent background
        fgImage.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        // Keep foreground logo
        fgImage.setPixel(x, y, p);
      }
    }
  }

  // Scale down the foreground logo to 65% size so it stays within Android adaptive safe zone (72dp inner area out of 108dp)
  final canvas = Image(width: 1024, height: 1024, numChannels: 4);
  canvas.clear(ColorUint8.rgba(0, 0, 0, 0));
  
  final scaledFg = copyResize(fgImage, width: 680, height: 680);
  compositeImage(canvas, scaledFg, dstX: 172, dstY: 172);

  final targetDirs = [
    'c:/Users/user/Documents/AntiGravity/bharath_fix/assets/images',
    'c:/Users/user/Documents/AntiGravity/bharath_fix_technician_app/assets/images',
    'c:/Users/user/Documents/AntiGravity/bharath_fix_admin/assets/images',
  ];

  for (final dirPath in targetDirs) {
    final dir = Directory(dirPath);
    dir.createSync(recursive: true);

    // Save full icon (with background)
    File('${dir.path}/app_icon.png').writeAsBytesSync(encodePng(image));

    // Save adaptive foreground icon (transparent with safe-zone scaling)
    File('${dir.path}/app_icon_foreground.png').writeAsBytesSync(encodePng(canvas));

    print('Updated assets in $dirPath');
  }

  print('BACKGROUND_HEX=$bgHex');
}
