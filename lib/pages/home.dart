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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(imagePath: image.path),
      ),
    );
  }
}
