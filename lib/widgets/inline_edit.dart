import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/haptics.dart';

// ─────────────────────────────────────────────────────────────
//  TS INLINE EDIT — tap to edit in place
// ─────────────────────────────────────────────────────────────

class TSInlineEdit extends StatefulWidget {
  const TSInlineEdit({
    super.key,
    required this.value,
    required this.label,
    required this.onSave,
    this.enabled = true,
  });

  final String value;
  final String label;
  final ValueChanged<String> onSave;
  final bool enabled;

  @override
  State<TSInlineEdit> createState() => _TSInlineEditState();
}

class _TSInlineEditState extends State<TSInlineEdit> {
  bool _editing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(TSInlineEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_editing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      // Tap outside — cancel
      setState(() {
        _editing = false;
        _controller.text = widget.value;
      });
    }
  }

  void _startEditing() {
    if (!widget.enabled) return;
    TSHaptics.light();
    setState(() {
      _editing = true;
      _controller.text = widget.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _submit() {
    final newValue = _controller.text.trim();
    setState(() => _editing = false);
    if (newValue.isNotEmpty && newValue != widget.value) {
      widget.onSave(newValue);
    } else {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          _editing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: GestureDetector(
        onTap: _startEditing,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.value.isNotEmpty ? widget.value : widget.label,
                style: TSTextStyles.body(
                  size: 15,
                  color: widget.value.isNotEmpty
                      ? TSColors.text
                      : TSColors.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.enabled) ...[
              const SizedBox(width: 6),
              const Text('✏️', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
      secondChild: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: TSTextStyles.body(size: 15),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          hintText: widget.label,
          hintStyle: TSTextStyles.body(color: TSColors.muted, size: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TS PRIVACY TOGGLE — horizontal 3-option selector
// ─────────────────────────────────────────────────────────────

class TSPrivacyToggle extends StatelessWidget {
  const TSPrivacyToggle({
    super.key,
    required this.currentLevel,
    required this.onChanged,
  });

  final String currentLevel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option('🔒', 'private', 'private'),
        const SizedBox(width: 8),
        _option('👥', 'friends', 'friends_only'),
        const SizedBox(width: 8),
        _option('🌍', 'public', 'public'),
      ],
    );
  }

  Widget _option(String icon, String label, String value) {
    final selected = currentLevel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!selected) {
            TSHaptics.selection();
            onChanged(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? TSColors.limeDim(0.12) : TSColors.s2,
            borderRadius: TSRadius.sm,
            border: Border.all(
              color: selected ? TSColors.lime : TSColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TSTextStyles.label(
                  color: selected ? TSColors.lime : TSColors.muted,
                  size: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
