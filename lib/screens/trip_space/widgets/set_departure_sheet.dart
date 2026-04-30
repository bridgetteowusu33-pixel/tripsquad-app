import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors.dart';
import '../../../core/haptics.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../services/supabase_service.dart';

/// Modal sheet to set the current user's departure city + IATA for
/// flight search. Shown from the "tell scout where you're flying
/// from" CTA on the user's own flight card.
///
/// MVP keeps the input simple: a free-text city + a 3-letter IATA
/// code (uppercased). Future: city-name autocomplete that resolves
/// to IATA via a geocoding API.
class SetDepartureSheet extends ConsumerStatefulWidget {
  const SetDepartureSheet({
    super.key,
    required this.trip,
    required this.arrivalIata,
    this.initialCity,
    this.initialIata,
  });
  final Trip trip;
  final String? arrivalIata;
  final String? initialCity;
  final String? initialIata;

  @override
  ConsumerState<SetDepartureSheet> createState() =>
      _SetDepartureSheetState();
}

class _SetDepartureSheetState extends ConsumerState<SetDepartureSheet> {
  late final TextEditingController _city;
  late final TextEditingController _iata;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.initialCity ?? '');
    _iata = TextEditingController(text: widget.initialIata ?? '');
    // If the per-trip plan is empty, fall back to the profile defaults
    // (home_city + home_airport) so the user isn't typing them again.
    if ((widget.initialCity ?? '').isEmpty &&
        (widget.initialIata ?? '').isEmpty) {
      _prefillFromProfile();
    }
  }

  Future<void> _prefillFromProfile() async {
    try {
      final profile =
          await ref.read(authServiceProvider).fetchCurrentProfile();
      if (!mounted || profile == null) return;
      final city = profile.homeCity?.trim() ?? '';
      final iata = profile.homeAirport?.trim().toUpperCase() ?? '';
      if (city.isNotEmpty || iata.isNotEmpty) {
        setState(() {
          if (_city.text.isEmpty) _city.text = city;
          if (_iata.text.isEmpty) _iata.text = iata;
        });
      }
    } catch (_) { /* non-fatal */ }
  }

  @override
  void dispose() {
    _city.dispose();
    _iata.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final city = _city.text.trim();
    final iata = _iata.text.trim().toUpperCase();
    if (iata.isEmpty || iata.length != 3) {
      setState(() => _error = 'enter a 3-letter airport code (like JFK)');
      return;
    }
    if (city.isEmpty) {
      setState(() => _error =
          "add your city so the squad knows where you're coming from");
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(bookingServiceProvider).upsertMyArrivalPlan(
            tripId: widget.trip.id,
            departureCity: city,
            departureIata: iata,
            arrivalIata: widget.arrivalIata,
          );
      if (mounted) {
        TSHaptics.success();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = humanizeError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: TSColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GrabHandle(),
            const SizedBox(height: 16),
            Text('where are you flying from?',
                style: TSTextStyles.heading(size: 20)),
            const SizedBox(height: 6),
            Text(
              'scout uses this to build your flight search and match you with the squad.',
              style: TSTextStyles.body(color: TSColors.text2),
            ),
            const SizedBox(height: 20),

            Text('your city',
                style: TSTextStyles.label(color: TSColors.muted, size: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: _city,
              autofocus: true,
              style: TSTextStyles.body(),
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('e.g. New York'),
            ),
            const SizedBox(height: 16),

            Text('airport code (3 letters)',
                style: TSTextStyles.label(color: TSColors.muted, size: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: _iata,
              style: TSTextStyles.body(),
              textCapitalization: TextCapitalization.characters,
              maxLength: 3,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                UpperCaseTextFormatter(),
              ],
              decoration: _decoration('JFK')
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 4),
            Text(
              'common: JFK · LAX · LHR · CDG · MEX · NRT · DFW · SFO · ORD',
              style: TSTextStyles.caption(color: TSColors.muted),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TSTextStyles.caption(color: Colors.redAccent)),
            ],

            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(
                    'cancel',
                    style: TSTextStyles.label(color: TSColors.text2, size: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _saving ? null : _save,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: TSColors.lime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TSColors.bg,
                            ),
                          )
                        : Text(
                            'save',
                            style: TSTextStyles.label(
                                color: TSColors.bg, size: 13),
                          ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TSTextStyles.body(color: TSColors.muted),
      filled: true,
      fillColor: TSColors.s2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TSColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TSColors.lime, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: TSColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}
