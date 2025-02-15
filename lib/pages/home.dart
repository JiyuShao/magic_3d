// ignore_for_file: dead_code

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_app/pages/result.dart';
import 'package:web_app/utils/logger.dart';
import 'package:web_app/utils/request.dart';
import 'package:web_app/components/list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> gridItems = [
    {
      'title': '苹果设计指南',
      'subtitle': '了解更多 iOS 设计规范和最佳实践',
      'imageUrl': 'https://picsum.photos/seed/1/400/300', // 示例图片URL
    },
    {
      'title': '材料设计 3.0',
      'subtitle': '探索 Google Material Design 的最新更新',
      'imageUrl': 'https://picsum.photos/seed/2/400/300',
    },
    {
      'title': 'Flutter UI',
      'subtitle': 'Flutter 界面设计精选',
      'imageUrl': 'https://picsum.photos/seed/3/400/300',
    },
    {
      'title': '交互设计',
      'subtitle': '优秀的交互设计案例',
      'imageUrl': 'https://picsum.photos/seed/4/400/300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text('欢迎来到首页'),
          ElevatedButton(
            onPressed: () {
              _showCamera(context);
            },
            child: const Text('点击调起摄像头'),
          ),

          // 网格布局
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 每行两个
                  crossAxisSpacing: 16, // 水平间距
                  mainAxisSpacing: 16, // 垂直间距
                  childAspectRatio: 0.8, // 控制卡片宽高比
                ),
                itemCount: gridItems.length,
                itemBuilder: (context, index) {
                  final item = gridItems[index];
                  return CardGridItem(
                    title: item['title']!,
                    subtitle: item['subtitle'],
                    imageUrl: item['imageUrl']!,
                    onViewPressed: () {
                      print('查看按钮被点击: ${item['title']}');
                    },
                  );
                },
              ),
            ),
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
