import 'dart:convert';
import 'dart:io';

/// Test runtime follows the app asset/receipt; production server pins are untouched.
String desktopPackageRoot(String repository) => (jsonDecode(File('$repository/apps/app/assets/desktop-installation.json').readAsStringSync()) as Map)['packageRoot'] as String;
