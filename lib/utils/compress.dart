import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

Future<File> compressImage(File imageFile) async {
  final Uint8List bytes = await imageFile.readAsBytes();
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: 1024,
    minHeight: 1024,
    quality: 95,
  );

  final appDir = await getApplicationDocumentsDirectory();

  final file = File('${appDir.path}/${generateRandomFileName("")}}');
  await file.writeAsBytes(result);
  return file;
}

String generateRandomFileName(String extension) {
  String dateTimeString = DateTime.now().millisecondsSinceEpoch.toString();
  String randomString = _generateRandomString(10);
  return '${dateTimeString}_$randomString$extension';
}

String _generateRandomString(int length) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random rnd = Random();
  return String.fromCharCodes(Iterable.generate(
    length,
    (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
  ));
}
