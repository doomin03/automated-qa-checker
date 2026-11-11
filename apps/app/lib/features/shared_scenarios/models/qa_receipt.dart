import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable upstream identity; never an execution result or credential.
class QaReceipt {
  QaReceipt({
    required this.projectId,
    required this.qaId,
    required this.origin,
    required this.serverProjectId,
    required this.version,
    required this.receivedAt,
    this.suite,
  });
  final String projectId, qaId, origin, serverProjectId, receivedAt;
  final Map<String, dynamic> version;
  final Map<String, dynamic>? suite;
  String get xml => version['xml'] as String;
  String get hash => version['sha256'] as String;
  String get versionId => version['id'] as String;
  String get label => '${version['packageId']} ${version['version']}';
  bool matches(String source) =>
      sha256.convert(utf8.encode(source)).toString() == hash;
  Map<String, dynamic> toJson() => {
    'format': 1,
    'projectId': projectId,
    'qaId': qaId,
    'origin': origin,
    'serverProjectId': serverProjectId,
    'receivedAt': receivedAt,
    'version': version,
    if (suite != null) 'suite': suite,
  };
  factory QaReceipt.fromJson(Map<String, dynamic> value) {
    if (value['format'] != 1 ||
        value.keys.any(
          (k) => !{
            'format',
            'projectId',
            'qaId',
            'origin',
            'serverProjectId',
            'receivedAt',
            'version',
            'suite',
          }.contains(k),
        )) {
      throw const FormatException('지원하지 않는 수신 출처 형식입니다.');
    }
    for (final k in [
      'projectId',
      'qaId',
      'origin',
      'serverProjectId',
      'receivedAt',
    ]) {
      if (value[k] is! String || (value[k] as String).length > 4096) {
        throw const FormatException('잘못된 수신 출처입니다.');
      }
    }
    final v = Map<String, dynamic>.from(value['version'] as Map);
    for (final k in [
      'id',
      'projectId',
      'packageId',
      'version',
      'sha256',
      'blueprintSnapshotHash',
      'xml',
    ]) {
      if (v[k] is! String) throw FormatException('잘못된 원본 필드: $k');
    }
    if (v['projectId'] != value['serverProjectId'] ||
        sha256.convert(utf8.encode(v['xml'] as String)).toString() !=
            v['sha256']) {
      throw const FormatException('원본 XML 또는 프로젝트가 수신 출처와 다릅니다.');
    }
    return QaReceipt(
      projectId: value['projectId'],
      qaId: value['qaId'],
      origin: value['origin'],
      serverProjectId: value['serverProjectId'],
      version: Map.unmodifiable(v),
      receivedAt: value['receivedAt'],
      suite: value['suite'] == null
          ? null
          : Map.unmodifiable(Map<String, dynamic>.from(value['suite'] as Map)),
    );
  }
}
