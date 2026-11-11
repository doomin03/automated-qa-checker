import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/project_home_view_model.dart';
import '../view_models/desktop_workspace_view_model.dart';
import '../../../features/project_workspace/models/workspace.dart';

class ProjectHome extends StatelessWidget {
  const ProjectHome({
    super.key,
    required this.onCreate,
    required this.onOpen,
    required this.onReceived,
  });
  final Future<void> Function(bool project) onCreate;
  final Future<void> Function(String? project, String? qa) onOpen;
  final VoidCallback onReceived;
  @override
  Widget build(BuildContext context) {
    final home = context.watch<ProjectHomeViewModel>();
    final desktop = context.watch<DesktopWorkspaceViewModel>(),
        ws = desktop.workspace;
    final locked = home.busy || desktop.busy || !ws.ready;
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  '홈',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (ws.project != null && home.section == 'projects') ...[
                  const Text('  /  '),
                  Flexible(
                    child: Text(
                      ws.project!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  home.shared.connected
                      ? (home.localMode ? '로컬 테스트 서버' : '서버 연결됨')
                      : '서버 연결 안 됨',
                  style: const TextStyle(color: Color(0xffbbbbbb)),
                ),
                const SizedBox(width: 10),
                TextButton(
                  key: const Key('home-connect'),
                  onPressed: locked ? null : () => _connection(context, home),
                  child: const Text('서버 연결'),
                ),
                if (home.shared.connected)
                  TextButton(
                    onPressed: home.disconnect,
                    child: const Text('연결 해제'),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        if (home.busy) const LinearProgressIndicator(minHeight: 2),
        if (home.error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              home.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 176,
                child: Material(
                  color: const Color(0xff292929),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in [
                          ('projects', '내 프로젝트'),
                          ('available', '서버에서 받기'),
                          ('received', '가져온 QA'),
                        ])
                          ListTile(
                            dense: true,
                            selected: home.section == item.$1,
                            selectedTileColor: const Color(0xff414141),
                            title: Text(item.$2),
                            onTap: locked ? null : () => home.navigate(item.$1),
                          ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '로컬 문서는 서버 연결 없이 사용할 수 있습니다.',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            {
                              'projects': ws.project == null ? '프로젝트' : 'QA 목록',
                              'available': '받을 수 있는 QA',
                              'received': '가져온 QA',
                            }[home.section]!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (home.section == 'projects') ...[
                            if (ws.project != null)
                              TextButton(
                                onPressed: locked
                                    ? null
                                    : () => onOpen(null, null),
                                child: const Text('모든 프로젝트'),
                              ),
                            FilledButton(
                              onPressed: locked
                                  ? null
                                  : () => onCreate(ws.project == null),
                              child: Text(
                                ws.project == null ? '새 프로젝트' : '새 QA',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey('home-search-${home.queryResetRevision}'),
                        initialValue: home.query,
                        onChanged: home.search,
                        decoration: InputDecoration(
                          isDense: true,
                          border: const OutlineInputBorder(),
                          hintText: home.section == 'available'
                              ? '불러온 목록에서 검색'
                              : '이름으로 검색',
                          prefixIcon: const Icon(Icons.search, size: 18),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: home.section == 'available'
                            ? _available(context, home)
                            : home.section == 'received'
                            ? _received(context, home)
                            : _local(context, home),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  home.message.isEmpty
                      ? '프로젝트에서 QA를 열거나 서버에서 게시된 QA를 가져오세요.'
                      : home.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (home.shared.connected)
                const Text('수신 시 실행하지 않음', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty(String text, [Widget? action]) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 12), action],
      ],
    ),
  );
  Widget _local(BuildContext context, ProjectHomeViewModel home) {
    final ws = home.desktop.workspace,
        disabled = home.busy || home.desktop.busy;
    if (ws.project == null) {
      final projects = ws.workspace.projects
          .where((p) => home.matches(p.name))
          .toList();
      if (projects.isEmpty) {
        return _empty(
          ws.workspace.projects.isEmpty
              ? '프로젝트를 만들어 QA 문서를 모아 두세요.'
              : '검색 결과가 없습니다.',
        );
      }
      return ListView(
        children: [
          for (final p in projects)
            ListTile(
              key: Key('home-project-${p.id}'),
              title: Text(p.name),
              subtitle: Text('QA ${p.documents.length}개'),
              trailing: const Text('열기'),
              onTap: disabled ? null : () => onOpen(p.id, null),
            ),
        ],
      );
    }
    final docs = ws.project!.documents
        .where((q) => home.matches(q.name))
        .toList();
    final selected = docs
        .where((q) => q.id == home.selectedLocalQa)
        .firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: docs.isEmpty
              ? _empty(
                  ws.project!.documents.isEmpty
                      ? '아직 QA가 없습니다. 새 QA를 만들거나 서버에서 가져오세요.'
                      : '검색 결과가 없습니다.',
                )
              : ListView(
                  children: [
                    for (final q in docs)
                      _qaRow(home, ws.project!, q, disabled),
                  ],
                ),
        ),
        if (selected != null) ...[
          const VerticalDivider(width: 24),
          SizedBox(
            width: 260,
            child: _localDetail(home, ws.project!, selected, disabled),
          ),
        ],
      ],
    );
  }

  Widget _qaRow(
    ProjectHomeViewModel home,
    QaProject p,
    QaDocument q,
    bool disabled,
  ) {
    final r = home.receipt(p.id, q.id);
    return ListTile(
      key: Key('home-qa-${q.id}'),
      selected: home.selectedLocalQa == q.id,
      selectedTileColor: const Color(0xff414141),
      title: Text(q.name),
      subtitle: Text(
        '${r == null ? '로컬 작성' : r.label}  ·  ${_outcome(q.lastRun?.outcome)}\n${_date(q.updatedAt)}',
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: disabled ? null : () => onOpen(p.id, q.id),
        child: const Text('열기'),
      ),
      onTap: disabled ? null : () => home.chooseLocalQa(q.id),
    );
  }

  Widget _localDetail(
    ProjectHomeViewModel home,
    QaProject p,
    QaDocument q,
    bool disabled,
  ) {
    final r = home.receipt(p.id, q.id);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text('프로젝트  ${p.name}'),
          const SizedBox(height: 8),
          Text('최근 수정  ${_date(q.updatedAt)}'),
          const SizedBox(height: 8),
          Text('최근 실행  ${_outcome(q.lastRun?.outcome)}'),
          const Divider(height: 30),
          if (r != null) ...[
            const Text('받은 원본', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(r.label),
            Text(r.matches(q.source) ? '원본과 같음' : '로컬 수정됨'),
            Text('받은 날짜  ${_date(r.receivedAt)}'),
            if (r.suite != null)
              Text('Suite  ${r.suite!['packageId']} ${r.suite!['version']}'),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('출처 상세'),
              children: [
                SelectableText(
                  '${r.origin}\n서버 프로젝트 ${r.serverProjectId}\n버전 ${r.versionId}\nSHA-256 ${r.hash}',
                ),
              ],
            ),
          ] else
            const Text('이 컴퓨터에서 작성한 QA'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: disabled ? null : () => onOpen(p.id, q.id),
            child: const Text('작업실에서 열기'),
          ),
        ],
      ),
    );
  }

