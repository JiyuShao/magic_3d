// ignore_for_file: dead_code

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_app/pages/result.dart';
import 'package:web_app/utils/compress.dart';
import 'package:web_app/utils/logger.dart';
import 'package:web_app/utils/request.dart';
import 'package:web_app/components/list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Result> _resultList = [];

  @override
  void initState() {
    super.initState();
    // 从本地获取 _resultList
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _resultList = prefs
                .getStringList('resultList')
                ?.map((e) => Result.fromJson(jsonDecode(e)))
                .toList() ??
            [];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Container(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
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
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/logo1.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // 右侧 Logo
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/logo2.png',
                        width: 80,
                        height: 80,
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
                fontSize: 42, // 加大字号
                fontWeight: FontWeight.bold, // 加粗字体
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '上传照片即可一键生成3D模型',
              style: TextStyle(
                wordSpacing: 10,
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
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      // 这里预留放置相机图标的位置
                      child: Image.asset(
                        'assets/camera.png', // 稍后替换为实际的图标路径
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
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
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                  top: 0,
                ),
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
                        logger.i('开始下载模型: ${result.modelPath}');
                        _downloadTaskModel(result);
                      },
                      onDelete: () {
                        setState(() {
                          _resultList.removeAt(index);
                          // 设置 _resultList 到本地
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setStringList(
                                'resultList',
                                _resultList
                                    .map((e) => jsonEncode(e.toJson()))
                                    .toList());
                          });
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCamera(BuildContext context) async {
    Result result;
    if (true) {
      // 选择图片
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        return;
      }

      EasyLoading.show(status: '压缩图片中...');
      final imageFile = File(image.path);
      logger.d("图片压缩前：${imageFile.lengthSync() / 1024} KB");
      final compressedImageFile = await compressImage(imageFile);
      logger.d("压缩图片后：${compressedImageFile.lengthSync() / 1024} KB");

      EasyLoading.show(status: '上传图片中...');
      // 上传图片
      final imageToken = await upload(compressedImageFile);
      if (imageToken == null) {
        EasyLoading.showError('上传图片失败');
        return;
      }
      EasyLoading.show(status: '创建中...');
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
        EasyLoading.showError('创建失败');
        return;
      }
      EasyLoading.show(status: '生成中...');
      final taskId = taskIdResult['task_id'];
      // 轮询任务状态
      final taskResult = await startTaskPolling(taskId, (progress) {
        EasyLoading.show(status: '生成中($progress%)...');
      });
      if (taskResult == null) {
        EasyLoading.showError('生成失败');
        return;
      }
      logger.i("生成结果: $taskResult");

      // 下载模型
      // final modelUrl = taskResult['model_url'];
      // if (modelUrl == null) {
      //   return;
      // }
      // final modelFile = await download(modelUrl);
      result = Result(
        id: taskId,
        imagePath: taskResult['output']['rendered_image'],
        modelPath: taskResult['output']['pbr_model'],
      );
    } else {
      result = Result(
        id: '123',
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
      id: result.id,
      imagePath: finalImagePath ?? '',
      modelPath: finalModelPath ?? '',
    );
    logger.i('上传成功: $finalResult');

    setState(() {
      _resultList.add(finalResult);
      // 设置 _resultList 到本地
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList('resultList',
            _resultList.map((e) => jsonEncode(e.toJson())).toList());
      });
    });

    EasyLoading.dismiss();
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

  void _downloadTaskModel(Result result) async {
    String? filePath;
    if (result.modelLocalPath != null) {
      filePath = result.modelLocalPath;
    } else {
      final file = await downloadFile(result.modelPath);
      if (file == null) {
        return;
      }
      filePath = file.path;
      logger.i('下载模型成功: ${file.path}');
      setState(() {
        // 更新 _resultList 的 modelLocalPath
        _resultList.firstWhere((e) => e.id == result.id).modelLocalPath =
            file.path;
        // 设置 _resultList 到本地
        SharedPreferences.getInstance().then((prefs) {
          prefs.setStringList('resultList',
              _resultList.map((e) => jsonEncode(e.toJson())).toList());
        });
      });
    }

    // 打开文件
    await OpenFile.open(filePath);
  }
}
