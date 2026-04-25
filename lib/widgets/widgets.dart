import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  TS BUTTON  (primary / outline / ghost variants)
// ─────────────────────────────────────────────────────────────
enum TSButtonVariant { primary, outline, ghost, danger, ai }

class TSButton extends StatelessWidget {
  const TSButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = TSButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.small   = false,
    this.expand  = true,
  });

  final String label;
  final VoidCallback? onTap;
  final TSButtonVariant variant;
  final String? icon;
  final bool loading;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final h = small ? 42.0 : 52.0;
    final fs = small ? 12.0 : 14.0;

    Color bg, fg, border;
    switch (variant) {
      case TSButtonVariant.primary:
        bg = TSColors.lime; fg = TSColors.bg; border = Colors.transparent;
      case TSButtonVariant.outline:
        bg = Colors.transparent; fg = TSColors.muted2; border = TSColors.border2;
      case TSButtonVariant.ghost:
        bg = TSColors.s2; fg = TSColors.text2; border = TSColors.border;
      case TSButtonVariant.danger:
        bg = TSColors.coral; fg = Colors.white; border = Colors.transparent;
      case TSButtonVariant.ai:
        bg = TSColors.purpleDim(0.18); fg = TSColors.purple; border = TSColors.purpleDim(0.35);
    }

    return SizedBox(
      width: expand ? double.infinity : null,
      height: h,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: TSRadius.md,
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
          child: loading
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Text(icon!, style: TextStyle(fontSize: fs + 2)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TSTextStyles.title(color: fg, size: fs),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TS CARD
// ─────────────────────────────────────────────────────────────
class TSCard extends StatelessWidget {
  const TSCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.radius,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: padding ?? const EdgeInsets.all(TSSpacing.md),
        decoration: BoxDecoration(
          color: color ?? TSColors.s2,
          borderRadius: radius ?? TSRadius.md,
          border: Border.all(color: borderColor ?? TSColors.border),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TS PILL / CHIP
// ─────────────────────────────────────────────────────────────
enum TSPillVariant { lime, coral, blue, purple, gold, teal, muted }

class TSPill extends StatelessWidget {
  const TSPill(this.label, {super.key, this.variant = TSPillVariant.lime, this.small = false});

  final String label;
  final TSPillVariant variant;
  final bool small;

  @override
  Widget build(BuildContext context) {
    Color bg, text, border;
    switch (variant) {
      case TSPillVariant.lime:
        bg = TSColors.limeDim(0.12); text = TSColors.lime; border = TSColors.limeDim(0.30);
      case TSPillVariant.coral:
        bg = TSColors.coralDim(0.12); text = TSColors.coral; border = TSColors.coralDim(0.28);
      case TSPillVariant.blue:
        bg = TSColors.blueDim(0.12); text = TSColors.blue; border = TSColors.blueDim(0.28);
      case TSPillVariant.purple:
        bg = TSColors.purpleDim(0.12); text = TSColors.purple; border = TSColors.purpleDim(0.28);
      case TSPillVariant.gold:
        bg = TSColors.goldDim(0.12); text = TSColors.gold; border = TSColors.goldDim(0.28);
      case TSPillVariant.teal:
        bg = TSColors.tealDim(0.12); text = TSColors.teal; border = TSColors.tealDim(0.28);
      case TSPillVariant.muted:
        bg = TSColors.s3; text = TSColors.muted2; border = TSColors.border;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical:   small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: TSRadius.full,
        border: Border.all(color: border),
      ),
      child: Text(label, style: TSTextStyles.label(color: text, size: small ? 9 : 10)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TS TEXT FIELD
// ─────────────────────────────────────────────────────────────
class TSTextField extends StatelessWidget {
  const TSTextField({
    super.key,
    this.hint,
    this.label,
    this.controller,
    this.onChanged,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.prefixIcon,
    this.focusNode,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final String? hint;
  final String? label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool autofocus;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TSTextStyles.label()),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: autofocus,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TSTextStyles.body(color: TSColors.text, size: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
          ),
          cursorColor: TSColors.lime,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.action, this.actionLabel});
  final String label;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: TSTextStyles.label()),
          if (action != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: action,
              child: Text(
                actionLabel ?? 'See all',
                style: TSTextStyles.label(color: TSColors.lime),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SQUAD AVATAR ROW
// ─────────────────────────────────────────────────────────────
class SquadAvatarRow extends StatelessWidget {
  const SquadAvatarRow({
    super.key,
    required this.emojis,
    this.photoUrls,
    this.maxShow = 5,
  });
  final List<String> emojis;

  /// Optional — same length as [emojis]. When a slot has a non-null url,
  /// the circle renders the photo; otherwise the emoji is shown.
  final List<String?>? photoUrls;
  final int maxShow;

  @override
  Widget build(BuildContext context) {
    final shownEmojis = emojis.take(maxShow).toList();
    final shownPhotos = photoUrls
        ?.take(maxShow)
        .toList() ??
        List<String?>.filled(shownEmojis.length, null);
    final remaining = emojis.length - shownEmojis.length;
    final all = <Widget>[
      for (int i = 0; i < shownEmojis.length; i++)
        _Avatar(
          emoji: shownEmojis[i],
          photoUrl: i < shownPhotos.length ? shownPhotos[i] : null,
        ),
      if (remaining > 0) _Avatar(label: '+$remaining'),
    ];
    const overlap = 8.0;
    final totalWidth = all.length * 28.0 - (all.length - 1) * overlap;
    return SizedBox(
      width: totalWidth.clamp(0, double.infinity),
      height: 28,
      child: Stack(
        children: all.asMap().entries.map((e) => Positioned(
          left: e.key * (28.0 - overlap),
          child: e.value,
        )).toList(),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.emoji, this.photoUrl, this.label});
  final String? emoji;
  final String? photoUrl;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: TSColors.s3,
          shape: BoxShape.circle,
          border: Border.all(color: TSColors.bg, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: TSColors.s2),
          errorWidget: (_, __, ___) => Container(
            color: TSColors.s2,
            alignment: Alignment.center,
            child: Text(emoji ?? '😎',
                style: const TextStyle(fontSize: 14)),
          ),
        ),
      );
    }
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: TSColors.s3,
        shape: BoxShape.circle,
        border: Border.all(color: TSColors.bg, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji ?? label ?? '?',
        style: TextStyle(fontSize: emoji != null ? 14 : 9),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROGRESS BAR
// ─────────────────────────────────────────────────────────────
class TSProgressBar extends StatelessWidget {
  const TSProgressBar({super.key, required this.progress, this.color});
  final double progress; // 0.0 to 1.0
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: TSRadius.full,
      child: Stack(children: [
        Container(height: 4, color: TSColors.s3),
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: color ?? TSColors.lime,
              borderRadius: TSRadius.full,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LIVE BADGE
// ─────────────────────────────────────────────────────────────
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1200.ms)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: TSColors.lime.withOpacity(0.4 + _ctrl.value * 0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text('LIVE', style: TSTextStyles.label(color: TSColors.lime, size: 9)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  LOADING OVERLAY
// ─────────────────────────────────────────────────────────────
class TSLoadingOverlay extends StatelessWidget {
  const TSLoadingOverlay({super.key, required this.child, this.loading = false});
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (loading) Container(
        color: TSColors.bg.withOpacity(0.7),
        child: const Center(
          child: CircularProgressIndicator(color: TSColors.lime),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  SCOUT LOADING — rotating Gen-Z messages while Scout thinks
// ─────────────────────────────────────────────────────────────
/// Full-card loading state with a bouncing 🧭 and a rotating set of
/// fun messages. Use when the wait is 5–30s (AI generation). Pass
/// your own messages or use the defaults.
class TSScoutLoading extends StatefulWidget {
  const TSScoutLoading({
    super.key,
    this.messages,
    this.subtitle = 'this takes a few seconds',
    this.accent = TSColors.lime,
  });

  final List<String>? messages;
  final String subtitle;
  final Color accent;

  static const itineraryMessages = [
    'scout is cooking... 🔥',
    'talking to the locals...',
    'scouting hidden gems...',
    'checking your vibe...',
    'mapping your days...',
    'finding the good stuff...',
    'remixing your options...',
    'LETS GOOO 🚀',
  ];

  static const packingMessages = [
    'scout is packing... 🎒',
    'checking the forecast...',
    'remembering the essentials...',
    'no way you\'re forgetting this...',
    'packing light, packing smart...',
    'almost set...',
  ];

  static const destinationMessages = [
    'scout is thinking... 🧭',
    'looking up vibes...',
    'finding the best fit...',
    'checking the seasons...',
    'mixing it up...',
  ];

  @override
  State<TSScoutLoading> createState() => _TSScoutLoadingState();
}

class _TSScoutLoadingState extends State<TSScoutLoading>
    with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _shimmer;
  Timer? _rotator;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _rotator = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      final msgs = widget.messages ?? TSScoutLoading.itineraryMessages;
      setState(() => _idx = (_idx + 1) % msgs.length);
    });
  }

  @override
  void dispose() {
    _bounce.dispose();
    _shimmer.dispose();
    _rotator?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.messages ?? TSScoutLoading.itineraryMessages;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Bouncing compass
          AnimatedBuilder(
            animation: _bounce,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -6 * _bounce.value),
              child: const Text('🧭', style: TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 16),
          // Rotating message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              msgs[_idx % msgs.length],
              key: ValueKey(_idx),
              style: TSTextStyles.heading(size: 18, color: widget.accent),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Text(widget.subtitle,
              style: TSTextStyles.caption(color: TSColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Shimmer bar
          SizedBox(
            width: 140,
            height: 3,
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (_, __) {
                return Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      color: TSColors.s2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: (-40) + _shimmer.value * 180,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          widget.accent.withValues(alpha: 0),
                          widget.accent,
                          widget.accent.withValues(alpha: 0),
                        ]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  APP BAR HELPER
// ─────────────────────────────────────────────────────────────
/// Circular avatar that shows a photo when available, otherwise the
/// emoji fallback. Use sensible sizes (28 for row avatars, 72 for
/// headers). Keep emoji-only in tiny contexts — avatars read well
/// at ≥ 40pt but emoji reads better below that.
class TSAvatar extends StatelessWidget {
  const TSAvatar({
    super.key,
    required this.emoji,
    this.photoUrl,
    this.size = 40,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String emoji;
  final String? photoUrl;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final inner = _inner();
    if (ringColor != null && ringWidth > 0) {
      return Container(
        width: size + ringWidth * 2,
        height: size + ringWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: ringWidth),
        ),
        alignment: Alignment.center,
        child: inner,
      );
    }
    return inner;
  }

  Widget _inner() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _emojiFallback(),
          errorWidget: (_, __, ___) => _emojiFallback(),
        ),
      );
    }
    return _emojiFallback();
  }

  Widget _emojiFallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: TSColors.s1,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.55),
      ),
    );
  }
}

class TSAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TSAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = true,
    this.trailing,
    this.showBorder = true,
    this.onTitleLongPress,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final bool showBorder;
  /// Optional long-press handler on the title. Used by Trip Space
  /// to let the host rename the trip without adding extra chrome.
  final VoidCallback? onTitleLongPress;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      height: preferredSize.height + topPadding,
      padding: EdgeInsets.fromLTRB(TSSpacing.md, topPadding, TSSpacing.md, 0),
      decoration: BoxDecoration(
        color: TSColors.bg,
        border: showBorder
            ? const Border(bottom: BorderSide(color: TSColors.border))
            : null,
      ),
      child: Row(children: [
        if (showBack)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Dismiss any focused input + pop in one gesture so the
              // user doesn't have to tap twice (first to close keyboard,
              // second to pop).
              FocusManager.instance.primaryFocus?.unfocus();
              // Pop if we can. If the user reached this screen via
              // `context.go(...)` (stack-replacing), there's nothing to
              // pop — fall back to /home so the chevron always does
              // something visible.
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
              } else {
                GoRouter.of(context).go('/home');
              }
            },
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: TSColors.text2, size: 18),
              ),
            ),
          )
        else
          const SizedBox(width: 44),
        const Spacer(),
        if (title != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTitleLongPress,
            onLongPress: onTitleLongPress,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(title!, style: TSTextStyles.title()),
                    if (onTitleLongPress != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded,
                          color: TSColors.muted, size: 13),
                    ],
                  ]),
                  if (subtitle != null)
                    Text(subtitle!, style: TSTextStyles.caption()),
                ]),
          ),
        const Spacer(),
        trailing ?? const SizedBox(width: 44),
      ]),
    );
  }
}
