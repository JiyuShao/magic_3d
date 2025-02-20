import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:web_app/utils/aliyun_oss.dart';
import 'package:web_app/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> upload(File image) async {
  var apiKey = dotenv.env['TRIPO3D_API_KEY'] ?? '';
  var apiUrl = 'https://api.tripo3d.ai/v2/openapi/upload';
  try {
    // 创建 multipart 请求
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $apiKey';

    // 添加文件
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      image.path,
      filename: p.basename(image.path),
    ));

    // 发送请求
    var response = await request.send();

    // 处理响应
    if (response.statusCode == 200) {
      logger.d('上传成功: $apiUrl  ${response.statusCode}');
      final responseBody = await response.stream.bytesToString();
      // 获取返回的 JSON 数据
      final responseJson = jsonDecode(responseBody);
      logger.d('返回值: $responseJson');
      if (responseJson['code'] == 0) {
        return responseJson['data']['image_token'];
      }
      logger.e('上传失败(Data Response): $apiUrl $responseJson');
    } else {
      logger.e(
          '上传失败(HTTP Response): $apiUrl  ${response.statusCode} ${response.reasonPhrase}');
    }
  } catch (e) {
    logger.e('上传失败(Exception): $apiUrl $e');
  }
  return null;
}

Future<Map<String, dynamic>?> request(String method, String url,
    {Map<String, dynamic>? body}) async {
  final apiKey = dotenv.env['TRIPO3D_API_KEY'] ?? '';
  // 创建请求头
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };
  try {
    dynamic response;
    if (method == 'POST') {
      response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));
    } else if (method == 'GET') {
      response = await http.get(Uri.parse(url), headers: headers);
    }
    if (response.statusCode == 200) {
      logger.d('请求成功: $url ${response.statusCode} ${response.body}');
      var responseJson = jsonDecode(response.body);
      if (responseJson['code'] == 0) {
        return responseJson['data'];
      } else {
        logger.e(
            '请求失败(Data Response): $url ${response.statusCode} ${response.body}');
      }
    } else {
      logger.e(
          '请求失败(HTTP Response): $url ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    logger.e('请求失败(Exception): $url $e');
  }
  return null;
}

Future<Map<String, dynamic>?> startTaskPolling(
    String taskId, Function callback) async {
  while (true) {
    try {
      var taskResult = await fetchTaskStatus(taskId);
      if (taskResult.status == 'pending' || taskResult.status == 'success') {
        logger.i('任务进行中: ${taskResult.data!['progress']}%');
        callback(taskResult.data!['progress']);
      }
      if (taskResult.status == 'success' || taskResult.status == 'error') {
        return taskResult.data;
      }
      await Future.delayed(const Duration(seconds: 5)); // 等待 5 秒
    } catch (e) {
      logger.e('任务状态查询失败：${e.toString()}');
    }
  }
}

class TaskResult {
  final String status;
  final Map<String, dynamic>? data;
  final String message;

  TaskResult({required this.status, required this.data, required this.message});
}

Future<TaskResult> fetchTaskStatus(String taskId) async {
  try {
    var taskResult = await request(
      'GET',
      'https://api.tripo3d.ai/v2/openapi/task/$taskId',
    );
    if (taskResult == null) {
      return TaskResult(
        status: 'error',
        data: {'progress': 100},
        message: '任务状态查询失败',
      );
    }
    if (taskResult['progress'] != 100) {
      return TaskResult(
        status: 'pending',
        data: taskResult,
        message: '任务进行中',
      );
    }
    return TaskResult(
      status: 'success',
      data: taskResult,
      message: '任务完成',
    );
  } catch (e) {
    return TaskResult(
      status: 'error',
      data: null,
      message: '任务状态查询失败',
    );
  }
}

Future<File?> downloadFile(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final file = File('${appDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      logger.i('模型下载完成: ${file.path}');
      return file;
    } else {
      logger.e('下载失败: ${response.statusCode}');
    }
  } catch (e) {
    logger.e('下载文件失败: $e');
  }
  return null;
}

Future<String?> downloadAndUploadToAliyun({
  required String url,
}) async {
  try {
    final file = await downloadFile(url);
    if (file == null) {
      return null;
    }
    // 上传文件到阿里云
    final aliyunOss = AliyunOSS(
      accessKeyId: dotenv.env['OSS_ACCESS_KEY_ID'] ?? '',
      accessKeySecret: dotenv.env['OSS_ACCESS_KEY_SECRET'] ?? '',
      endpoint: dotenv.env['OSS_ENDPOINT'] ?? '',
      bucket: dotenv.env['OSS_BUCKET'] ?? '',
    );
    String dateTime = DateTime.now().microsecondsSinceEpoch.toString();
    String fileName = url.split('?')[0].split('/').last;
    String fileNameHash = md5.convert(utf8.encode(fileName)).toString();
    String fileExtension = fileName.split('.').last;
    String finalUrl = await aliyunOss.uploadFile(
      file,
      "magic-3d/${dateTime}_$fileNameHash.$fileExtension",
    );
    file.delete();
    logger.d('上传文件到阿里云成功: $finalUrl');
    return finalUrl;
  } catch (e) {
    logger.e('上传文件到阿里云失败: $e');
  }
  return null;
}
