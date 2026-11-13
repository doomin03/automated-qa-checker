# packages/api_client_dart

`package:api_client_dart/platform_client.dart`는 PlatformClient(origin, bearerToken), 생성 DraftInput/DependencyPin/RunInput/ArtifactInput 등 모든 모델과 공통 오류를 공개한다. DTO는 json_serializable 생성자이며 builder/built_collection을 요구하지 않는다. facade 이름은 TS와 동일하고 pagination은 named arguments다. decodeEngineEvents/decodeEngineResult로 opaque JSON을 읽으며 dispose 시 close()가 요청을 취소한다. [서버 실행/권한](../../apps/server/PLATFORM.md), 양 SDK 실제 통합 `node packages/contract/generator/platform-integration.mjs`를 참고한다.

Checker OpenAPI에서 dart-dio + json_serializable로 생성한다. Flutter 앱은 같은 저장소의 path dependency로 소비하며 pnpm workspace에는 포함하지 않는다.

PlatformClient는 TS와 같은 업무 상태/비교/알림, Suite 검수·발행·pin, execution 생성·조회·취소·복구, schedule 생성·enabled·occurrences 메서드를 제공한다. `organization_client.dart`의 OrganizationClient는 getSession/logout/desktopExchange/loginUrl로 Desktop PKCE 로그인을 연결한다. operational metadata는 권한이 없으면 null이며 QA outcome과 별도로 표시한다. path parameter는 고정 생성 template에서 Uri.encodeComponent를 한 번 적용하므로 호출자가 미리 encoding하지 않는다.

```dart
import 'package:api_client_dart/health_client.dart';
final client = HealthClient('http://127.0.0.1:4319');
final response = await client.getHealth(client: 'app');
print(response.status.value);
client.close();
```

`lib/src`와 `lib/api_client_dart.dart`, pubspec/build 설정은 [생성 파이프라인](../contract/generator/README.md)이 관리한다. 직접 수정하지 않는다. 수작업 경계는 health/platform/organization facade이며 생성 schema를 검사하고 ApiFailure(status/body), TransportFailure(reason), ContractFailure로 실패를 구분한다. endpoint나 wire model을 다시 정의하지 않는다. nullable required client는 생략할 수 없고 null은 허용한다.

이 디렉터리에서 고정 Dart3.13.4로 `pub get --enforce-lockfile`, `analyze`, `test`를 실행한다. pubspec.lock을 보존한다. production API origin의 HTTPS 정책과 UI 상태/dispose는 Flutter composition/repository의 책임이다.