  Widget _received(BuildContext context, ProjectHomeViewModel home) {
    final values = <({QaProject p, QaDocument q})>[];
    for (final p in home.desktop.workspace.workspace.projects) {
      for (final q in p.documents) {
        if (home.receipt(p.id, q.id) != null &&
            home.matches(
              '${p.name} ${q.name} ${home.receipt(p.id, q.id)!.label}',
            )) {
          values.add((p: p, q: q));
        }
      }
    }
    final selected = values
        .where((v) => v.q.id == home.selectedLocalQa)
        .firstOrNull;
    if (values.isEmpty) {
      return _empty(
        '가져온 QA가 없습니다.',
        TextButton(
          onPressed: home.busy ? null : () => home.navigate('available'),
          child: const Text('서버에서 받기'),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final v in values)
                _qaRow(home, v.p, v.q, home.busy || home.desktop.busy),
            ],
          ),
        ),
        if (selected != null) ...[
          const VerticalDivider(width: 24),
          SizedBox(
            width: 260,
            child: _localDetail(
              home,
              selected.p,
              selected.q,
              home.busy || home.desktop.busy,
            ),
          ),
        ],
      ],
    );
  }

  Widget _available(BuildContext context, ProjectHomeViewModel home) {
    final shared = home.shared;
    if (home.projects.isEmpty) {
      return _empty(
        '서버에 연결하면 게시된 QA와 Suite를 볼 수 있습니다.',
        FilledButton(
          onPressed: home.busy ? null : () => _connection(context, home),
          child: const Text('서버 연결'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('home-server-project'),
                initialValue: home.serverProject,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: '서버 프로젝트',
                  border: OutlineInputBorder(),
                ),
                items: home.projects
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p['id'] as String,
                        child: Text(
                          p['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: home.busy
                    ? null
                    : (v) {
                        if (v != null) home.connectProject(v);
                      },
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: home.busy || home.serverProject == null
                  ? null
                  : () => home.connectProject(home.serverProject!),
              child: const Text('새로 고침'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '게시된 공용 QA입니다. 개인 담당 업무 목록과 다릅니다.',
          style: TextStyle(fontSize: 12, color: Color(0xffbbbbbb)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: !shared.connected
              ? _empty('서버 프로젝트를 선택하세요.')
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          const Text(
                            'QA 버전',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (shared.versions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('게시된 QA가 없습니다.'),
                            ),
                          for (final v in shared.versions.where(
                            (v) => home.matches(
                              '${v['title']} ${v['packageId']} ${v['version']}',
                            ),
                          ))
                            ListTile(
                              key: Key('home-version-${v['id']}'),
                              dense: true,
                              selected: shared.preview?['id'] == v['id'],
                              selectedTileColor: const Color(0xff414141),
                              title: Text(
                                (v['title'] ?? v['packageId']) as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('버전 ${v['version']}'),
                              onTap: home.busy
                                  ? null
                                  : () => shared.select(v['id']),
                            ),
                          if (shared.nextCursor != null)
                            TextButton(
                              onPressed: home.busy ? null : shared.more,
                              child: const Text('QA 더 보기'),
                            ),
                          const Divider(height: 24),
                          const Text(
                            'Suite',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (shared.suites.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('게시된 Suite가 없습니다.'),
                            ),
                          for (final s in shared.suites.where(
                            (s) => home.matches(
                              '${s['title']} ${s['packageId']} ${s['version']}',
                            ),
                          ))
                            ListTile(
                              dense: true,
                              title: Text(
                                (s['title'] ?? s['packageId']) as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('버전 ${s['version']}'),
                              selected: shared.selectedSuite?['id'] == s['id'],
                              onTap: home.busy
                                  ? null
                                  : () => shared.selectSuite(s['id']),
                            ),
                          if (shared.suiteCursor != null)
                            TextButton(
                              onPressed: home.busy
                                  ? null
                                  : () => shared.loadSuites(more: true),
                              child: const Text('Suite 더 보기'),
                            ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 24),
                    SizedBox(
                      width: 300,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (shared.selectedSuite != null) ...[
                              Text(
                                'Suite ${shared.selectedSuite!['packageId']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text('버전 ${shared.selectedSuite!['version']}'),
                              TextButton(
                                onPressed: home.busy || shared.suitePinned
                                    ? null
                                    : shared.pinSelectedSuite,
                                child: Text(
                                  shared.suitePinned
                                      ? 'Suite 버전 고정됨'
                                      : 'Suite 버전 고정',
                                ),
                              ),
                              for (final dynamic m
                                  in shared.selectedSuite!['cases'] as List)
                                TextButton(
                                  onPressed: home.busy || !shared.suitePinned
                                      ? null
                                      : () => shared.selectSuiteCase(
                                          Map<String, dynamic>.from(m as Map),
                                        ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('QA ${m['caseId']}'),
                                  ),
                                ),
                              const Text(
                                '선택한 case를 개별 수신합니다. 전체 Suite 실행은 사용자 웹에서 요청하세요.',
                                style: TextStyle(fontSize: 12),
                              ),
                              const Divider(height: 24),
                            ],
                            if (shared.preview == null)
                              const Text('목록에서 QA 버전을 선택하세요.')
                            else ...[
                              Text(
                                (shared.preview!['title'] ??
                                        shared.preview!['packageId'])
                                    as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('고정 버전  ${shared.preview!['version']}'),
                              const SizedBox(height: 10),
                              const Text(
                                '선택한 프로젝트에 새 로컬 QA로 받습니다. 원본은 보존되며 자동 실행하지 않습니다.',
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                key: const Key('home-receive'),
                                onPressed: home.canReceive
                                    ? () => _receive(context, home)
                                    : null,
                                child: const Text('프로젝트로 가져오기'),
                              ),
                              if (home.duplicates.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('이미 가져온 사본'),
                                for (final r in home.duplicates)
                                  TextButton(
                                    onPressed: home.busy
                                        ? null
                                        : () => onOpen(r.projectId, r.qaId),
                                    child: Text(
                                      home.desktop.workspace.workspace.projects
                                          .where((p) => p.id == r.projectId)
                                          .first
                                          .documents
                                          .where((q) => q.id == r.qaId)
                                          .first
                                          .name,
                                    ),
                                  ),
                              ],
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text('원본 XML 보기'),
                                children: [
                                  SelectableText(
                                    shared.preview!['xml'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'Consolas',
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              shared.message,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xffbbbbbb),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _receive(BuildContext context, ProjectHomeViewModel home) async {
    if (home.desktop.workspace.workspace.projects.isEmpty) {
      await onCreate(true);
      if (!context.mounted) return;
    }
    final projects = home.desktop.workspace.workspace.projects;
    if (projects.isEmpty) return;
    String destination = home.desktop.workspace.projectId ?? projects.first.id;
    final name = TextEditingController(
      text:
          (home.shared.preview!['title'] ?? home.shared.preview!['packageId'])
              as String,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(home.duplicates.isEmpty ? '로컬 QA로 가져오기' : '새 사본 받기'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (home.duplicates.isNotEmpty)
                  const Text('기존 사본과 수정 내용은 보존합니다.'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: destination,
                  items: projects
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) set(() => destination = v);
                  },
                  decoration: const InputDecoration(labelText: '받을 프로젝트'),
                ),
                TextField(
                  key: const Key('home-receive-name'),
                  controller: name,
                  decoration: const InputDecoration(labelText: '새 QA 이름'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const Key('home-receive-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('새 QA로 가져오기'),
            ),
          ],
        ),
      ),
    );
    final value = name.text;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    if (confirmed == true &&
        context.mounted &&
        await home.receive(destination, value)) {
      onReceived();
    }
  }

  Future<void> _connection(
    BuildContext context,
    ProjectHomeViewModel home,
  ) async {
    final address = TextEditingController(
          text: home.origin.isEmpty ? 'http://127.0.0.1:4319' : home.origin,
        ),
        token = TextEditingController();
    final mode = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('공유 서버 연결'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('home-server-address'),
                  controller: address,
                  decoration: const InputDecoration(labelText: '서버 주소'),
                ),
                const SizedBox(height: 12),
                const Text('조직 로그인을 마치면 접근 가능한 프로젝트를 선택할 수 있습니다.'),
                if (home.auth.identity != null)
                  Text('현재 로그인: ${home.auth.identity!.userId}'),
                ExpansionTile(
                  title: const Text('개발 연결 설정'),
                  children: [
                    TextField(
                      key: const Key('home-local-token'),
                      controller: token,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: '로컬 테스트 토큰 · 저장하지 않음',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, 'local'),
                      child: const Text('로컬 테스트 연결'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (home.auth.identity != null)
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                home.logout();
              },
              child: const Text('로그아웃'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              c,
              home.auth.identity == null ? 'login' : 'session',
            ),
            child: Text(home.auth.identity == null ? '조직 로그인' : '현재 로그인으로 연결'),
          ),
        ],
      ),
    );
    final server = address.text.trim(), credential = token.text.trim();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    address.dispose();
    token.dispose();
    if (mode != null && context.mounted) {
      await home.discover(
        server,
        token: credential,
        organization: mode == 'login',
      );
    }
  }

  String _date(String value) => value.isEmpty
      ? '아직 저장한 수정 없음'
      : value.replaceFirst('T', ' ').split('.').first.replaceAll('Z', '');
  String _outcome(String? value) =>
      {
        'passed': '통과',
        'failed': '실패',
        'cancelled': '취소',
        'blocked': '진행 불가',
        'infra_error': '실행 환경 오류',
      }[value] ??
      '실행 전';
}
