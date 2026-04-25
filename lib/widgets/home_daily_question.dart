import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import 'scout_greeting.dart';

// ─────────────────────────────────────────────────────────────
//  HOME DAILY QUESTION
//
//  Scout asks one question a day — "if you could leave tomorrow,
//  where?" — rendered as a small card on Home. Tap jumps to the
//  Scout tab. Answered state persists per-calendar-day in
//  SharedPreferences so the card hides once engaged.
//
//  Builds daily-habit return behaviour. Stays quiet if the user
//  already answered today.
// ─────────────────────────────────────────────────────────────

class HomeDailyQuestion extends ConsumerStatefulWidget {
  const HomeDailyQuestion({super.key});

  @override
  ConsumerState<HomeDailyQuestion> createState() =>
      _HomeDailyQuestionState();
}

class _HomeDailyQuestionState extends ConsumerState<HomeDailyQuestion> {
  bool _answeredToday = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Dismissal rule: card hides only after the user has replied to
    // Scout *after* we posted today's question. Prior user messages
    // (from earlier in the day, before the question existed) don't
    // count. If the question hasn't been tapped yet today, the card
    // always shows.
    final prefs = await SharedPreferences.getInstance();
    final postedAtStr = prefs.getString('scout_daily_posted_at');
    if (postedAtStr == null) {
      if (mounted) setState(() => _checked = true);
      return;
    }
    final postedAt = DateTime.tryParse(postedAtStr);
    if (postedAt == null) {
      if (mounted) setState(() => _checked = true);
      return;
    }
    final today = _todayKey();
    final postedDay = '${postedAt.year}-'
        '${postedAt.month.toString().padLeft(2, '0')}-'
        '${postedAt.day.toString().padLeft(2, '0')}';
    if (postedDay != today) {
      if (mounted) setState(() => _checked = true);
      return;
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _checked = true);
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('scout_messages')
          .select('id')
          .eq('user_id', uid)
          .eq('role', 'user')
          .gte('created_at', postedAt.toUtc().toIso8601String())
          .limit(1);
      if (!mounted) return;
      setState(() {
        _answeredToday = (rows as List).isNotEmpty;
        _checked = true;
      });
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox();
    if (_answeredToday) return const SizedBox();

    final question = scoutDailyQuestion();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TSSpacing.md, 8, TSSpacing.md, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          TSHaptics.ctaTap();
          final prefs = await SharedPreferences.getInstance();
          final today = _todayKey();
          final existing = prefs.getString('scout_daily_posted_at');
          final existingDt = existing == null
              ? null
              : DateTime.tryParse(existing);
          final existingDay = existingDt == null
              ? null
              : '${existingDt.year}-'
                  '${existingDt.month.toString().padLeft(2, '0')}-'
                  '${existingDt.day.toString().padLeft(2, '0')}';
          final alreadyPostedToday = existingDay == today;

          if (!alreadyPostedToday) {
            final uid = Supabase.instance.client.auth.currentUser?.id;
            if (uid != null) {
              try {
                await Supabase.instance.client
                    .from('scout_messages')
                    .insert({
                  'user_id': uid,
                  'role': 'assistant',
                  'content': question,
                });
                await prefs.setString(
                    'scout_daily_posted_at',
                    DateTime.now().toIso8601String());
              } catch (_) {
                // Non-fatal — Scout tab still opens.
              }
            }
          }

          if (!context.mounted) return;
          context.push('/scout');
        },
        child: Container(
          decoration: BoxDecoration(
            color: TSColors.s1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TSColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full-height Scout brand stripe — purple → lime.
                Container(
                  width: 3,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.horizontal(right: Radius.circular(2)),
                    gradient: LinearGradient(
                      colors: [TSColors.purple, TSColors.lime],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('SCOUT · TODAY',
                              style: TSTextStyles.label(
                                  color: TSColors.lime, size: 10)),
                          const Spacer(),
                          Text('answer →',
                              style: TSTextStyles.title(
                                  size: 12, color: TSColors.lime)),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          question,
                          style: TSTextStyles.body(
                              size: 15, color: TSColors.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
