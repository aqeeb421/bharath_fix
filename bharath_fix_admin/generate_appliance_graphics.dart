import 'dart:io';

void main() async {
  final Directory targetDir = Directory('web/app_images');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  // 1. Copy all AI generated studio photos
  final aiFiles = {
    's1_1.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/single_door_fridge_1784539120885.png',
    's1_2.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/double_door_fridge_1784539157416.png',
    's1_3.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/bottom_freezer_fridge_1784539172137.png',
    's1_4.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s1_4_triple_door_fridge_1784540636893.png',
    's1_5.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/deep_freezer_1784539185169.png',
    's2_1.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s2_1_top_load_washer_1784540651858.png',
    's2_2.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s2_2_front_load_washer_1784540666158.png',
    's2_3.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s2_3_semi_auto_washer_1784540680090.png',
    's2_4.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s2_4_fully_auto_washer_1784540695167.png',
    's3_1.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s3_1_hot_cool_ro_1784540708036.png',
    's3_2.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s3_2_uv_ro_purifier_1784540723431.png',
    's3_3.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s3_3_commercial_plant_1784540738947.png',
    's4_1.png': 'C:/Users/user/.gemini/antigravity-ide/brain/7bfb50a4-5b20-4c91-9f37-dc01ab20140a/s4_1_split_ac_1784540751933.png',
  };

  for (var entry in aiFiles.entries) {
    final aiFile = File(entry.value);
    if (await aiFile.exists()) {
      await aiFile.copy('${targetDir.path}/${entry.key}');
      print('Copied AI generated photo to ${entry.key}');
    }
  }

  // 2. Download high-definition appliance photos for remaining subcategories
  final Map<String, String> remainingAssets = {
    's4_2.png': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&q=80&w=400',
    's5_1.png': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80&w=400',
    's5_2.png': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80&w=400',
    's6_1.png': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&q=80&w=400',
    's6_2.png': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&q=80&w=400',
    's7_1.png': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&q=80&w=400',
    's7_2.png': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&q=80&w=400',
    's8_1.png': 'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?auto=format&fit=crop&q=80&w=400',
    's8_2.png': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?auto=format&fit=crop&q=80&w=400',
  };

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  for (var entry in remainingAssets.entries) {
    final fileName = entry.key;
    final url = entry.value;
    final file = File('${targetDir.path}/$fileName');

    print('Downloading photo for $fileName...');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (list, element) => list..addAll(element));
        await file.writeAsBytes(bytes);
        print('Successfully saved $fileName.');
      } else {
        print('Failed to download $fileName: HTTP Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading $fileName: $e');
    }
  }

  client.close();
  print('All 24 subcategory real appliance photos are ready in web/app_images/!');
}
