import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────
//  HOME — ASK SCOUT QUICK PROMPTS
//
//  A horizontal scroll of small prompt chips on Home. Tap posts
//  the prompt as a user message into scout_messages and routes
//  to the Scout tab. Scout's realtime stream picks up the message
//  and generates a reply as normal.
//
//  Surfaces Scout's utility before the Scout tab, without
//  duplicating the "daily question" affordance (that one is a
//  single specific question; this is a set of exploratory
//  starters).
// ─────────────────────────────────────────────────────────────

const _prompts = <_Prompt>[
  _Prompt('🗺️', 'long weekend ideas'),
  _Prompt('💸', 'cheap destinations right now'),
  _Prompt('🏖️', 'somewhere warm this month'),
  _Prompt('🌃', 'best night-life cities'),
  _Prompt('🥾', 'underrated european gems'),
  _Prompt('🌱', 'solo-friendly + safe'),
];

class HomeScoutPrompts extends ConsumerStatefulWidget {
  const HomeScoutPrompts({super.key});

  @override
  ConsumerState<HomeScoutPrompts> createState() =>
      _HomeScoutPromptsState();
}

class _HomeScoutPromptsState extends ConsumerState<HomeScoutPrompts> {
  bool _sending = false;

  Future<void> _ask(_Prompt p) async {
    if (_sending) return;
    setState(() => _sending = true);
    TSHaptics.ctaTap();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _sending = false);
      return;
    }
    // Route first so the user sees the Scout tab immediately; the
    // edge function persists both the user message and Scout's
    // reply, which stream into the thread as they land.
    if (context.mounted) context.push('/scout');
    unawaited(ref.read(scoutServiceProvider).ask(p.label).catchError((_) => ''));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TSSpacing.md),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: TSSpacing.md),
          itemCount: _prompts.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('ask scout',
                      style: TSTextStyles.label(
                          color: TSColors.muted, size: 10)),
                ),
              );
            }
            final p = _prompts[i - 1];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _ask(p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: TSColors.s1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: TSColors.purple.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(p.label,
                        style:
                            TSTextStyles.caption(color: TSColors.text)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Prompt {
  final String emoji;
  final String label;
  const _Prompt(this.emoji, this.label);
}
