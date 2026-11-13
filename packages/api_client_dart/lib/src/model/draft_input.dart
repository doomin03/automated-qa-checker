//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/dependency_pin.dart';
import 'package:json_annotation/json_annotation.dart';

part 'draft_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DraftInput {
  /// Returns a new [DraftInput] instance.
  DraftInput({
    required this.dependencies,

    required this.packageId,

    required this.title,

    required this.xml,
  });

  @JsonKey(name: r'dependencies', required: true, includeIfNull: false)
  final List<DependencyPin> dependencies;

  @JsonKey(name: r'packageId', required: true, includeIfNull: false)
  final String packageId;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  /// Opaque Engine Blueprint XML. Validation does not execute it.
  @JsonKey(name: r'xml', required: true, includeIfNull: false)
  final String xml;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftInput &&
          other.dependencies == dependencies &&
          other.packageId == packageId &&
          other.title == title &&
          other.xml == xml;

  @override
  int get hashCode =>
      dependencies.hashCode +
      packageId.hashCode +
      title.hashCode +
      xml.hashCode;

  factory DraftInput.fromJson(Map<String, dynamic> json) =>
      _$DraftInputFromJson(json);

  Map<String, dynamic> toJson() => _$DraftInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
