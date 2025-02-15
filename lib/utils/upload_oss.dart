import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadOss {
  static String ossAccessKeyId = dotenv.env['OSS_ACCESS_KEY_ID'] ?? '';
  static String ossAccessKeySecret = dotenv.env['OSS_ACCESS_KEY_SECRET'] ?? '';
  static String bucket = dotenv.env['OSS_BUCKET'] ?? '';
  static String region = dotenv.env['OSS_REGION'] ?? '';
  static String url = 'http://$bucket.$region.aliyuncs.com';
  static String expiration = DateTime.now() // 获取当前时间
      .add(const Duration(days: 365 * 2)) // 设置为当前时间后的两年
      .toIso8601String() // 转换为 ISO 8601 格式
      .replaceFirst('Z', '.000Z');

  static Future<String> upload(File file,
      {String rootDir = 'moment', String? fileType}) async {
    String policyText =
        '{"expiration": "$expiration","conditions": [{"bucket": "$bucket" },["content-length-range", 0, 1048576000]]}';
    String signature = getSignature(policyText);

    Dio dio = Dio();
    String pathName =
        '$rootDir/${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}/${getRandom(12)}.${fileType ?? getFileType(file.path)}';

    FormData formData = FormData.fromMap({
      'key': pathName,
      'policy': getSplicyBase64(policyText),
      'OSSAccessKeyId': ossAccessKeyId,
      'success_action_status': '200',
      'signature': signature,
      'contentType': 'multipart/form-data',
      'file': await MultipartFile.fromFile(file.path),
    });

    await dio.post(url, data: formData);
    return '$url/$pathName';
  }

  static String getRandom(int num) {
    String alphabet = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM';
    String left = '';
    for (var i = 0; i < num; i++) {
      left += alphabet[Random().nextInt(alphabet.length)];
    }
    return left;
  }

  static String getFileType(String path) {
    List<String> array = path.split('.');
    return array[array.length - 1];
  }

  static String getSplicyBase64(String policyText) {
    List<int> policyTextUtf8 = utf8.encode(policyText);
    return base64.encode(policyTextUtf8);
  }

  static String getSignature(String policyText) {
    List<int> policyTextUtf8 = utf8.encode(policyText);
    String policyBase64 = base64.encode(policyTextUtf8);
    List<int> policy = utf8.encode(policyBase64);
    List<int> key = utf8.encode(ossAccessKeySecret);
    List<int> signaturePre = Hmac(sha1, key).convert(policy).bytes;
    return base64.encode(signaturePre);
  }
}
