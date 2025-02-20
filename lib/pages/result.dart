import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:web_app/utils/logger.dart';

part 'result.g.dart';

@JsonSerializable()
class Result {
  final String id;
  final String imagePath;
  final String modelPath;
  String? modelLocalPath;

  Result({
    required this.id,
    required this.imagePath,
    required this.modelPath,
    this.modelLocalPath,
  });

  factory Result.fromJson(Map<String, dynamic> json) => _$ResultFromJson(json);

  Map<String, dynamic> toJson() => _$ResultToJson(this);

  @override
  String toString() {
    return 'Result(id: $id, imagePath: $imagePath, modelPath: $modelPath, modelLocalPath: $modelLocalPath)';
  }
}

class ResultPage extends StatelessWidget {
  final Result result;

  const ResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    logger.i('展示结果: $result');
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型预览'),
      ),
      body: Center(
        child: ModelViewer(
          backgroundColor: const Color(0xFFF5F3FF),
          src: result.modelPath,
          alt: 'A 3D model',
          ar: true,
          autoRotate: true,
          disableZoom: false,
        ),
      ),
    );
  }
}
