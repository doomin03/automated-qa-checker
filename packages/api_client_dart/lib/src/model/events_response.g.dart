// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventsResponse _$EventsResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EventsResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'attempt',
          'engineRunId',
          'eventsJson',
          'hasMore',
          'nextSequence',
          'runId',
          'snapshotHash',
          'terminal',
        ],
      );
      final val = EventsResponse(
        attempt: $checkedConvert('attempt', (v) => (v as num).toInt()),
        engineRunId: $checkedConvert('engineRunId', (v) => v as String),
        eventsJson: $checkedConvert(
          'eventsJson',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        hasMore: $checkedConvert('hasMore', (v) => v as bool),
        nextSequence: $checkedConvert(
          'nextSequence',
          (v) => (v as num).toInt(),
        ),
        runId: $checkedConvert('runId', (v) => v as String),
        snapshotHash: $checkedConvert('snapshotHash', (v) => v as String),
        terminal: $checkedConvert('terminal', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$EventsResponseToJson(EventsResponse instance) =>
    <String, dynamic>{
      'attempt': instance.attempt,
      'engineRunId': instance.engineRunId,
      'eventsJson': instance.eventsJson,
      'hasMore': instance.hasMore,
      'nextSequence': instance.nextSequence,
      'runId': instance.runId,
      'snapshotHash': instance.snapshotHash,
      'terminal': instance.terminal,
    };
