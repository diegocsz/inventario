import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LocalImageStorage {
  static const int maxBytes = 10 * 1024 * 1024;
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickAndSave() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final source = File(picked.path);
    final length = await source.length();
    if (length > maxBytes)
      throw Exception('La imagen supera el limite de 10 MB');
    final directory = await getApplicationDocumentsDirectory();
    final images = Directory('${directory.path}/product_images');
    if (!await images.exists()) await images.create(recursive: true);
    final extension = picked.name.contains('.')
        ? '.${picked.name.split('.').last.toLowerCase()}'
        : '.jpg';
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${extension.replaceAll(RegExp(r'[^a-z0-9.]'), '')}';
    final destination = await source.copy('${images.path}/$fileName');
    return destination;
  }

  Future<String?> saveReference(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final base = '${directory.path}${Platform.pathSeparator}';
    final path = file.path.replaceFirst(base, '');
    return path;
  }

  Future<File?> resolve(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$relativePath',
    );
    return await file.exists() ? file : null;
  }

  Future<void> delete(String? relativePath) async {
    if (relativePath == null) return;
    final file = await resolve(relativePath);
    if (file != null && await file.exists()) await file.delete();
  }
}
