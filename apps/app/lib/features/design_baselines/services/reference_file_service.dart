import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../models/reference_input.dart';

/// Reads explicit local resources; execution schema and image comparison belong to Engine.
class ReferenceFileService {
  Future<List<int>> _read(String root, String relative, int limit) async {
    if (!Directory(root).isAbsolute ||
        relative.isEmpty ||
        relative.contains(':') ||
        relative.startsWith('/') ||
        relative.startsWith('\\') ||
        relative
            .split(RegExp(r'[/\\]'))
            .any((part) => part.isEmpty || part == '..')) {
      throw const FormatException('기준 파일은 지정한 절대 폴더 안의 상대 경로여야 합니다.');
    }
    final resolvedRoot = await Directory(root).resolveSymbolicLinks();
    final file = File('$resolvedRoot/$relative');
    final resolvedFile = await file.resolveSymbolicLinks();
    if (!resolvedFile.toLowerCase().startsWith(
      '${resolvedRoot.toLowerCase()}${Platform.pathSeparator}',
    )) {
      throw const FormatException('기준 파일이 폴더 밖을 가리킵니다.');
    }
    final handle = await file.open();
    try {
      final bytes = await handle.read(limit + 1);
      if (bytes.length > limit) {
        throw const FormatException('기준 파일 크기 제한을 초과했습니다.');
      }
      return bytes;
    } finally {
      await handle.close();
    }
  }

  Future<Map<String, dynamic>> read(ReferenceInput input) async {
    if (input.pngPath.isEmpty && input.measurementsPath.isEmpty) {
      throw const FormatException('PNG 또는 명시 수치 JSON을 선택하세요.');
    }
    final profile = jsonDecode(input.profileJson);
    if (profile is! Map<String, dynamic>) {
      throw const FormatException('Profile은 JSON 객체여야 합니다.');
    }
    final images = <Map<String, dynamic>>[];
    if (input.pngPath.isNotEmpty) {
      final bytes = await _read(input.root, input.pngPath, 10 * 1024 * 1024);
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length < 8 ||
          List.generate(8, (i) => bytes[i] == signature[i]).contains(false)) {
        throw const FormatException('PNG 서명이 아닙니다.');
      }
      images.add({
        'id': 'baseline',
        'path': input.pngPath,
        'sha256': sha256.convert(bytes).toString(),
        'region': 'viewport',
        'threshold': {
          'channelTolerance': input.channelTolerance,
          'maxDiffRatio': input.maxDiffRatio,
        },
      });
    }
    final rules = <Map<String, dynamic>>[];
    if (input.measurementsPath.isNotEmpty) {
      final bytes = await _read(
        input.root,
        input.measurementsPath,
        1024 * 1024,
      );
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! List || value.isEmpty || value.length > 128) {
        throw const FormatException('수치 JSON은 1~128개 규칙 배열이어야 합니다.');
      }
      for (final rule in value) {
        if (rule is! Map<String, dynamic> || rule.containsKey('source')) {
          throw const FormatException(
            '수치 규칙 객체만 입력하세요. source hash는 선택 파일에서 기록합니다.',
          );
        }
        rules.add({
          ...rule,
          'source': {
            'document': input.measurementsPath,
            'sha256': sha256.convert(bytes).toString(),
          },
        });
      }
    }
    return {
      'schemaVersion': 'qa.designReference/v1',
      'id': input.id,
      'profile': profile,
      'images': images,
      'measurementRules': rules,
    };
  }
}
