import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/avatar_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';

/// Full inline edit of the user's profile — nickname, tag, emoji,
/// home city / airport, travel style, passports, avatar. Reached from
/// Settings → "edit profile".
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameC = TextEditingController();
  final _tagC = TextEditingController();
  final _cityC = TextEditingController();
  final _airportC = TextEditingController();

  String? _emoji;
  String? _travelStyle;
  Set<String> _passports = {};
  bool _saving = false;
  bool _avatarBusy = false;
  bool _initialised = false;

  static const _emojiChoices = [
    '😎','😊','🤠','🧳','✈️','🌍','🌴','⛰️','🏝️','🏖️',
    '🗺️','🎒','📸','🎉','🌙','☀️','🌊','🧗','🚀','💃',
  ];

  static const _styles = [
    (id: 'budget',   emoji: '🎒', title: 'budget explorer'),
    (id: 'midrange', emoji: '🧳', title: 'mid-range'),
    (id: 'splurge',  emoji: '✨', title: 'occasional splurger'),
  ];

  static const _commonPassports = [
    '🇺🇸 US', '🇬🇧 UK', '🇬🇭 Ghana', '🇳🇬 Nigeria', '🇨🇦 Canada',
    '🇫🇷 France', '🇩🇪 Germany', '🇪🇸 Spain', '🇮🇹 Italy',
    '🇯🇲 Jamaica', '🇿🇦 South Africa', '🇰🇪 Kenya', '🇪🇬 Egypt',
    '🇯🇵 Japan', '🇦🇺 Australia', '🇧🇷 Brazil', '🇲🇽 Mexico',
  ];

  void _hydrate(AppUser u) {
    if (_initialised) return;
    _nicknameC.text = u.nickname ?? '';
    _tagC.text = u.tag ?? '';
    _cityC.text = u.homeCity ?? '';
    _airportC.text = u.homeAirport ?? '';
    _emoji = u.emoji ?? '😎';
    _travelStyle = u.travelStyle;
    _passports = u.passports.toSet();
    _initialised = true;
  }

  @override
  void dispose() {
    _nicknameC.dispose();
    _tagC.dispose();
    _cityC.dispose();
    _airportC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      backgroundColor: TSColors.bg,
      appBar: const TSAppBar(title: 'edit profile'),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: TSColors.lime)),
          error: (e, _) => Center(child: Text(humanizeError(e))),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('no profile'));
            }
            _hydrate(user);
            return _form(user);
          },
        ),
      ),
    );
  }

  Widget _form(AppUser user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _avatarRow(user),
        const SizedBox(height: 20),

        _label('nickname'),
        _textField(
          controller: _nicknameC,
          hint: 'what should squads call you',
          maxLength: 24,
          inputFormatters: [LengthLimitingTextInputFormatter(24)],
        ),
        const SizedBox(height: 14),

        _label('@tag'),
        _textField(
          controller: _tagC,
          hint: 'your unique handle',
          prefix: '@',
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
        ),
        Text(
          'can only be changed every 30 days',
          style: TSTextStyles.caption(color: TSColors.muted),
        ),
        const SizedBox(height: 14),

        _label('vibe emoji'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in _emojiChoices) _emojiChip(e),
        ]),
        const SizedBox(height: 18),

        _label('home city'),
        _textField(
          controller: _cityC,
          hint: 'e.g. Accra',
        ),
        const SizedBox(height: 10),
        _label('home airport (code)'),
        _textField(
          controller: _airportC,
          hint: 'e.g. ACC',
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
            LengthLimitingTextInputFormatter(4),
          ],
        ),
        const SizedBox(height: 18),

        _label('travel style'),
        Column(children: [
          for (final s in _styles) _styleRow(s),
        ]),
        const SizedBox(height: 18),

        _label('passports'),
        Text('tap any you hold, or add your own',
            style: TSTextStyles.caption(color: TSColors.muted)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in _commonPassports) _passportChip(p),
          // Custom passports the user has added beyond the common list
          for (final p in _passports.where((p) => !_commonPassports.contains(p)))
            _passportChip(p),
          _AddPassportChip(onAdd: _addCustomPassport),
        ]),
        const SizedBox(height: 28),

        TSButton(
          label: _saving ? 'saving…' : '✓ save changes',
          onTap: _saving ? null : _save,
        ),
        const SizedBox(height: 12),
        TSButton(
          label: 'cancel',
          variant: TSButtonVariant.outline,
          onTap: _saving ? null : () => context.pop(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _avatarRow(AppUser user) {
    return Center(
      child: GestureDetector(
        onTap: _avatarBusy ? null : _openAvatarSheet,
        child: Stack(alignment: Alignment.center, children: [
          TSAvatar(
            emoji: _emoji ?? '😎',
            photoUrl: user.avatarUrl,
            size: 88,
            ringColor: TSColors.limeDim(0.35),
            ringWidth: 2,
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TSColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: TSColors.bg, width: 2),
              ),
              child: _avatarBusy
                  ? const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: TSColors.bg),
                    )
                  : const Icon(Icons.camera_alt_rounded,
                      color: TSColors.bg, size: 14),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Text(text.toUpperCase(),
            style: TSTextStyles.label(color: TSColors.muted, size: 10)),
      );

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    String? prefix,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: TSTextStyles.body(size: 15),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixText: prefix,
        hintStyle: TSTextStyles.body(color: TSColors.muted, size: 15),
        filled: true,
        fillColor: TSColors.s2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _emojiChip(String e) {
    final sel = _emoji == e;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.selection();
        setState(() => _emoji = e);
      },
      child: Container(
        width: 44, height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? TSColors.limeDim(0.15) : TSColors.s2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: sel ? TSColors.lime : TSColors.border,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Text(e, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _styleRow(({String id, String emoji, String title}) s) {
    final sel = _travelStyle == s.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TSHaptics.selection();
          setState(() => _travelStyle = s.id);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? TSColors.limeDim(0.10) : TSColors.s2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? TSColors.lime : TSColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Text(s.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.title, style: TSTextStyles.body(size: 15)),
            ),
            if (sel)
              const Icon(Icons.check_rounded,
                  color: TSColors.lime, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _passportChip(String p) {
    final sel = _passports.contains(p);
    final isCustom = !_commonPassports.contains(p);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TSHaptics.selection();
        setState(() {
          if (sel) {
            _passports.remove(p);
          } else {
            _passports.add(p);
          }
        });
      },
      onLongPress: isCustom
          ? () {
              TSHaptics.longPressReact();
              setState(() => _passports.remove(p));
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? TSColors.limeDim(0.15) : TSColors.s2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: sel ? TSColors.lime : TSColors.border,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Text(p, style: TSTextStyles.body(size: 13)),
      ),
    );
  }

  /// Opens a small sheet with a text field so the user can type a country
  /// name. Resolves to a canonical flag via `TSQuickDestinations.flagFor`
  /// (returns '🌍' if unknown), then adds "🏳️ Name" to the set.
  Future<void> _addCustomPassport() async {
    TSHaptics.ctaTap();
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TSColors.border2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('add a passport',
                    style: TSTextStyles.heading(size: 18)),
                const SizedBox(height: 4),
                Text('type the country',
                    style:
                        TSTextStyles.caption(color: TSColors.muted)),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TSTextStyles.body(size: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Portugal',
                    hintStyle:
                        TSTextStyles.body(color: TSColors.muted, size: 15),
                    filled: true,
                    fillColor: TSColors.s2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (v) =>
                      Navigator.pop(sheet, v.trim()),
                ),
                const SizedBox(height: 14),
                TSButton(
                  label: 'add →',
                  onTap: () => Navigator.pop(sheet, ctrl.text.trim()),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null || result.isEmpty) return;
    // Title-case the input, look up a flag, build the chip label.
    final name = result
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) =>
            w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
    final flag = TSQuickDestinations.flagFor(name) ?? '🏳️';
    final label = '$flag $name';
    setState(() => _passports.add(label));
    TSHaptics.ctaCommit();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    TSHaptics.medium();
    setState(() => _saving = true);

    final auth = ref.read(authServiceProvider);
    final newTag = _tagC.text.trim().toLowerCase();
    final oldTag = (ref.read(currentProfileProvider).valueOrNull?.tag ?? '')
        .toLowerCase();

    try {
      // Tag change has its own validation (30-day cooldown + availability)
      if (newTag.isNotEmpty && newTag != oldTag) {
        final res = await auth.changeTag(newTag);
        if (!res.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res.error ?? 'could not change tag'),
                backgroundColor: TSColors.coral,
              ),
            );
          }
          setState(() => _saving = false);
          return;
        }
      }

      await auth.updateProfile({
        'nickname': _nicknameC.text.trim(),
        'emoji': _emoji,
        'home_city':
            _cityC.text.trim().isEmpty ? null : _cityC.text.trim(),
        'home_airport': _airportC.text.trim().isEmpty
            ? null
            : _airportC.text.trim().toUpperCase(),
        'travel_style': _travelStyle,
        'passports': _passports.toList(),
      });
      ref.invalidate(currentProfileProvider);
      TSHaptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile saved ✦',
                style: TSTextStyles.body(color: TSColors.bg)),
            backgroundColor: TSColors.lime,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAvatarSheet() async {
    TSHaptics.light();
    final user = ref.read(currentProfileProvider).valueOrNull;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: TSColors.s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TSColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('profile picture', style: TSTextStyles.heading(size: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 22)),
              title: Text('take photo', style: TSTextStyles.body()),
              onTap: () {
                Navigator.pop(sheet);
                _pickAvatar(ImageSource.camera);
              },
            ),
            const Divider(color: TSColors.border, height: 1),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 22)),
              title: Text('choose from library',
                  style: TSTextStyles.body()),
              onTap: () {
                Navigator.pop(sheet);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) ...[
              const Divider(color: TSColors.border, height: 1),
              ListTile(
                leading: const Text('🗑️', style: TextStyle(fontSize: 22)),
                title: Text('remove photo',
                    style: TSTextStyles.body(color: TSColors.coral)),
                subtitle: Text('keep emoji only',
                    style: TSTextStyles.caption(color: TSColors.muted)),
                onTap: () {
                  Navigator.pop(sheet);
                  _removeAvatar();
                },
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    setState(() => _avatarBusy = true);
    try {
      final url = await ref
          .read(avatarServiceProvider)
          .pickAndUpload(source: source);
      if (url != null) {
        TSHaptics.success();
        ref.invalidate(currentProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _avatarBusy = true);
    try {
      await ref.read(avatarServiceProvider).remove();
      TSHaptics.medium();
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }
}

/// Dashed "+ add" chip that lives after the preset passports and opens
/// the add-country sheet. Visually distinct so it never looks like a
/// selectable chip you've forgotten to tap.
class _AddPassportChip extends StatelessWidget {
  const _AddPassportChip({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: TSColors.muted,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, color: TSColors.muted, size: 14),
          const SizedBox(width: 4),
          Text('add',
              style: TSTextStyles.body(size: 13, color: TSColors.muted)),
        ]),
      ),
    );
  }
}
