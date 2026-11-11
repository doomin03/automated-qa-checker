import 'dart:convert';

import 'package:flutter/services.dart';

/// Read-only public contract assets; no engine implementation is embedded.
class BlueprintCatalog {
  Future<Map<String, dynamic>> load() async =>
      jsonDecode(await rootBundle.loadString('assets/desktop-engine-contract.json'))
          as Map<String, dynamic>;
}
