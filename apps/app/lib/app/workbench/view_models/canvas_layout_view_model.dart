import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../features/scenario_editor/repositories/canvas_layout_repository.dart';
import 'desktop_workspace_view_model.dart';

class CanvasLayoutViewModel extends ChangeNotifier {
  CanvasLayoutViewModel(this.desktop, this.repository) {
    desktop.addListener(_changed);
  }
  final DesktopWorkspaceViewModel desktop;
  final CanvasLayoutRepository repository;
  Map<String, dynamic> positions = {};
  String? _identity, error;
  int _generation = 0;
  bool _disposed = false;
  bool _loading = false, _loadValid = true;
  Future<void> _writes = Future.value();
  final List<Map<String, dynamic>> _undo = [];
  void _changed() {
    final id = '${desktop.workspace.projectId}/${desktop.workspace.qaId}';
    if (id == _identity) return;
    _identity = id;
    positions = {};
    _loading = true;
    _loadValid = true;
    _undo.clear();
    final ticket = ++_generation;
    unawaited(() async {
      try {
        final loaded = await repository.read(
          desktop.workspace.repository.directory,
          id,
        );
        if (!_disposed && ticket == _generation) {
          final pending = positions;
          positions = {...loaded, ...pending};
          _undo.clear();
          _loading = false;
          if (pending.isNotEmpty) _save();
          error = null;
          notifyListeners();
        }
      } catch (e) {
        if (!_disposed && ticket == _generation) {
          _loading = false;
          _loadValid = false;
          error = '$e';
          notifyListeners();
        }
      }
    }());
  }

  Offset position(Map<String, dynamic> blueprint, String id, int index) {
    final p =
        positions[id] ??
        blueprint['flow']['metadata']?['presentation']?['positions']?[id];
    if (p is Map && p['x'] is num && p['y'] is num) {
      return Offset(
        (p['x'] as num).toDouble().clamp(0, 1000000),
        (p['y'] as num).toDouble().clamp(0, 1000000),
      );
    }
    return Offset(60 + (index % 3) * 280.0, 60 + (index ~/ 3) * 170.0);
  }

  void move(String id, Offset point) {
    _undo.add(jsonDecode(jsonEncode(positions)));
    if (_undo.length > 50) _undo.removeAt(0);
    positions = {
      ...positions,
      id: {'x': point.dx.clamp(0, 1000000), 'y': point.dy.clamp(0, 1000000)},
    };
    _save();
    notifyListeners();
  }

  bool get canUndo => !_loading && _undo.isNotEmpty;
  void undo() {
    if (canUndo) {
      positions = _undo.removeLast();
      _save();
      notifyListeners();
    }
  }

  void _save() {
    if (_loading || !_loadValid) return;
    final identity = _identity, root = desktop.workspace.repository.directory;
    final saved = jsonDecode(jsonEncode(positions)) as Map<String, dynamic>;
    if (identity == null) return;
    _writes = _writes
        .then((_) => repository.write(root, identity, saved))
        .catchError((Object e) {
          if (!_disposed) {
            error = '$e';
            notifyListeners();
          }
        });
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    desktop.removeListener(_changed);
    super.dispose();
  }
}
