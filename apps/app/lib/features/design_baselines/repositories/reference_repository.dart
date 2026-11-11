import '../models/reference_input.dart';
import '../services/reference_file_service.dart';

class ReferenceRepository {
  ReferenceRepository(this._files);
  final ReferenceFileService _files;
  Future<Map<String, dynamic>> read(ReferenceInput input) => _files.read(input);
}
