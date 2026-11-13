import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class CanvasLayoutRepository {
  String path(String root, String identity) =>
      '$root/presentation-v1/${sha256.convert(utf8.encode(identity))}.json';
  Future<Map<String, dynamic>> read(String root, String identity) async {
    final file = File(path(root, identity));
    if (!await file.exists()) return {};
    final bytes = await file.open();
    try {
      final data = await bytes.read(1024 * 1024 + 1);
      if (data.length > 1024 * 1024) {
        throw const FormatException('레이아웃 파일이 너무 큽니다.');
      }
      final value = jsonDecode(utf8.decode(data));
      if (value['version'] != 1 ||
          value['identity'] != identity ||
          value['positions'] is! Map) {
        throw const FormatException('레이아웃 형식이 다릅니다.');
      }
      final positions = Map<String, dynamic>.from(value['positions']);
      for (final p in positions.values) {
        if (p is! Map ||
            p['x'] is! num ||
            p['y'] is! num ||
            !(p['x'] as num).isFinite ||
            !(p['y'] as num).isFinite) {
          throw const FormatException('레이아웃 좌표가 잘못되었습니다.');
        }
      }
      return positions;
    } finally {
      await bytes.close();
    }
  }

  Future<void> write(
    String root,
    String identity,
    Map<String, dynamic> positions,
  ) async {
    final file = File(path(root, identity));
    await file.parent.create(recursive: true);
    final stage = await file.parent.createTemp('.layout-');
    try {
      final temp = File('${stage.path}/layout.json');
      await temp.writeAsString(
        jsonEncode({
          'version': 1,
          'identity': identity,
          'positions': positions,
        }),
        flush: true,
      );
      await temp.rename(file.path);
    } finally {
      await stage.delete(recursive: true);
    }
  }
}
