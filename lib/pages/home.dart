// ignore_for_file: dead_code

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_app/pages/result.dart';
import 'package:web_app/utils/logger.dart';
import 'package:web_app/utils/request.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('欢迎来到首页'),
          ElevatedButton(
            onPressed: () {
              _showCamera(context);
            },
            child: const Text('点击调起摄像头'),
          ),
        ],
      ),
    );
  }

  void _showCamera(BuildContext context) async {
    Result result;
    if (false) {
      // 选择图片
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        return;
      }
      // 上传图片
      final imageToken = await upload(File(image.path));
      if (imageToken == null) {
        return;
      }
      // 创建任务
      final taskIdResult = await request(
        'POST',
        'https://api.tripo3d.ai/v2/openapi/task',
        body: {
          'type': 'image_to_model',
          'file': {
            'type': 'jpg',
            'file_token': imageToken,
          },
        },
      );

      if (taskIdResult == null) {
        return;
      }
      final taskId = taskIdResult['task_id'];
      // 轮询任务状态
      final taskResult = await startTaskPolling(taskId);
      if (taskResult == null) {
        return;
      }
      logger.i(taskResult);

      // 下载模型
      // final modelUrl = taskResult['model_url'];
      // if (modelUrl == null) {
      //   return;
      // }
      // final modelFile = await download(modelUrl);
      result = Result(
        imagePath: taskResult['output']['rendered_image'],
        modelPath: taskResult['output']['pbr_model'],
      );
    } else {
      result = Result(
        imagePath:
            'https://tripo-data.cdn.bcebos.com/tcli_9eb8f06d07484b65b1be273e91e17f63/20250215/e534e2f0-618d-44d7-afea-a541fdd1d01a/rendered_image.webp?auth_key=1739664000-qaTCDmwd-0-3afea8374cdd656c00c00d48b9d9349b',
        modelPath:
            'https://tripo-data.cdn.bcebos.com/tcli_9eb8f06d07484b65b1be273e91e17f63/20250215/e534e2f0-618d-44d7-afea-a541fdd1d01a/tripo_pbr_model_e534e2f0-618d-44d7-afea-a541fdd1d01a.glb?auth_key=1739664000-qaTCDmwd-0-5e78ed534d85d51df2384865ed2c9e21',
      );
    }

    final finalImagePath = await downloadAndUploadToAliyun(
      url: result.imagePath,
    );
    final finalModelPath = await downloadAndUploadToAliyun(
      url: result.modelPath,
    );
    final finalResult = Result(
      imagePath: finalImagePath ?? '',
      modelPath: finalModelPath ?? '',
    );
    logger.i('上传成功: $finalResult');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          result: finalResult,
        ),
      ),
    );
  }
}
