// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Result _$ResultFromJson(Map<String, dynamic> json) => Result(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      modelPath: json['modelPath'] as String,
      modelLocalPath: json['modelLocalPath'] as String?,
    );

Map<String, dynamic> _$ResultToJson(Result instance) => <String, dynamic>{
      'id': instance.id,
      'imagePath': instance.imagePath,
      'modelPath': instance.modelPath,
      'modelLocalPath': instance.modelLocalPath,
    };
