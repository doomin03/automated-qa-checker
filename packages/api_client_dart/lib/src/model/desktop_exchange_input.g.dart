// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_exchange_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesktopExchangeInput _$DesktopExchangeInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DesktopExchangeInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code', 'redirectUri', 'verifier']);
  final val = DesktopExchangeInput(
    code: $checkedConvert('code', (v) => v as String),
    redirectUri: $checkedConvert('redirectUri', (v) => v as String),
    verifier: $checkedConvert('verifier', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DesktopExchangeInputToJson(
  DesktopExchangeInput instance,
) => <String, dynamic>{
  'code': instance.code,
  'redirectUri': instance.redirectUri,
  'verifier': instance.verifier,
};
