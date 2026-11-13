import 'dart:math' as math;

import 'package:flutter/material.dart';

/// UI constraints only. Document, process and execution lifetimes stay in Provider.
double workbenchLineHeight(BuildContext context, [double base = 34]) =>
    math.max(base, MediaQuery.textScalerOf(context).scale(14) + 20);

class WorkbenchDialogBody extends StatelessWidget {
  const WorkbenchDialogBody({
    required this.child,
    this.width = 760,
    this.height = 560,
    super.key,
  });
  final Widget child;
  final double width, height;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: math.min(width, math.max(120, size.width - 96)),
      height: math.min(height, math.max(120, size.height - 180)),
      child: child,
    );
  }
}

/// Keeps both panes mounted when compact so focus and scroll positions survive.
class WorkbenchMasterDetail extends StatefulWidget {
  const WorkbenchMasterDetail({
    required this.primary,
    this.detail,
    this.detailWidth = 280,
    this.detailLabel = '선택 상세',
    super.key,
  });
  final Widget primary;
  final Widget? detail;
  final double detailWidth;
  final String detailLabel;
  @override
  State<WorkbenchMasterDetail> createState() => _WorkbenchMasterDetailState();
}

class _WorkbenchMasterDetailState extends State<WorkbenchMasterDetail> {
  bool detail = false;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final compact = c.maxWidth < 720 * math.min(scale, 1.3);
      return Column(
        children: [
          if (compact && widget.detail != null)
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => detail = false),
                  child: const Text('목록'),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('compact-detail'),
                      onPressed: () => setState(() => detail = true),
                      child: Text(
                        widget.detailLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: !compact && widget.detail != null
                      ? widget.detailWidth + 16
                      : 0,
                  child: ExcludeFocus(
                    excluding: compact && detail && widget.detail != null,
                    child: Offstage(
                      offstage: compact && detail && widget.detail != null,
                      child: widget.primary,
                    ),
                  ),
                ),
                if (widget.detail != null)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: compact ? c.maxWidth : widget.detailWidth,
                    child: ExcludeFocus(
                      excluding: compact && !detail,
                      child: Offstage(
                        offstage: compact && !detail,
                        child: widget.detail!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
