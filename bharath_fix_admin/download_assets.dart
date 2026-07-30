import 'dart:io';

void main() async {
  final Directory targetDir = Directory('web/app_images');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final Map<String, String> assets = {
    'refrigerator.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/French_door_refrigerator.jpg/640px-French_door_refrigerator.jpg',
    'washing_machine.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Front-loading-washing-machine.jpg/640px-Front-loading-washing-machine.jpg',
    'water_purifier.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Reverse_osmosis_purifier.jpg/640px-Reverse_osmosis_purifier.jpg',
    'air_conditioner.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Split_air_conditioner.jpg/640px-Split_air_conditioner.jpg',
    'kitchen_chimney.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Extractor_hood.jpg/640px-Extractor_hood.jpg',
    'air_cooler.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Evaporative_cooler.jpg/640px-Evaporative_cooler.jpg',
    'geyser.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Electric_water_heater.jpg/640px-Electric_water_heater.jpg',
    'microwave.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Microwave_oven.jpg/640px-Microwave_oven.jpg'
  };

  final client = HttpClient();

  for (var entry in assets.entries) {
    final fileName = entry.key;
    final url = entry.value;
    final file = File('${targetDir.path}/$fileName');

    print('Downloading $fileName from $url...');
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
  print('Completed downloading all local category images!');
}
