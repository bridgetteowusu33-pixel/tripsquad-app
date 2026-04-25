import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  LINKIFIED TEXT
//
//  Renders chat / DM / Scout content with:
//   - `https://…` URLs → lime, underlined, tap opens in browser.
//   - `@handle` mentions → lime, bold. Optional [onTagTap] fires
//     with the bare handle when tapped. Without it, mentions
//     render visually but stay inert (used in DMs where mentions
//     aren't meaningful).
//
//  Stateful so TapGestureRecognizers can be disposed on rebuild
//  without leaking. One widget, three surfaces.
// ─────────────────────────────────────────────────────────────

class LinkifiedText extends StatefulWidget {
  const LinkifiedText({
    super.key,
    required this.content,
    this.color = TSColors.text,
    this.size = 14,
    this.onTagTap,
  });

  final String content;
  final Color color;
  final double size;
  final void Function(String tag)? onTagTap;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final re = RegExp(
      r'(https?://[^\s<>]+)|@([a-z0-9_]{2,30})',
      caseSensitive: false,
    );
    final spans = <InlineSpan>[];
    final onAccent = widget.color == TSColors.bg
        ? TSColors.bg
        : TSColors.lime;
    int cursor = 0;
    for (final m in re.allMatches(widget.content)) {
      if (m.start > cursor) {
        spans.add(TextSpan(
          text: widget.content.substring(cursor, m.start),
          style: TSTextStyles.body(color: widget.color, size: widget.size),
        ));
      }
      final urlMatch = m.group(1);
      if (urlMatch != null) {
        final tap = TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(urlMatch);
            if (uri == null) return;
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {/* silent */}
          };
        _recognizers.add(tap);
        spans.add(TextSpan(
          text: urlMatch,
          style: TSTextStyles.body(color: widget.color, size: widget.size)
              .copyWith(
                  decoration: TextDecoration.underline,
                  color: onAccent),
          recognizer: tap,
        ));
      } else {
        TapGestureRecognizer? tap;
        if (widget.onTagTap != null) {
          final tag = m.group(2)!;
          tap = TapGestureRecognizer()
            ..onTap = () => widget.onTagTap!(tag);
          _recognizers.add(tap);
        }
        spans.add(TextSpan(
          text: m.group(0),
          style: TSTextStyles.body(color: widget.color, size: widget.size)
              .copyWith(
                  fontWeight: FontWeight.w700,
                  color: onAccent),
          recognizer: tap,
        ));
      }
      cursor = m.end;
    }
    if (cursor < widget.content.length) {
      spans.add(TextSpan(
        text: widget.content.substring(cursor),
        style: TSTextStyles.body(color: widget.color, size: widget.size),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
