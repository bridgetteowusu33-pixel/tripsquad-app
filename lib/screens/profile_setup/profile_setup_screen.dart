import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/effects.dart';
import '../../core/haptics.dart';
import '../../core/constants.dart';
import '../../widgets/widgets.dart';
import '../../widgets/tappable.dart';
import '../../widgets/ts_scaffold.dart';

// ─────────────────────────────────────────────────────────────
//  PROFILE SETUP — 5 screens + payoff
//  Runs after signup, feels like a conversation with Scout
// ─────────────────────────────────────────────────────────────

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends ConsumerState<ProfileSetupScreen> {
  int _step = 0;

  // Step 1: Name + emoji
  final _nameCtrl = TextEditingController();
  String _emoji = '😎';

  // Step 2: Home city
  final _cityCtrl = TextEditingController();
  String? _selectedCity;
  String? _selectedAirport;

  // Step 3: Travel style
  String? _travelStyle;

  // Step 4: Passports
  final List<String> _passports = [];

  // Step 5: Tag name
  final _tagCtrl = TextEditingController();
  bool _tagAvailable = true;
  bool _checkingTag = false;

  bool _saving = false;

  final _cities = [
    ('London', 'LHR'), ('New York', 'JFK'), ('Los Angeles', 'LAX'),
    ('Paris', 'CDG'), ('Tokyo', 'NRT'), ('Dubai', 'DXB'),
    ('Singapore', 'SIN'), ('Barcelona', 'BCN'), ('Amsterdam', 'AMS'),
    ('Sydney', 'SYD'), ('Toronto', 'YYZ'), ('Berlin', 'BER'),
    ('Miami', 'MIA'), ('Bangkok', 'BKK'), ('Istanbul', 'IST'),
    ('San Francisco', 'SFO'), ('Chicago', 'ORD'), ('Seoul', 'ICN'),
    ('Lisbon', 'LIS'), ('Rome', 'FCO'), ('Mexico City', 'MEX'),
    ('Lagos', 'LOS'), ('Accra', 'ACC'), ('Nairobi', 'NBO'),
    ('Cape Town', 'CPT'), ('Johannesburg', 'JNB'), ('Cairo', 'CAI'),
    ('Mumbai', 'BOM'), ('Delhi', 'DEL'), ('Hong Kong', 'HKG'),
    ('Kuala Lumpur', 'KUL'), ('Manila', 'MNL'), ('Jakarta', 'CGK'),
    ('São Paulo', 'GRU'), ('Buenos Aires', 'EZE'), ('Bogotá', 'BOG'),
    ('Lima', 'LIM'), ('Medellín', 'MDE'), ('Atlanta', 'ATL'),
    ('Dallas', 'DFW'), ('Denver', 'DEN'), ('Seattle', 'SEA'),
    ('Boston', 'BOS'), ('Washington DC', 'IAD'), ('Houston', 'IAH'),
    ('Manchester', 'MAN'), ('Edinburgh', 'EDI'), ('Dublin', 'DUB'),
    ('Copenhagen', 'CPH'), ('Stockholm', 'ARN'), ('Oslo', 'OSL'),
    ('Helsinki', 'HEL'), ('Vienna', 'VIE'), ('Prague', 'PRG'),
    ('Warsaw', 'WAW'), ('Budapest', 'BUD'), ('Athens', 'ATH'),
    ('Marrakech', 'RAK'), ('Casablanca', 'CMN'),
  ];

  final _passportFlags = [
    ('🇬🇧', 'UK'), ('🇺🇸', 'US'), ('🇨🇦', 'Canada'), ('🇦🇺', 'Australia'),
    ('🇳🇬', 'Nigeria'), ('🇬🇭', 'Ghana'), ('🇰🇪', 'Kenya'), ('🇿🇦', 'South Africa'),
    ('🇮🇳', 'India'), ('🇵🇰', 'Pakistan'), ('🇧🇩', 'Bangladesh'), ('🇵🇭', 'Philippines'),
    ('🇫🇷', 'France'), ('🇩🇪', 'Germany'), ('🇮🇹', 'Italy'), ('🇪🇸', 'Spain'),
    ('🇳🇱', 'Netherlands'), ('🇧🇪', 'Belgium'), ('🇵🇹', 'Portugal'), ('🇮🇪', 'Ireland'),
    ('🇧🇷', 'Brazil'), ('🇲🇽', 'Mexico'), ('🇨🇴', 'Colombia'), ('🇦🇷', 'Argentina'),
    ('🇯🇵', 'Japan'), ('🇰🇷', 'South Korea'), ('🇨🇳', 'China'), ('🇸🇬', 'Singapore'),
    ('🇦🇪', 'UAE'), ('🇸🇦', 'Saudi'), ('🇪🇬', 'Egypt'), ('🇲🇦', 'Morocco'),
    ('🇯🇲', 'Jamaica'), ('🇹🇹', 'Trinidad'), ('🇬🇾', 'Guyana'), ('🇧🇸', 'Bahamas'),
    ('🇸🇪', 'Sweden'), ('🇳🇴', 'Norway'), ('🇩🇰', 'Denmark'), ('🇫🇮', 'Finland'),
    ('🇵🇱', 'Poland'), ('🇨🇿', 'Czechia'), ('🇭🇺', 'Hungary'), ('🇷🇴', 'Romania'),
    ('🇹🇷', 'Turkey'), ('🇹🇭', 'Thailand'), ('🇻🇳', 'Vietnam'), ('🇮🇩', 'Indonesia'),
  ];

  Future<void> _checkTag(String tag) async {
    if (tag.length < 3) {
      setState(() { _tagAvailable = false; _checkingTag = false; });
      return;
    }
    setState(() => _checkingTag = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('tag', tag.toLowerCase())
          .limit(1);
      if (mounted) {
        setState(() {
          _tagAvailable = (data as List).isEmpty;
          _checkingTag = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingTag = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').update({
        'nickname': _nameCtrl.text.trim(),
        'emoji': _emoji,
        'home_city': _selectedCity,
        'home_airport': _selectedAirport,
        'travel_style': _travelStyle,
        'passports': _passports,
        'tag': _tagCtrl.text.trim().toLowerCase().isNotEmpty
            ? _tagCtrl.text.trim().toLowerCase()
            : null,
        'profile_complete': true,
      }).eq('id', uid);

      if (mounted) context.go('/home');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // Unique-constraint violation on profiles.tag — someone grabbed it
      // between the live check and save. Bounce back to the tag step.
      if (e.code == '23505' && e.message.contains('profiles_tag_key')) {
        setState(() {
          _step = 5;
          _tagAvailable = false;
        });
        TSHaptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'that tag just got claimed. pick a different one ✦',
              style: TSTextStyles.body(color: TSColors.bg),
            ),
            backgroundColor: TSColors.lime,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "couldn't save your profile. try again in a sec.",
              style: TSTextStyles.body(color: TSColors.bg),
            ),
            backgroundColor: TSColors.coral,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "couldn't save your profile. try again in a sec.",
              style: TSTextStyles.body(color: TSColors.bg),
            ),
            backgroundColor: TSColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TSScaffold(
      style: TSBackgroundStyle.hero,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSSpacing.lg),
          child: Column(children: [
            const SizedBox(height: 16),

            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => AnimatedContainer(
                duration: 200.ms,
                width: i == _step ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i <= _step ? TSColors.lime : TSColors.s3,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            const SizedBox(height: 8),

            // Skip button
            if (_step < 5)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    final uid = Supabase.instance.client.auth.currentUser!.id;
                    await Supabase.instance.client.from('profiles').update({
                      'profile_complete': true,
                    }).eq('id', uid);
                    if (mounted) context.go('/home');
                  },
                  child: Text('skip for now', style: TSTextStyles.caption(color: TSColors.muted)),
                ),
              ),

            const SizedBox(height: 16),

            // Steps
            Expanded(
              child: AnimatedSwitcher(
                duration: 300.ms,
                switchInCurve: Curves.easeOutCubic,
                child: _buildStep(),
              ),
            ),

            // Bottom nav
            Padding(
              padding: const EdgeInsets.only(bottom: TSSpacing.lg),
              child: Row(children: [
                if (_step > 0)
                  Expanded(
                    child: TSTappable(
                      onTap: () => setState(() => _step--),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: TSColors.s2,
                          borderRadius: TSRadius.full,
                          border: Border.all(color: TSColors.border2),
                        ),
                        child: Text('← back',
                          style: TSTextStyles.title(color: TSColors.text2, size: 14),
                          textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TSTappable(
                    onTap: _step == 5 ? _save : () {
                      TSHaptics.medium();
                      setState(() => _step++);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: TSColors.lime,
                        borderRadius: TSRadius.full,
                        boxShadow: [BoxShadow(color: TSColors.limeDim(0.3), blurRadius: 12)],
                      ),
                      child: _saving
                          ? const Center(child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: TSColors.bg),
                            ))
                          : Text(
                              _step == 5 ? "let's go 🚀" : 'next →',
                              style: TSTextStyles.title(color: TSColors.bg, size: 15),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _StepName(key: const ValueKey(0));
      case 1: return _StepCity(key: const ValueKey(1));
      case 2: return _StepStyle(key: const ValueKey(2));
      case 3: return _StepPassport(key: const ValueKey(3));
      case 4: return _StepTag(key: const ValueKey(4));
      case 5: return _StepPayoff(key: const ValueKey(5));
      default: return const SizedBox();
    }
  }

  // ── STEP 1: Name + Emoji ──────────────────────────────────
  Widget _StepName({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('🧭', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text('first things first', style: TSTextStyles.heading(size: 24)),
          TSShimmerText(
            text: 'what do we call you?',
            style: TSTextStyles.heading(size: 24, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic),
            shimmerColor: TSColors.lime,
          ),
          const SizedBox(height: 8),
          Text('scout needs a name to work with.',
            style: TSTextStyles.body(color: TSColors.muted)),

          const SizedBox(height: 24),

          TSTextField(
            hint: 'your name or nickname',
            controller: _nameCtrl,
            autofocus: true,
          ),

          const SizedBox(height: 20),

          Text('pick your avatar', style: TSTextStyles.label()),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: TSEmojis.avatars.map((e) {
              final sel = _emoji == e;
              return GestureDetector(
                onTap: () {
                  TSHaptics.selection();
                  setState(() => _emoji = e);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: sel ? TSColors.limeDim(0.15) : TSColors.s2,
                    borderRadius: TSRadius.sm,
                    border: Border.all(
                      color: sel ? TSColors.lime : TSColors.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Home City ─────────────────────────────────────
  Widget _StepCity({Key? key}) {
    final query = _cityCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? _cities
        : _cities.where((c) => c.$1.toLowerCase().contains(query)).toList();

    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('✈️', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text('where do you', style: TSTextStyles.heading(size: 24)),
          TSShimmerText(
            text: 'usually fly from?',
            style: TSTextStyles.heading(size: 24, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic),
            shimmerColor: TSColors.lime,
          ),
          const SizedBox(height: 8),
          Text('scout uses this to find trips that actually make sense for you.',
            style: TSTextStyles.body(color: TSColors.muted)),

          const SizedBox(height: 20),

          TSTextField(
            hint: 'search your city...',
            controller: _cityCtrl,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.take(12).map((c) {
              final sel = _selectedCity == c.$1;
              return GestureDetector(
                onTap: () {
                  TSHaptics.selection();
                  setState(() {
                    _selectedCity = c.$1;
                    _selectedAirport = c.$2;
                    _cityCtrl.text = c.$1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? TSColors.limeDim(0.12) : TSColors.s2,
                    borderRadius: TSRadius.full,
                    border: Border.all(
                      color: sel ? TSColors.lime : TSColors.border,
                    ),
                  ),
                  child: Text(
                    '${c.$1} (${c.$2})',
                    style: TSTextStyles.body(
                      color: sel ? TSColors.lime : TSColors.text2,
                      size: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── STEP 3: Travel Style ──────────────────────────────────
  Widget _StepStyle({Key? key}) {
    final styles = [
      (
        id: 'budget',
        emoji: '🎒',
        title: 'budget explorer',
        desc: 'hostels, street food, max experiences per dollar',
        color: TSColors.teal,
      ),
      (
        id: 'midrange',
        emoji: '🧳',
        title: 'mid-range traveller',
        desc: 'comfortable hotels, nice restaurants, balanced budget',
        color: TSColors.lime,
      ),
      (
        id: 'splurge',
        emoji: '✨',
        title: 'occasional splurger',
        desc: 'boutique stays, fine dining, treat yourself energy',
        color: TSColors.gold,
      ),
    ];

    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('💸', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text('how do you', style: TSTextStyles.heading(size: 24)),
          TSShimmerText(
            text: 'travel?',
            style: TSTextStyles.heading(size: 24, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic),
            shimmerColor: TSColors.lime,
          ),
          const SizedBox(height: 8),
          Text("be honest. scout won't judge 😏",
            style: TSTextStyles.body(color: TSColors.muted)),

          const SizedBox(height: 24),

          ...styles.map((s) {
            final sel = _travelStyle == s.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TSTappable(
                onTap: () {
                  TSHaptics.selection();
                  setState(() => _travelStyle = s.id);
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.all(TSSpacing.md),
                  decoration: BoxDecoration(
                    color: sel ? s.color.withOpacity(0.08) : TSColors.s2,
                    borderRadius: TSRadius.md,
                    border: Border.all(
                      color: sel ? s.color : TSColors.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: TSTextStyles.title(
                          color: sel ? s.color : TSColors.text,
                        )),
                        const SizedBox(height: 2),
                        Text(s.desc, style: TSTextStyles.caption(color: TSColors.muted)),
                      ],
                    )),
                    if (sel)
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.color,
                        ),
                        child: const Icon(Icons.check_rounded, color: TSColors.bg, size: 14),
                      ),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── STEP 4: Passports ─────────────────────────────────────
  Widget _StepPassport({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('🛂', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text('which passport do', style: TSTextStyles.heading(size: 24)),
          TSShimmerText(
            text: 'you carry?',
            style: TSTextStyles.heading(size: 24, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic),
            shimmerColor: TSColors.lime,
          ),
          const SizedBox(height: 8),
          Text('helps scout know where you can go without visa drama.',
            style: TSTextStyles.body(color: TSColors.muted)),

          const SizedBox(height: 20),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: _passportFlags.map((p) {
              final sel = _passports.contains(p.$2);
              return GestureDetector(
                onTap: () {
                  TSHaptics.selection();
                  setState(() {
                    if (sel) {
                      _passports.remove(p.$2);
                    } else {
                      _passports.add(p.$2);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: sel ? TSColors.limeDim(0.12) : TSColors.s2,
                    borderRadius: TSRadius.sm,
                    border: Border.all(
                      color: sel ? TSColors.lime : TSColors.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.$1, style: const TextStyle(fontSize: 18)),
                      Text(p.$2, style: TSTextStyles.caption(
                        color: sel ? TSColors.lime : TSColors.muted,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── STEP 5: Tag Name ──────────────────────────────────────
  Widget _StepTag({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('🏷️', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text('pick your', style: TSTextStyles.heading(size: 24)),
          TSShimmerText(
            text: 'tag name',
            style: TSTextStyles.heading(size: 24, color: TSColors.lime)
                .copyWith(fontStyle: FontStyle.italic),
            shimmerColor: TSColors.lime,
          ),
          const SizedBox(height: 8),
          Text('your squad can find you by your tag. make it you.',
            style: TSTextStyles.body(color: TSColors.muted)),

          const SizedBox(height: 24),

          Row(children: [
            Text('@', style: TSTextStyles.heading(size: 28, color: TSColors.lime)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                style: TSTextStyles.heading(size: 22),
                decoration: InputDecoration(
                  hintText: 'yourname',
                  hintStyle: TSTextStyles.heading(size: 22, color: TSColors.s3),
                  border: InputBorder.none,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                onChanged: (v) => _checkTag(v),
              ),
            ),
            if (_checkingTag)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: TSColors.muted),
              )
            else if (_tagCtrl.text.length >= 3)
              Icon(
                _tagAvailable ? Icons.check_circle : Icons.cancel,
                color: _tagAvailable ? TSColors.lime : TSColors.coral,
                size: 22,
              ),
          ]),

          Container(
            height: 2,
            decoration: BoxDecoration(
              color: _tagCtrl.text.isEmpty
                  ? TSColors.border
                  : _tagAvailable ? TSColors.lime : TSColors.coral,
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 12),

          if (_tagCtrl.text.length >= 3 && !_tagAvailable)
            Text('that tag is taken. try another one.',
              style: TSTextStyles.caption(color: TSColors.coral)),

          if (_tagCtrl.text.length >= 3 && _tagAvailable)
            Text('nice. @${_tagCtrl.text.toLowerCase()} is yours.',
              style: TSTextStyles.caption(color: TSColors.lime)),

          const SizedBox(height: 20),

          Text('tag name rules:', style: TSTextStyles.label()),
          const SizedBox(height: 6),
          Text('• lowercase letters, numbers, underscores only\n• 3-20 characters\n• unique to you',
            style: TSTextStyles.body(color: TSColors.muted, size: 13)),
        ],
      ),
    );
  }

  // ── STEP 6: Payoff ────────────────────────────────────────
  Widget _StepPayoff({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TSPulseRing(color: TSColors.lime, size: 100),
          const SizedBox(height: 24),
          Text('🧭', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          TSShimmerText(
            text: 'scout knows you now',
            style: TSTextStyles.heading(size: 24, color: TSColors.lime),
            shimmerColor: TSColors.lime,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text("let's find your next trip.",
            style: TSTextStyles.body(color: TSColors.text2),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TSSpacing.md),
            decoration: BoxDecoration(
              color: TSColors.s2,
              borderRadius: TSRadius.md,
              border: Border.all(color: TSColors.limeDim(0.2)),
            ),
            child: Column(children: [
              Row(children: [
                Text(_emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_nameCtrl.text.isEmpty ? 'traveller' : _nameCtrl.text,
                    style: TSTextStyles.title()),
                  if (_tagCtrl.text.isNotEmpty)
                    Text('@${_tagCtrl.text.toLowerCase()}',
                      style: TSTextStyles.caption(color: TSColors.lime)),
                ]),
              ]),
              if (_selectedCity != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Text('✈️', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text('flies from $_selectedCity ($_selectedAirport)',
                    style: TSTextStyles.body(color: TSColors.text2, size: 13)),
                ]),
              ],
              if (_travelStyle != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Text(_travelStyle == 'budget' ? '🎒' : _travelStyle == 'midrange' ? '🧳' : '✨',
                    style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(_travelStyle ?? '',
                    style: TSTextStyles.body(color: TSColors.text2, size: 13)),
                ]),
              ],
              if (_passports.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Text('🛂', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_passports.join(', '),
                    style: TSTextStyles.body(color: TSColors.text2, size: 13))),
                ]),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
