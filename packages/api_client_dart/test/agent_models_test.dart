import 'dart:convert';
import 'dart:io';

import 'package:api_client_dart/platform_client.dart';
import 'package:api_client_dart/health_client.dart' show validateModel;
import 'package:test/test.dart';

void main() {
  test('execution preserves role-redacted nullable operational metadata', () {
    final value = <String, dynamic>{
      'id': 'execution',
      'projectId': 'demo',
      'state': 'recovered',
      'reason': null,
      'leaseId': 'lease',
      'resourceKey': null,
      'fence': null,
      'cleanupState': null,
      'operatorRecovery': null,
      'cancelRequested': false,
      'reportedExecutionStatus': null,
      'evidenceStatus': 'pending',
      'cases': <dynamic>[],
      'caseRuns': <dynamic>[],
      'createdAt': '2026-10-31T00:00:00.000Z',
      'deadlineAt': null,
    };
    validateModel('ExecutionResponse', value);
    final redacted = ExecutionResponse.fromJson(value).toJson();
    for (final key in [
      'resourceKey',
      'fence',
      'cleanupState',
      'operatorRecovery',
    ]) {
      expect(redacted[key], isNull);
    }
    value.addAll({
      'resourceKey': 'slot',
      'fence': 3,
      'cleanupState': 'unknown',
      'operatorRecovery': {
        'id': '99999999-9999-4999-8999-999999999999',
        'confirmedAt': value['createdAt'],
        'priorFence': 3,
        'newFence': 4,
      },
    });
    validateModel('ExecutionResponse', value);
    expect(
      ExecutionResponse.fromJson(value).toJson()['operatorRecovery'],
      value['operatorRecovery'],
    );
  });
  test('nullable referenced operator recovery round-trips null and object', () {
    final fixture = jsonDecode(
      File(
        '../contract/agent-protocol/v0.1.0-draft.1/examples/reconcile-response.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final decision = Map<String, dynamic>.from(
      (fixture['decisions'] as List).first as Map,
    );
    validateModel('AgentReconcileDecisionDto', decision);
    expect(
      AgentReconcileDecisionDto.fromJson(decision).toJson()['operatorRecovery'],
      isNull,
    );
    (decision['lease'] as Map)['state'] = 'recovered';
    decision['directive'] = 'observe';
    decision['operatorRecovery'] = {
      'id': '99999999-9999-4999-8999-999999999999',
      'confirmedAt': '2026-10-31T00:00:00.000Z',
      'priorFence': 1,
      'newFence': 2,
    };
    validateModel('AgentReconcileDecisionDto', decision);
    expect(
      AgentReconcileDecisionDto.fromJson(decision).toJson()['operatorRecovery'],
      decision['operatorRecovery'],
    );
    (decision['operatorRecovery'] as Map)['confirmedAt'] =
        '2026-02-30T00:00:00.000Z';
    expect(
      () => validateModel('AgentReconcileDecisionDto', decision),
      throwsA(isA<ContractFailure>()),
    );
  });
}
