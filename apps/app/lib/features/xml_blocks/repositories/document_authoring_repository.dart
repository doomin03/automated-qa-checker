import '../../run_review/services/engine_cli_service.dart';
import '../../run_review/models/engine_execution.dart';
import '../models/xml_block_document.dart';

/// Maps app identities/paths to the public Engine authoring contract.
/// All graph assembly and execution semantics belong to Engine.
class DocumentAuthoringRepository {
  DocumentAuthoringRepository(this.engine);
  final EngineCliService engine;
  EngineDocumentAuthoring get api {
    final value = engine;
    if (value is EngineDocumentAuthoring) return value as EngineDocumentAuthoring;
    throw const EngineException('UNSUPPORTED_CAPABILITY: 공개 문서 작성 API가 필요합니다.');
  }

  Future<Map<String, dynamic>> compose(EngineSettings settings,
      List<XmlBlockAsset> assets, List<XmlBlockInstance> instances,
      List<XmlBlockLink> links) async {
    final authored = await api.compose(settings, {
      'schemaVersion': 'qa.composition/v1',
      'assets': [for (final asset in assets) {
        'id': asset.id, 'format': asset.xml.trimLeft().startsWith('<') ? 'xml' : 'json',
        'source': asset.xml, 'sha256': asset.hash,
      }],
      'instances': [for (final instance in instances) {'id':instance.id,'assetId':instance.assetId}],
      'links': links.map((link) => link.toJson()).toList(),
    });
    final map = authored['sourceMap'];
    if (map is! Map || map['nodes'] is! Map ||
        map['blueprintSnapshotHash'] != authored['blueprintSnapshotHash'] ||
        map['flowSnapshotHash'] != authored['flowSnapshotHash']) {
      throw const EngineException('합성 sourceMap과 문서 snapshot이 다릅니다.');
    }
    final byAsset = {for(final asset in assets) asset.id:asset};
    final byInstance = {for(final instance in instances) instance.id:instance};
    final nodes = (authored['blueprint']['flow']['nodes'] as List).map((n)=>n['id']).toSet();
    final mappedNodes = (authored['blueprint']['flow']['nodes'] as List)
        .where((n)=>n['type']!='start'&&n['type']!='end').map((n)=>n['id']).toSet();
    final suppliedNodes = (map['nodes'] as Map).keys.toSet();
    if(mappedNodes.length!=suppliedNodes.length||!mappedNodes.containsAll(suppliedNodes)) {
      throw const EngineException('합성 노드의 원본 매핑이 누락되거나 추가되었습니다.');
    }
    final uiMap = <String, Map<String,String>>{};
    for(final entry in (map['nodes'] as Map).entries) {
      final value = entry.value;
      if(value is! Map || entry.key is! String || !nodes.contains(entry.key)) throw const EngineException('잘못된 원본 블록 매핑');
      final asset = byAsset[value['assetId']], instance = byInstance[value['instanceId']];
      if(asset==null || instance==null || instance.assetId!=asset.id || value['sourceHash']!=asset.hash || value['sourceNodeId'] is! String) {
        throw const EngineException('원본 asset/instance/hash 매핑이 다릅니다.');
      }
      if(!(asset.blueprint['flow']['nodes'] as List).any((node)=>node['id']==value['sourceNodeId']&&node['type']!='start'&&node['type']!='end')) {
        throw const EngineException('원본에 없는 노드 매핑입니다.');
      }
      uiMap[entry.key as String] = {
        'assetId':asset.id,'instanceId':instance.id,'sourceNodeId':value['sourceNodeId'],
        'sourceHash':asset.hash,'sourceFile':asset.path,
      };
    }
    return {...authored,'uiSourceMap':uiMap};
  }
}
