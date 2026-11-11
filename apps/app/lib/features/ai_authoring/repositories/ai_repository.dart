import 'dart:io';

import '../models/ai_request.dart';
import '../services/ai_cli_service.dart';

class AiRepository {
  AiRepository(this.service);
  final AiCliService service;
  Future<String> diagnose(AiSettings settings) => service.diagnose(settings);
  Future<AiAnswer> generate(
    AiSettings settings,
    Directory sessions,
    String prompt,
    void Function(String) progress,
  ) => service.generate(settings, sessions, prompt, progress);
  Future<void> cancel() => service.cancel();
}
