import 'package:flutter/foundation.dart';

@immutable
class EngineSettings {
  const EngineSettings({
    this.nodePath = '',
    this.cliPath = '',
    this.reportRoot = '',
    this.referenceRoot = '',
    this.appiumConfig = '',
  });
  final String nodePath, cliPath, reportRoot, referenceRoot, appiumConfig;
  EngineSettings get normalized => EngineSettings(
    nodePath: nodePath.trim(),
    cliPath: cliPath.trim(),
    reportRoot: reportRoot.trim(),
    referenceRoot: referenceRoot.trim(),
    appiumConfig: appiumConfig.trim(),
  );
  EngineSettings copyWith({
    String? nodePath,
    String? cliPath,
    String? reportRoot,
    String? referenceRoot,
    String? appiumConfig,
  }) => EngineSettings(
    nodePath: nodePath ?? this.nodePath,
    cliPath: cliPath ?? this.cliPath,
    reportRoot: reportRoot ?? this.reportRoot,
    referenceRoot: referenceRoot ?? this.referenceRoot,
    appiumConfig: appiumConfig ?? this.appiumConfig,
  );
  @override
  bool operator ==(Object other) =>
      other is EngineSettings &&
      nodePath == other.nodePath &&
      cliPath == other.cliPath &&
      reportRoot == other.reportRoot &&
      referenceRoot == other.referenceRoot &&
      appiumConfig == other.appiumConfig;
  @override
  int get hashCode =>
      Object.hash(nodePath, cliPath, reportRoot, referenceRoot, appiumConfig);
}
