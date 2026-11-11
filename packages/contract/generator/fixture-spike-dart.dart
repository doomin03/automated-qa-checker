import 'dart:io';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:api_client_dart/health_client.dart';
import 'package:dio/dio.dart';

void check(bool ok, String label) { if (!ok) throw StateError(label); }
Future<void> main() async {
  final dio=Dio(BaseOptions(baseUrl:Platform.environment['QA_TEST_ORIGIN']!));
  dio.interceptors.add(InterceptorsWrapper(onResponse:(response,handler){try { if(response.statusCode==201)validateModel('FixtureBody',response.data);handler.next(response); } catch(error) { handler.reject(DioException(requestOptions:response.requestOptions,response:response,error:error)); }}));
  final api=FixtureApi(dio);
  final value=<String,dynamic>{'label':null,'choice':'two','count':9007199254740991,'measurement':0.125,'largeId':'18446744073709551616','utc':'2026-10-31T12:34:56.123Z','values':<String>['한글','x/y','%?']};
  validateModel('FixtureBody',value);final body=FixtureBody.fromJson(value);
  check(body.toJson().containsKey('label')&&body.toJson()['label']==null,'required null');check(!body.toJson().containsKey('optional'),'optional omitted');
  final result=(await api.fixtureRoundTrip(id:'plain',enabled:false,fixtureBody:body)).data!;
  check(result.label==null&&result.choice==FixtureBodyChoiceEnum.two&&result.count==9007199254740991&&result.measurement==0.125&&result.largeId==value['largeId']&&result.utc.toIso8601String()==value['utc']&&result.values.join('|')==(value['values'] as List<String>).join('|'),'all scalar/date/list fields');
  const path='segment / 한글 %?';check((await api.fixtureRoundTrip(id:path,enabled:true,fixtureBody:body)).data!.optional==path,'path encoded exactly once');
  check((await api.fixtureRoundTrip(id:'unknown-addition',enabled:false,fixtureBody:body)).data!.largeId==body.largeId,'unknown addition');
  for(final invalid in <Map<String,dynamic>>[{...value,'choice':'future'},{...value,'utc':'2026-02-30T12:34:56.123Z'},{...value,'count':9007199254740992},{...value}..remove('label')]){bool rejected=false;try{validateModel('FixtureBody',invalid);}on ContractFailure{rejected=true;}check(rejected,'strict generated schema guard');}
  for(final query in ['enabled=true&enabled=false','enabled=invalid']){try{await dio.post<Object>('/api/v1/__fixture/plain?$query',data:value);throw StateError('Expected400');}on DioException catch(error){check(error.response?.statusCode==400,'HTTP400 status');validateModel('ApiErrorResponse',error.response!.data);check(ApiErrorResponse.fromJson(Map<String,dynamic>.from(error.response!.data as Map)).code=='VALIDATION_ERROR','common error');}}
  try{await api.fixtureFailure();throw StateError('Expected500');}on DioException catch(error){check(error.response?.statusCode==500,'HTTP500 status');validateModel('ApiErrorResponse',error.response!.data);final parsed=ApiErrorResponse.fromJson(Map<String,dynamic>.from(error.response!.data as Map));check(parsed.code=='INTERNAL_ERROR'&&!parsed.message.contains('private-secret-stack'),'sanitized error');}
  dio.close(force:true);print('Dart expanded fixture SDK actual HTTP PASS');
}
