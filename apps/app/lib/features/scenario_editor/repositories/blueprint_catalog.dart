import 'dart:convert';

import 'package:flutter/services.dart';

/// Read-only public contract assets; no engine implementation is embedded.
class BlueprintCatalog {
  Future<Map<String,dynamic>?> authoring() async {
    try {return jsonDecode(await rootBundle.loadString('assets/desktop-authoring-contract.json')) as Map<String,dynamic>;}
    catch (_) {return null;}
  }
  Future<Map<String, dynamic>> runtime() async =>
      jsonDecode(await rootBundle.loadString('assets/desktop-engine-runtime.json')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> load() async =>
      jsonDecode(await rootBundle.loadString('assets/desktop-engine-contract.json'))
          as Map<String, dynamic>;
}
