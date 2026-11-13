import 'package:file_selector/file_selector.dart';

abstract interface class ScenarioFilePicker {
  Future<String?> choose({bool allowJson = false});
}

class NativeScenarioFilePicker implements ScenarioFilePicker {
  @override
  Future<String?> choose({bool allowJson = false}) async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: allowJson ? 'QA XML / JSON' : 'QA XML',
          extensions: allowJson ? ['xml', 'json'] : ['xml'],
        ),
      ],
    );
    return file?.path;
  }
}
