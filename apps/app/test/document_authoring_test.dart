import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/xml_blocks/models/xml_block_document.dart';
import 'package:automated_qa_desktop/features/xml_blocks/repositories/document_authoring_repository.dart';
import 'package:automated_qa_desktop/features/xml_blocks/repositories/xml_block_repository.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'engine_bridge_test.dart' show IncompleteService;

class MalformedAuthoring extends IncompleteService implements EngineDocumentAuthoring {
  Map<String,dynamic> response={};
  @override Future<Map<String,dynamic>> compose(EngineSettings settings,Map<String,dynamic> input)async=>response;
  @override Future<Map<String,dynamic>> templates(EngineSettings settings)async=>{};
  @override Future<Map<String,dynamic>> createTemplate(EngineSettings settings,String id,String version,String hash,Map<String,dynamic> bindings)async=>{};
}

void main(){
  test('public Engine composes deterministic namespace and rejects invalid graphs without running',()async{
    final receipt=jsonDecode(await File('assets/desktop-installation.json').readAsString());
    final manifest=Map<String,dynamic>.from(jsonDecode(await File('assets/desktop-engine-runtime.json').readAsString()));
    final out=await Directory('../../artifacts/multi-terminal/authoring').absolute.create(recursive:true);
    final service=LocalEngineCliService(loadManifest:()async=>manifest);
    addTearDown(service.dispose);
    final settings=EngineSettings(nodePath:receipt['nodePath'],cliPath:receipt['cliPath'],reportRoot:out.path);
    final blueprint=Map<String,dynamic>.from(jsonDecode(await File('assets/desktop-engine-contract.json').readAsString())['example']);
    final xml=await service.exportXml(settings,jsonEncode(blueprint));
    final asset=XmlBlockAsset(id:'a',name:'same.xml',path:'fixtures/same.xml',xml:xml,blueprint:blueprint);
    final instances=[const XmlBlockInstance('one','a',0,0),const XmlBlockInstance('two','a',300,0)];
    final links=[const XmlBlockLink('one','two')];
    final repository=DocumentAuthoringRepository(service);
    final first=await repository.compose(settings,[asset],instances,links);
    final again=await repository.compose(settings,[asset],instances,links);
    expect(first['xml'],again['xml']);expect(first['blueprintSnapshotHash'],again['blueprintSnapshotHash']);
    final map=first['uiSourceMap'] as Map<String,Map<String,String>>;
    expect(map.values.map((v)=>v['instanceId']).toSet(),{'one','two'});
    expect(map.values.every((v)=>v['sourceHash']==asset.hash&&v['sourceFile']==asset.path),true);
    expect(first['blueprint']['target'],blueprint['target']);
    for(final edges in [<XmlBlockLink>[],[const XmlBlockLink('one','two'),const XmlBlockLink('two','one')]]) {
      await expectLater(repository.compose(settings,[asset],instances,edges),throwsA(isA<EngineAuthoringException>()));
    }
    final different=blockCopy(blueprint);different['target']['id']='other';
    final other=XmlBlockAsset(id:'b',name:'other.xml',path:'other.xml',xml:await service.exportXml(settings,jsonEncode(different)),blueprint:different);
    await expectLater(repository.compose(settings,[asset,other],[instances.first,const XmlBlockInstance('two','b',0,0)],links),throwsA(isA<EngineAuthoringException>()));
    final catalog=await service.templates(settings);
    final empty=(catalog['templates'] as List).firstWhere((t)=>t['id']=='empty');
    final created=await service.createTemplate(settings,empty['id'],empty['version'],empty['sha256'],{'id':'template-qa','target':blueprint['target']});
    expect(created['blueprint']['flow']['nodes'],hasLength(2));expect(created['sourceMap'],isNull);
    await expectLater(service.createTemplate(settings,empty['id'],empty['version'],'0'*64,{'id':'template-qa','target':blueprint['target']}),throwsA(isA<EngineAuthoringException>()));
    final old=LocalEngineCliService(loadManifest:()async=>{...manifest,'documentAuthoring':false});
    await expectLater(old.templates(settings),throwsA(isA<EngineException>().having((e)=>e.message,'message',contains('UNSUPPORTED_CAPABILITY'))));old.dispose();
    await File('${out.path}/composition.xml').writeAsString(first['xml']);
    await File('${out.path}/verification.json').writeAsString(jsonEncode({'engineVersion':manifest['engineVersion'],'snapshot':first['blueprintSnapshotHash'],'flowSnapshot':first['flowSnapshotHash'],'sourceMap':map,'runs':0,'templateSnapshot':created['blueprintSnapshotHash'],'deterministic':true}));
  },timeout:const Timeout(Duration(minutes:2)));

  test('consumer rejects unsupported service and incomplete or wrong original source maps',()async{
    const settings=EngineSettings(nodePath:'node',cliPath:'cli',reportRoot:'report');
    await expectLater(DocumentAuthoringRepository(IncompleteService()).compose(settings,[],[],[]),throwsA(isA<EngineException>()));
    final original={'flow':{'nodes':[{'id':'action','type':'action'}]}};
    final asset=XmlBlockAsset(id:'a',name:'a',path:'a.xml',xml:'fixture',blueprint:original);
    final fake=MalformedAuthoring(),repository=DocumentAuthoringRepository(MalformedAuthoring());
    final response={'blueprintSnapshotHash':'b','flowSnapshotHash':'f','blueprint':{'flow':{'nodes':[{'id':'generated','type':'action'}]}},
      'sourceMap':{'blueprintSnapshotHash':'b','flowSnapshotHash':'f','nodes':{}}};
    fake.response=response;
    final actual=DocumentAuthoringRepository(fake);
    await expectLater(actual.compose(settings,[asset],[const XmlBlockInstance('i','a',0,0)],[]),throwsA(isA<EngineException>()));
    (fake.response['sourceMap'] as Map)['nodes']={'generated':{'assetId':'a','instanceId':'i','sourceHash':asset.hash,'sourceNodeId':'absent'}};
    await expectLater(actual.compose(settings,[asset],[const XmlBlockInstance('i','a',0,0)],[]),throwsA(isA<EngineException>()));
    await expectLater(repository.compose(settings,[],[],[]),throwsA(isA<EngineException>()));
  });

  test('sidecar mode, conflict and corruption retain original bytes',()async{
    final dir=await Directory.systemTemp.createTemp('qa-block-test-');addTearDown(()=>dir.delete(recursive:true));
    final repository=XmlBlockRepository(),data={'mode':'direct','assets':[],'instances':[],'links':[]};
    await repository.write(dir.path,'project/qa',data,0);
    expect((await repository.read(dir.path,'project/qa'))!['mode'],'direct');
    await expectLater(repository.write(dir.path,'project/qa',{...data,'mode':'composition'},0),throwsFormatException);
    final file=File('${dir.path}/xml-blocks-v1/${blockHash('project/qa')}.json');await file.writeAsString('{broken');
    await expectLater(repository.write(dir.path,'project/qa',data,1),throwsFormatException);expect(await file.readAsString(),'{broken');
  });
}
