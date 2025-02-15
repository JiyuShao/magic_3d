// ignore_for_file: dead_code

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_app/pages/result.dart';
import 'package:web_app/utils/logger.dart';
import 'package:web_app/utils/request.dart';

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
  void initState() async {
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
        const Text('欢迎来到 Magic 3D'),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              _showCamera(context);
            },
            child: const Text('上传图片'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _resultList.length,
            itemBuilder: (context, index) {
              final result = _resultList[index];
              return ListTile(
                leading: Image.network(
                  result.imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text('图片 ${index + 1}'),
                subtitle: Text('上传时间: ${DateTime.now().toString()}'),
                onTap: () => _openResultPage(context, _resultList[index]),
              );
            },
          ),
        )
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
