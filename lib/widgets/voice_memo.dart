import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/haptics.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────
//  Hold-to-record mic button.
//
//  Tap-and-hold to start recording; release to finish and fire
//  [onRecorded] with the local file path + duration. If the user
//  drags >60px up during the hold, the recording is cancelled
//  (iMessage-style "slide to cancel"). Max duration 90s.
// ─────────────────────────────────────────────────────────────

class HoldToRecordMic extends StatefulWidget {
  const HoldToRecordMic({super.key, required this.onRecorded, this.enabled = true});
  final Future<void> Function(String filePath, Duration duration) onRecorded;
  final bool enabled;

  @override
  State<HoldToRecordMic> createState() => _HoldToRecordMicState();
}

class _HoldToRecordMicState extends State<HoldToRecordMic> {
  final _rec = AudioRecorder();
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  bool _cancelling = false;

  static const _maxDuration = Duration(seconds: 90);
  static const _cancelThreshold = 60.0;

  @override
  void dispose() {
    _ticker?.cancel();
    _rec.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!widget.enabled || _recording) return;
    if (!await _rec.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('mic permission needed for voice memos',
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );
    TSHaptics.medium();
    setState(() {
      _recording = true;
      _cancelling = false;
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _startedAt == null) return;
      final dt = DateTime.now().difference(_startedAt!);
      setState(() => _elapsed = dt);
      if (dt >= _maxDuration) _finish();
    });
  }

  Future<void> _finish() async {
    if (!_recording) return;
    _ticker?.cancel();
    _ticker = null;
    final path = await _rec.stop();
    final cancelled = _cancelling || _elapsed < const Duration(milliseconds: 400);
    setState(() {
      _recording = false;
      _cancelling = false;
    });
    if (path == null) return;
    if (cancelled) {
      try { await File(path).delete(); } catch (_) {}
      TSHaptics.light();
      return;
    }
    TSHaptics.ctaCommit();
    await widget.onRecorded(path, _elapsed);
  }

  void _cancelDrag(double dy) {
    final up = -dy;
    if (up <= 0) return;
    final willCancel = up > _cancelThreshold;
    if (willCancel != _cancelling) {
      TSHaptics.light();
      setState(() => _cancelling = willCancel);
    }
  }

  Future<void> _tapHint() async {
    // Short tap: prime the permission prompt and hint the gesture.
    TSHaptics.light();
    final ok = await _rec.hasPermission();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'hold the mic to record' : 'mic permission needed',
          style: TSTextStyles.body(color: TSColors.bg, size: 13),
        ),
        backgroundColor: ok ? TSColors.lime : TSColors.coral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tapHint,
      onLongPressStart: (_) => _start(),
      onLongPressMoveUpdate: (d) => _cancelDrag(d.localOffsetFromOrigin.dy),
      onLongPressEnd: (_) => _finish(),
      onLongPressCancel: () {
        _cancelling = true;
        _finish();
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _recording ? 44 : 40,
          height: _recording ? 44 : 40,
          decoration: BoxDecoration(
            color: _recording
                ? (_cancelling ? TSColors.coral : TSColors.lime)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            _cancelling ? Icons.delete_outline_rounded : Icons.mic_rounded,
            color: _recording ? TSColors.bg : TSColors.lime,
            size: _recording ? 22 : 22,
          ),
        ),
        if (_recording)
          Positioned(
            right: 48,
            top: 8,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: TSColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(_fmt(_elapsed),
                  style: TSTextStyles.label(
                      color: _cancelling ? TSColors.coral : TSColors.text2,
                      size: 11)),
              const SizedBox(width: 8),
              Text(
                _cancelling ? 'release to cancel' : 'slide up to cancel',
                style: TSTextStyles.label(color: TSColors.muted, size: 10),
              ),
            ]),
          ),
      ]),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─────────────────────────────────────────────────────────────
//  Inline voice memo player — single bubble control. Lazy-loads
//  the audio on first tap, then streams.
// ─────────────────────────────────────────────────────────────

class VoiceMemoPlayer extends StatefulWidget {
  const VoiceMemoPlayer({
    super.key,
    required this.url,
    required this.durationMs,
    required this.onBubble,
  });
  final String url;
  final int? durationMs;
  final bool onBubble;

  @override
  State<VoiceMemoPlayer> createState() => _VoiceMemoPlayerState();
}

class _VoiceMemoPlayerState extends State<VoiceMemoPlayer> {
  late final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    if (widget.durationMs != null) {
      _duration = Duration(milliseconds: widget.durationMs!);
    }
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
      if (s == PlayerState.completed) {
        setState(() => _position = Duration.zero);
      }
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    TSHaptics.light();
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.onBubble ? TSColors.bg : TSColors.lime;
    final bg = widget.onBubble
        ? TSColors.bg.withValues(alpha: 0.15)
        : TSColors.s3;
    final dur = _duration ?? Duration.zero;
    final progress = dur.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / dur.inMilliseconds)
            .clamp(0.0, 1.0);
    final shown = _playing ? _position : dur;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.onBubble ? TSColors.lime : TSColors.bg,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: c.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(_fmt(shown),
                    style: TSTextStyles.label(color: fg, size: 10)),
              ],
            );
          }),
        ),
      ]),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
