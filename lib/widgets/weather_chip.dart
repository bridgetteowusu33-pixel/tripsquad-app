import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  WEATHER CHIP
//
//  Small "☀️ 22°" pill showing the forecast high for a trip's
//  destination on its start date. Uses Open-Meteo — free, no
//  API key — via two requests:
//    1. geocoding-api.open-meteo.com to resolve city → lat/lng
//    2. api.open-meteo.com/v1/forecast → daily max temp + wmo code
//
//  Called from HomeCountdown when the trip starts in <14 days.
//  Provider caches by (destination + startDate) for the session
//  so we don't re-ping on every rebuild.
// ─────────────────────────────────────────────────────────────

class Forecast {
  const Forecast({required this.tempC, required this.emoji});
  final double tempC;
  final String emoji;
}

/// User-preferred temperature unit, persisted in SharedPreferences.
/// Default is Celsius — swap via Settings → units.
enum TempUnit { celsius, fahrenheit }

final temperatureUnitProvider =
    StateNotifierProvider<_TempUnitNotifier, TempUnit>(
        (ref) => _TempUnitNotifier());

class _TempUnitNotifier extends StateNotifier<TempUnit> {
  _TempUnitNotifier() : super(TempUnit.celsius) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('temp_unit');
    if (raw == 'fahrenheit') state = TempUnit.fahrenheit;
  }

  Future<void> set(TempUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_unit', unit.name);
  }
}

/// WMO weather code → emoji mapping. Keeps the chip tiny.
String _wmoEmoji(int code) {
  if (code == 0) return '☀️';
  if (code <= 2) return '🌤️';
  if (code == 3) return '☁️';
  if (code >= 45 && code <= 48) return '🌫️';
  if (code >= 51 && code <= 67) return '🌧️';
  if (code >= 71 && code <= 77) return '❄️';
  if (code >= 80 && code <= 82) return '🌦️';
  if (code >= 85 && code <= 86) return '🌨️';
  if (code >= 95) return '⛈️';
  return '🌍';
}

final forecastProvider = FutureProviderFamily<Forecast?,
    ({String destination, DateTime date})>((ref, key) async {
  try {
    final geo = await http.get(Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&format=json&name=${Uri.encodeQueryComponent(key.destination)}'));
    if (geo.statusCode != 200) return null;
    final geoJson = jsonDecode(geo.body) as Map<String, dynamic>;
    final results = (geoJson['results'] as List?) ?? const [];
    if (results.isEmpty) return null;
    final first = results.first as Map<String, dynamic>;
    final lat = first['latitude'];
    final lon = first['longitude'];
    if (lat == null || lon == null) return null;

    final ymd = '${key.date.year.toString().padLeft(4, '0')}-'
        '${key.date.month.toString().padLeft(2, '0')}-'
        '${key.date.day.toString().padLeft(2, '0')}';
    final fx = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_max,weathercode&timezone=auto&start_date=$ymd&end_date=$ymd'));
    if (fx.statusCode != 200) return null;
    final fxJson = jsonDecode(fx.body) as Map<String, dynamic>;
    final daily = fxJson['daily'] as Map<String, dynamic>?;
    if (daily == null) return null;
    final temps = (daily['temperature_2m_max'] as List?) ?? const [];
    final codes = (daily['weathercode'] as List?) ?? const [];
    if (temps.isEmpty || codes.isEmpty) return null;
    final temp = (temps.first as num).toDouble();
    final code = (codes.first as num).toInt();
    return Forecast(tempC: temp, emoji: _wmoEmoji(code));
  } catch (_) {
    return null;
  }
});

/// Pill widget. Renders nothing while loading or on error so it
/// never leaves a ghost slot in the countdown card.
class WeatherChip extends ConsumerWidget {
  const WeatherChip({
    super.key,
    required this.destination,
    required this.date,
  });
  final String destination;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show for trips within the Open-Meteo forecast window
    // (~14 days). Further out is noise.
    final delta = date.difference(DateTime.now()).inDays;
    if (delta < 0 || delta > 14) return const SizedBox();
    final forecast = ref
        .watch(forecastProvider((destination: destination, date: date)))
        .valueOrNull;
    if (forecast == null) return const SizedBox();
    final unit = ref.watch(temperatureUnitProvider);
    final temp = unit == TempUnit.fahrenheit
        ? (forecast.tempC * 9 / 5 + 32).round()
        : forecast.tempC.round();
    final suffix = unit == TempUnit.fahrenheit ? '°F' : '°';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TSColors.s2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TSColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(forecast.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text('$temp$suffix',
            style: TSTextStyles.label(color: TSColors.text2, size: 12)),
      ]),
    );
  }
}
