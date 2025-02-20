// ignore_for_file: unnecessary_new

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'logger.dart';

class AliyunOSS {
  final String accessKeyId;
  final String accessKeySecret;
  final String endpoint;
  final String bucket;
  final String? cdnDomain;
  final Dio _dio;

  AliyunOSS({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.endpoint,
    required this.bucket,
    this.cdnDomain,
  }) : _dio = Dio();

  /// 上传文件到阿里云OSS
  ///
  /// [file] 要上传的文件
  /// [fileName] 在OSS中保存的文件名
  /// 返回可访问的文件URL
  Future<String> uploadFile(File file, String fileName) async {
    try {
      // 生成Policy
      final policy = _generatePolicy();
      final signature = _calculateSignature(policy);

      // 构建上传表单
      final formData = FormData.fromMap({
        'key': fileName,
        'policy': policy,
        'OSSAccessKeyId': accessKeyId,
        'success_action_status': '200',
        'Signature': signature,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      // 发起上传请求
      final response = await _dio.post(
        'https://$bucket.$endpoint',
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // 允许接收所有非500错误的响应
          },
          headers: {
            'Host': '$bucket.$endpoint',
          },
        ),
      );

      if (response.statusCode == 200) {
        return cdnDomain?.isNotEmpty == true
            ? 'https://$cdnDomain/$fileName'
            : 'https://$bucket.$endpoint/$fileName';
      } else {
        logger.e('Upload response: ${response.data}');
        throw 'Upload failed with status: ${response.statusCode}';
      }
    } catch (e) {
      logger.e('OSS upload error: $e');
      rethrow;
    }
  }

  String _generatePolicy() {
    final expiration = DateTime.now().add(const Duration(hours: 1));
    final policyJson = {
      'expiration': expiration.toUtc().toIso8601String(),
      'conditions': [
        ['eq', '\$bucket', bucket],
        ['starts-with', '\$key', ''],
        ['eq', '\$success_action_status', '200'],
        ['content-length-range', 0, 104857600],
      ]
    };

    return base64.encode(utf8.encode(json.encode(policyJson)));
  }

  String _calculateSignature(String policy) {
    final hmac = Hmac(sha1, utf8.encode(accessKeySecret));
    return base64.encode(hmac.convert(utf8.encode(policy)).bytes);
  }
}
