// ignore_for_file: dead_code

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // ignore: prefer_final_fields
  List<Result> _resultList = [
    Result(
      imagePath:
          'https://tripo-data.cdn.bcebos.com/tcli_9eb8f06d07484b65b1be273e91e17f63/20250215/e534e2f0-618d-44d7-afea-a541fdd1d01a/rendered_image.webp?auth_key=1739664000-qaTCDmwd-0-3afea8374cdd656c00c00d48b9d9349b',
      modelPath:
          'https://tripo-data.cdn.bcebos.com/tcli_9eb8f06d07484b65b1be273e91e17f63/20250215/e534e2f0-618d-44d7-afea-a541fdd1d01a/tripo_pbr_model_e534e2f0-618d-44d7-afea-a541fdd1d01a.glb?auth_key=1739664000-qaTCDmwd-0-5e78ed534d85d51df2384865ed2c9e21',
    )
  ];

  @override
  void initState() {
    super.initState();
    // 从本地获取 _resultList
    // final prefs = await SharedPreferences.getInstance();
    // _resultList = prefs
    //         .getStringList('resultList')
    //         ?.map((e) => Result.fromJson(e))
    //         .toList() ??
    //     [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo 容器
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 左侧 Logo
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo1.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // 右侧 Logo
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo2.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ), // 添加20px的间距
        const Text(
          'Magic 3D',
          style: TextStyle(
            fontSize: 48, // 加大字号
            fontWeight: FontWeight.bold, // 加粗字体
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '上传照片即可一键生成3D模型',
          style: TextStyle(
            wordSpacing: 5,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCamera(context),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  // 这里预留放置相机图标的位置
                  child: Image.asset(
                    'assets/camera_icon.png', // 稍后替换为实际的图标路径
                    width: 64,
                    height: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '我的模型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
              itemCount: _resultList.length,
              itemBuilder: (context, index) {
                final result = _resultList[index];
                return CardGridItem(
                  imageUrl: result.imagePath,
                  onImageTap: () => _openResultPage(context, result),
                  onDownload: () async {
                    // 处理下载逻辑
                    logger.i('开始下载模型: ${result.modelPath}');
                    try {
                      final response =
                          await http.get(Uri.parse(result.modelPath));
                      if (response.statusCode == 200) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName = result.modelPath.split('/').last;
                        final file = File('${appDir.path}/$fileName');
                        await file.writeAsBytes(response.bodyBytes);
                        logger.i('模型下载完成: ${file.path}');
                        OpenFile.open(file.path);
                      } else {
                        logger.e('下载失败: ${response.statusCode}');
                      }
                    } catch (e) {
                      logger.e('下载出错: $e');
                    }
                  },
                  onDelete: () {
                    // 处理删除逻辑
                    setState(() {
                      _resultList.removeAt(index);
                    });
                    // 这里可以添加持久化存储的逻辑
                  },
                );
              },
            ),
          ),
        ),
      ],
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
    // setState(() async {
    //   _resultList.add(finalResult);
    //   // 设置 _resultList 到本地
    //   final prefs = await SharedPreferences.getInstance();
    //   prefs.setStringList(
    //       'resultList', _resultList.map((e) => e.toJson()).toList());
    // });

    // ignore: use_build_context_synchronously
    _openResultPage(context, finalResult);
  }

  void _openResultPage(BuildContext context, Result result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          result: result,
        ),
      ),
    );
  }
}
