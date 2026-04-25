import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/haptics.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  SAVED SCOUT TIPS — per-device bookmark list
//
//  Long-press or tap the bookmark icon on a Scout reply to save
//  it. Opens via the "🔖 saved" pill in the Scout tab header.
//  Tap an entry → copy to clipboard. Long-press → remove.
//
//  Storage: SharedPreferences key `saved_scout_tips` = JSON list
//  of `{content, savedAt}`. Deduped by exact content match so
//  toggling is natural.
// ─────────────────────────────────────────────────────────────

class SavedTip {
  const SavedTip({required this.content, required this.savedAt});
  final String content;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'content': content,
        'savedAt': savedAt.toIso8601String(),
      };

  static SavedTip? fromJson(Map<String, dynamic> j) {
    final c = j['content'] as String?;
    final s = DateTime.tryParse((j['savedAt'] as String?) ?? '');
    if (c == null || s == null) return null;
    return SavedTip(content: c, savedAt: s);
  }
}

const _prefsKey = 'saved_scout_tips';

final savedScoutTipsProvider =
    FutureProvider<List<SavedTip>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  if (raw == null || raw.isEmpty) return const [];
  try {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SavedTip.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .whereType<SavedTip>()
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  } catch (_) {
    return const [];
  }
});

Future<void> _persist(List<SavedTip> tips) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      _prefsKey, jsonEncode(tips.map((t) => t.toJson()).toList()));
}

/// Add or remove a tip. Returns the new saved state (true if now
/// saved, false if removed). Invalidate [savedScoutTipsProvider]
/// on the caller side to refresh dependents.
Future<bool> toggleSavedTip(WidgetRef ref, String content) async {
  final current = (await ref.read(savedScoutTipsProvider.future));
  final idx = current.indexWhere((t) => t.content == content);
  final next = List<SavedTip>.from(current);
  final willSave = idx < 0;
  if (willSave) {
    next.add(SavedTip(content: content, savedAt: DateTime.now()));
  } else {
    next.removeAt(idx);
  }
  await _persist(next);
  ref.invalidate(savedScoutTipsProvider);
  return willSave;
}

Future<void> removeSavedTip(WidgetRef ref, String content) async {
  final current = await ref.read(savedScoutTipsProvider.future);
  final next = current.where((t) => t.content != content).toList();
  await _persist(next);
  ref.invalidate(savedScoutTipsProvider);
}

// ─────────────────────────────────────────────────────────────
//  Sheet UI
// ─────────────────────────────────────────────────────────────

class SavedTipsSheet extends ConsumerWidget {
  const SavedTipsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SavedTipsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedScoutTipsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: TSColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              const Text('🔖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('saved tips', style: TSTextStyles.heading(size: 20)),
            ]),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child:
                        CircularProgressIndicator(color: TSColors.lime)),
              ),
              error: (_, __) => const SizedBox(),
              data: (tips) {
                if (tips.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'no saved tips yet — tap 🔖 on any scout reply to stash it here.',
                      style: TSTextStyles.caption(color: TSColors.muted),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tips.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final t = tips[i];
                      return Dismissible(
                        key: ValueKey('saved_${t.savedAt.toIso8601String()}_${t.content.hashCode}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          TSHaptics.medium();
                          removeSavedTip(ref, t.content);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          decoration: BoxDecoration(
                            color: TSColors.coral,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 20),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            TSHaptics.light();
                            await Clipboard.setData(
                                ClipboardData(text: t.content));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text('copied',
                                    style: TSTextStyles.body(
                                        color: TSColors.bg,
                                        size: 13)),
                                backgroundColor: TSColors.lime,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          onLongPress: () async {
                            TSHaptics.medium();
                            await removeSavedTip(ref, t.content);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TSColors.s2,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: TSColors.border),
                            ),
                            child: Text(t.content,
                                style: TSTextStyles.body(size: 14)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text('tap to copy · swipe ← to delete',
                style: TSTextStyles.caption(color: TSColors.muted2)),
          ],
        ),
      ),
    );
  }
}
