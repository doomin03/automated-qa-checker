import 'dart:convert';

import 'package:crypto/crypto.dart';

String blockHash(String value) => sha256.convert(utf8.encode(value)).toString();
Map<String, dynamic> blockCopy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class XmlBlockAsset {
  XmlBlockAsset({
    required this.id,
    required this.name,
    required this.path,
    required this.xml,
    required Map<String, dynamic> blueprint,
  }) : hash = blockHash(xml),
       _blueprint = blockCopy(blueprint);
  final String id, name, path, xml, hash;
  final Map<String, dynamic> _blueprint;
  Map<String, dynamic> get blueprint => blockCopy(_blueprint);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'xml': xml,
    'hash': hash,
  };
}

class XmlBlockInstance {
  const XmlBlockInstance(this.id, this.assetId, this.x, this.y);
  final String id, assetId;
  final double x, y;
  XmlBlockInstance at(double x, double y) =>
      XmlBlockInstance(id, assetId, x, y);
  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'x': x,
    'y': y,
  };
}

class XmlBlockLink {
  const XmlBlockLink(this.from, this.to);
  final String from, to;
  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class XmlBlockCompilation {
  const XmlBlockCompilation(this.blueprint, this.sourceMap);
  final Map<String, dynamic> blueprint;
  final Map<String, Map<String, String>> sourceMap;
}

class BlockDiagnostic implements Exception {
  const BlockDiagnostic(this.message, {this.instanceId, this.assetId});
  final String message;
  final String? instanceId, assetId;
  @override
  String toString() => message;
}
