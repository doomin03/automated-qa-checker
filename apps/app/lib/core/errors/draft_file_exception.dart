class DraftFileException implements Exception {
  const DraftFileException(this.message);
  final String message;
  @override
  String toString() => message;
}
