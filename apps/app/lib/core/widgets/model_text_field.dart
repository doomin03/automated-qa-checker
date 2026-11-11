import 'package:flutter/material.dart';

/// The model owns text; this widget owns selection, composing and controller.
class ModelTextField extends StatefulWidget {
  const ModelTextField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.decoration,
    this.expands = false,
    super.key,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled, expands;
  final InputDecoration? decoration;
  @override
  State<ModelTextField> createState() => _ModelTextFieldState();
}

class _ModelTextFieldState extends State<ModelTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  @override
  void didUpdateWidget(covariant ModelTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.value) return;
    final offset = _controller.selection.extentOffset.clamp(
      0,
      widget.value.length,
    );
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    enabled: widget.enabled,
    onChanged: widget.onChanged,
    decoration: widget.decoration,
    expands: widget.expands,
    minLines: widget.expands ? null : 1,
    maxLines: widget.expands ? null : 1,
    autocorrect: false,
    enableSuggestions: false,
    textAlignVertical: TextAlignVertical.top,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
