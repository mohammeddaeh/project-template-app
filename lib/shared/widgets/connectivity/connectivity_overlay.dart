import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/presentation/shared/connectivity/connectivity_cubit.dart';

import 'offline_banner.dart';
import 'reconnect_countdown_chip.dart';
import 'subtle_offline_dot.dart';

// ─── phase ────────────────────────────────────────────────────────────────────
enum _OfflinePhase { online, subtle, banner }

/// Overlay شفاف يُركَّب فوق التطبيق ليعرض حالة الاتصال تلقائياً.
///
/// ```dart
/// // في app.dart داخل Stack الجذر
/// Stack(
///   children: [
///     MaterialApp.router(...),
///     const ConnectivityOverlay(),
///   ],
/// )
/// ```
///
/// يتدرج في العرض:
/// - 0s انقطاع   → لا شيء
/// - 1.5s انقطاع → [SubtleOfflineDot] (نقطة خفية)
/// - 5.5s انقطاع → [OfflineBanner] + [ReconnectCountdownChip] (30s عداد)
/// - عودة الاتصال → يُخفى فوراً
class ConnectivityOverlay extends StatefulWidget {
  const ConnectivityOverlay({super.key});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  _OfflinePhase _phase = _OfflinePhase.online;
  int _countdown = 0;

  Timer? _subtleTimer;
  Timer? _bannerTimer;
  Timer? _countdownTimer;

  static const _subtleDelay   = Duration(milliseconds: 1500);
  static const _bannerDelay   = Duration(seconds: 4);
  static const _countdownFrom = 30;

  // ── الانتقال إلى وضع offline ──────────────────────────────────────────────

  void _onOffline() {
    _cancelTimers();

    // المرحلة الأولى: نقطة خفية بعد 1.5 ثانية
    _subtleTimer = Timer(_subtleDelay, () {
      if (!mounted) return;
      setState(() => _phase = _OfflinePhase.subtle);

      // المرحلة الثانية: banner بعد 4 ثوان إضافية
      _bannerTimer = Timer(_bannerDelay, () {
        if (!mounted) return;
        setState(() {
          _phase    = _OfflinePhase.banner;
          _countdown = _countdownFrom;
        });
        _startCountdown();
      });
    });
  }

  // ── عودة الاتصال ──────────────────────────────────────────────────────────

  void _onOnline() {
    _cancelTimers();
    if (mounted) setState(() => _phase = _OfflinePhase.online);
  }

  // ── عداد إعادة المحاولة ───────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdown <= 1) {
        _countdownTimer?.cancel();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown--);
    });
  }

  void _cancelTimers() {
    _subtleTimer?.cancel();
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, NetworkState>(
      listener: (_, state) {
        if (state.isOffline) _onOffline();
        if (state.isOnline)  _onOnline();
      },
      // IgnorePointer: الـ overlay لا يحجب اللمس
      child: IgnorePointer(
        child: Stack(
          children: [
            // مؤشر المرحلة الحالية
            switch (_phase) {
              _OfflinePhase.online => const SizedBox.shrink(),
              _OfflinePhase.subtle => const SubtleOfflineDot(),
              _OfflinePhase.banner => const OfflineBanner(),
            },
            // عداد إعادة المحاولة — يظهر فقط مع banner وعند وجود عداد
            if (_phase == _OfflinePhase.banner && _countdown > 0)
              ReconnectCountdownChip(seconds: _countdown),
          ],
        ),
      ),
    );
  }
}
