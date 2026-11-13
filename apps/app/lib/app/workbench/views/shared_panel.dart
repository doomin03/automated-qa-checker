import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/shared_scenarios/view_models/shared_view_model.dart';
import '../view_models/workbench_view_model.dart';
import '../../../features/organization_login/view_models/organization_view_model.dart';

class SharedPanel extends StatefulWidget {
  const SharedPanel({this.openReceivedHome, super.key});
  final VoidCallback? openReceivedHome;
  @override
  State<SharedPanel> createState() => _SharedPanelState();
}

class _SharedPanelState extends State<SharedPanel> {
  final _origin = TextEditingController(text: 'http://127.0.0.1:4319');
  final _token = TextEditingController();
  final _project = TextEditingController();
  final _folder = TextEditingController();
  final _report = TextEditingController();
  @override
  void dispose() {
    for (final c in [_origin, _token, _project, _folder, _report]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<SharedViewModel>(
    builder: (context, vm, _) => ExpansionTile(
      title: const Text('공용 XML · 서버 진행 공유 (선택)'),
      children: [
        TextField(
          key: const Key('shared-origin'),
          controller: _origin,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: '공유 서버 주소'),
        ),
        Consumer<OrganizationViewModel>(
          builder: (context, auth, _) => Column(
            children: [
              Wrap(
                children: [
                  TextButton(
                    onPressed: auth.busy || vm.busy
                        ? null
                        : () {
                            context.read<WorkbenchViewModel>().login(
                              _origin.text.trim(),
                            );
                          },
                    child: const Text('브라우저에서 조직 로그인'),
                  ),
                  if (auth.busy)
                    TextButton(
                      onPressed: auth.cancel,
                      child: const Text('로그인 취소'),
                    ),
                  if (auth.identity != null) ...[
                    TextButton(
                      onPressed: auth.busy
                          ? null
                          : () {
                              _token.clear();
                              context.read<WorkbenchViewModel>().logout();
                            },
                      child: const Text('조직 로그아웃'),
                    ),
                    for (final project in auth.identity!.projects)
                      TextButton(
                        onPressed: () {
                          _project.text = project.id;
                        },
                        child: Text('프로젝트 ${project.name}'),
                      ),
                  ],
                ],
              ),
              Text(auth.message),
            ],
          ),
        ),
        TextField(
          key: const Key('shared-token'),
          controller: _token,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: '로컬 테스트 사용자 token (메모리에만 보관)',
          ),
        ),
        TextField(
          key: const Key('shared-project'),
          controller: _project,
          decoration: const InputDecoration(labelText: '프로젝트 ID'),
        ),
        TextField(
          key: const Key('shared-cache'),
          controller: _folder,
          decoration: const InputDecoration(labelText: '고정 XML 캐시 절대 폴더'),
        ),
        Wrap(
          children: [
            TextButton(
              onPressed:
                  vm.busy ||
                      (context.watch<OrganizationViewModel>().identity !=
                              null &&
                          context.watch<OrganizationViewModel>().origin !=
                              _origin.text.trim())
                  ? null
                  : () => context.read<WorkbenchViewModel>().connectShared(
                      _origin.text.trim(),
                      _token.text.trim(),
                      _project.text.trim(),
                      _folder.text.trim(),
                    ),
              child: const Text('공유 연결'),
            ),
            TextButton(
              onPressed: vm.busy
                  ? null
                  : widget.openReceivedHome ??
                        () => context.read<WorkbenchViewModel>().openOffline(
                          _folder.text.trim(),
                          _origin.text.trim(),
                          _project.text.trim(),
                        ),
              child: Text(
                widget.openReceivedHome == null
                    ? '오프라인 고정 XML 열기'
                    : '홈에서 가져온 QA 열기',
              ),
            ),
          ],
        ),
        Text(vm.message, key: const Key('shared-message')),
        ExpansionTile(
          title: const Text('공용 Suite · 개별 case 수신'),
          children: [
            TextButton(
              onPressed: vm.busy || !vm.connected
                  ? null
                  : () => vm.loadSuites(),
              child: const Text('Suite 목록 가져오기'),
            ),
            for (final suite in vm.suites)
              TextButton(
                onPressed: vm.busy ? null : () => vm.selectSuite(suite['id']),
                child: Text(
                  'Suite ${suite['packageId']} · ${suite['version']}',
                ),
              ),
            if (vm.suiteCursor != null)
              TextButton(
                onPressed: vm.busy ? null : () => vm.loadSuites(more: true),
                child: const Text('Suite 다음 페이지'),
              ),
            if (vm.selectedSuite != null) ...[
              SelectableText(
                'Suite ${vm.selectedSuite!['version']} · ${vm.selectedSuite!['sha256']} · stopOnFailure=${vm.selectedSuite!['stopOnFailure']}',
              ),
              TextButton(
                onPressed: vm.busy || !vm.connected
                    ? null
                    : vm.pinSelectedSuite,
                child: const Text('선택 Suite 버전 고정 (실행 안 함)'),
              ),
              for (final member in vm.selectedSuite!['cases'] as List)
                TextButton(
                  onPressed: vm.busy || !vm.suitePinned
                      ? null
                      : () => vm.selectSuiteCase(
                          Map<String, dynamic>.from(member as Map),
                        ),
                  child: Text(
                    'Suite case ${member['caseId']} · ${member['versionId']}',
                  ),
                ),
            ],
            const Text(
              'Desktop은 선택한 case를 개별 수신·검증·실행합니다. 전체 Suite 순차 실행은 웹의 Agent 실행 요청을 사용합니다.',
            ),
          ],
        ),
        if (vm.receivedVersion != null)
          Text(
            '원본 출처: ${vm.receivedVersion!['packageId']} ${vm.receivedVersion!['version']} · ${vm.receivedVersionMatchesPlan ? '검증 snapshot 일치: 실행에 version ID 연결' : '미검증 또는 편집 snapshot: 실행 version ID 연결 안 함'}',
          ),
        for (final v in vm.versions)
          TextButton(
            onPressed: vm.busy ? null : () => vm.select(v['id']),
            child: Text('${v['packageId']} · ${v['version']} · ${v['sha256']}'),
          ),
        if (vm.nextCursor != null)
          TextButton(
            onPressed: vm.busy ? null : vm.more,
            child: const Text('버전 더 보기'),
          ),
        if (vm.diff != null) SelectableText(vm.diff!),
        if (vm.preview != null) ...[
          SelectableText('선택 XML: ${vm.preview!['xml']}'),
          TextButton(
            onPressed: vm.busy || !vm.connected
                ? null
                : widget.openReceivedHome ??
                      context.read<WorkbenchViewModel>().receive,
            child: Text(
              widget.openReceivedHome == null
                  ? '이 버전 고정·초안으로 수신 (실행 안 함)'
                  : '홈에서 새 QA로 받기',
            ),
          ),
        ],
        CheckboxListTile(
          value: vm.autoPublish,
          onChanged: vm.canPublish
              ? (v) => vm.enablePublishing(v ?? false)
              : null,
          title: const Text('현재·다음 로컬 실행의 진행/결과를 이 프로젝트에 게시'),
        ),
        if (vm.incompatibility != null) Text(vm.incompatibility!),
        if (vm.projectContext != null)
          Text(
            '프로젝트 역할: ${vm.projectContext!.role.value} · 서버 ${vm.projectContext!.engine.engineVersion} / ${vm.projectContext!.engine.contractVersion}',
          ),
        SelectableText(
          vm.publishStatus,
          key: const Key('shared-publish-status'),
        ),
        TextField(
          controller: _report,
          decoration: const InputDecoration(
            labelText: '재시작 후 재게시할 실제 run 폴더 절대 경로',
          ),
        ),
        TextButton(
          onPressed: vm.canPublish && !vm.busy
              ? () => vm.restoreReport(_report.text.trim())
              : null,
          child: const Text('저장된 결과에서 게시 복구'),
        ),
        TextButton(
          onPressed: vm.canPublish ? vm.retry : null,
          child: const Text('게시 재시도'),
        ),
        const Text(
          '서버 연결 실패는 로컬 실행 결과를 바꾸지 않습니다. evidence verified는 자료의 hash·정합성 확인이며 외부 실행 신뢰나 실기기 검증 보증이 아닙니다. 업무 상태 편집·예약은 후속입니다.',
        ),
      ],
    ),
  );
}
