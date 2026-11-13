import 'dart:typed_data';

import 'engine_settings.dart';
export 'engine_settings.dart';

class ExpandedAuthoring {
  const ExpandedAuthoring(this.xml, this.sourceMap, this.directory);
  final String xml, directory;
  final Map<String, dynamic> sourceMap;
}

class EvidenceImage {
  EvidenceImage(this.path, List<int> bytes)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final String path;
  final Uint8List bytes;
}

class PreparedScenario {
  const PreparedScenario({
    required this.settings,
    required this.inputPath,
    required this.reportRoot,
    required this.plan,
  });
  final EngineSettings settings;
  final String inputPath;
  final String reportRoot;
  final Map<String, dynamic> plan;
}

class EngineUpdate {
  const EngineUpdate({
    this.event,
    this.result,
    this.reportDirectory,
    this.images = const [],
    this.checks = const [],
  });
  final Map<String, dynamic>? event;
  final Map<String, dynamic>? result;
  final String? reportDirectory;
  final List<EvidenceImage> images;
  final List<Map<String, dynamic>> checks;
}

class EngineException implements Exception {
  const EngineException(this.message);
  final String message;
  @override
  String toString() => message;
}

class EngineAuthoringException extends EngineException {
  const EngineAuthoringException(super.message, this.diagnostics);
  final List<Map<String, dynamic>> diagnostics;
}
