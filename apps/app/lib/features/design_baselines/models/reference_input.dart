class ReferenceInput {
  const ReferenceInput({
    required this.root,
    required this.id,
    required this.pngPath,
    required this.measurementsPath,
    required this.profileJson,
    required this.channelTolerance,
    required this.maxDiffRatio,
  });
  final String root, id, pngPath, measurementsPath, profileJson;
  final int channelTolerance;
  final double maxDiffRatio;
}
