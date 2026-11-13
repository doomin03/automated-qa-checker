import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/reference_input.dart';
import '../repositories/reference_repository.dart';
import '../../run_review/models/engine_execution.dart';
import '../../run_review/repositories/engine_repository.dart';

class DesignViewModel extends ChangeNotifier {
  DesignViewModel(this._references, this._engine);
  final ReferenceRepository _references;
  final EngineRepository _engine;
  bool busy = false, _disposed = false;
  String? error, summary;
  Future<String?> attach(
    EngineSettings settings,
    String source,
    ReferenceInput input,
  ) async {
    if (busy || _disposed) return null;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (settings.referenceRoot != input.root) {
        throw const FormatException('실행 설정의 기준 폴더와 입력 폴더를 일치시키세요.');
      }
      final reference = await _references.read(input);
      final prepared = await _engine.validate(settings, source);
      final b = jsonDecode(
        jsonEncode(prepared.plan['blueprint']),
      ) as Map<String, dynamic>;
      final existing = List<Map<String, dynamic>>.from(b['references'] ?? []);
      if (existing.any((r) => r['id'] == input.id)) {
        throw const FormatException('기존 기준 ID를 덮어쓰지 않습니다. 새 버전 ID를 입력하세요.');
      }
      b['target']['profile'] = reference['profile'];
      b['references'] = [...existing, reference];
      final nodes = b['flow']['nodes'] as List;
      final ends = nodes.where((n) => n['type'] == 'end').toList();
      if (ends.length != 1) {
        throw const FormatException(
          '기본 기준 연결은 end 노드가 정확히 하나인 Flow에서 가능합니다. 여러 종료 경로는 XML/블록에서 명시적으로 연결하세요.',
        );
      }
      final end = ends.single;
      final additions = <Map<String, dynamic>>[];
      var index = 0;
      for (final image in reference['images']) {
        additions.add({
          'id': '${input.id}_image${index++}',
          'type': 'assertion',
          'action': 'assertImage',
          'params': {'reference': input.id, 'image': image['id']},
        });
      }
      for (final rule in reference['measurementRules']) {
        additions.add({
          'id': '${input.id}_layout${index++}',
          'type': 'assertion',
          'action': 'assertLayout',
          'params': {'reference': input.id, 'rule': rule['id']},
        });
      }
      final edges = b['flow']['edges'] as List;
      for (final edge in edges) {
        if (edge['to'] == end['id']) edge['to'] = additions.first['id'];
      }
      for (var i = 0; i < additions.length; i++) {
        edges.add({
          'from': additions[i]['id'],
          'to': i + 1 < additions.length ? additions[i + 1]['id'] : end['id'],
        });
      }
      nodes.addAll(additions);
      final xml = await _engine.exportXml(settings, jsonEncode(b));
      if (_disposed) return null;
      summary =
          '${input.id} · ${additions.length}개 검사 · 새 XML 초안 (미실행)\n${jsonEncode(reference)}';
      return xml;
    } catch (e) {
      if (!_disposed) {
        error = e is FormatException
            ? e.message.toString()
            : e is EngineException
            ? e.message
            : '기준 파일을 읽거나 검증할 수 없습니다.';
      }
      return null;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
