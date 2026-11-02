import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_template/modules/token_inspector/domain/token_reading.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/inspector_parts.dart';
import 'package:app_template/modules/token_inspector/token_inspector_config.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// «Session now» — يقرأ التخزين، ويعيد القراءة مع كل حدث، ويعدّ كل ثانية.
class LiveSessionCard extends StatefulWidget {
  const LiveSessionCard({required this.recorder, super.key});

  final InspectorRecorder recorder;

  @override
  State<LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<LiveSessionCard> {
  TokenReading? _access;
  TokenReading? _refresh;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    widget.recorder.events.addListener(_load);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.recorder.events.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final (access, refresh) = await widget.recorder.storedTokens();
    if (!mounted) return;
    setState(() {
      _access = TokenReading.of(access);
      _refresh = TokenReading.of(refresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = _access;
    final refresh = _refresh;
    if (access == null || refresh == null) {
      return const InspectorMuted('Reading device storage…');
    }
    final now = DateTime.now();
    final verdict = _verdict(context, access, refresh, now);
    final s = context.screen;
    return InspectorSurface(
      color: verdict.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VerdictLine(verdict),
          SizedBox(height: s.space(12)),
          _TokenMeter(
            label: 'Access token',
            hint: 'sent with every request',
            reading: access,
            expiredNote: 'renews on the next request (needs network)',
          ),
          if (TokenInspectorConfig.refreshTokenKey != null) ...[
            SizedBox(height: s.space(12)),
            _TokenMeter(
              label: 'Refresh token',
              hint: 'renews the access token',
              reading: refresh,
              expiredNote: 'dead — login required',
            ),
          ],
        ],
      ),
    );
  }

  _Verdict _verdict(
    BuildContext context,
    TokenReading access,
    TokenReading refresh,
    DateTime now,
  ) {
    final c = context.colors;
    if (!access.isPresent) {
      return _Verdict('No session', c.stateError, Icons.block);
    }
    if (TokenInspectorConfig.refreshTokenKey != null) {
      if (!refresh.isPresent) {
        return _Verdict(
          'Access only — no refresh token stored',
          c.statusWarningFg,
          Icons.warning_amber,
        );
      }
      if (refresh.isExpired(now)) {
        return _Verdict(
          'Refresh token expired — login required',
          c.stateError,
          Icons.error_outline,
        );
      }
      if (refresh.isOffline) {
        return _Verdict(
          'Offline ✓ — survives idle',
          c.statusSuccessFg,
          Icons.verified_user_outlined,
        );
      }
      if (refresh.type == 'Refresh') {
        return _Verdict(
          'Alive but NOT offline — dies when idle',
          c.statusWarningFg,
          Icons.warning_amber,
        );
      }
      return _Verdict('Session alive', c.statusSuccessFg, Icons.check);
    }
    if (access.format == TokenFormat.opaque) {
      return _Verdict(
        'Session token stored — its expiry is known to the server only',
        c.primary,
        Icons.key,
      );
    }
    if (access.isExpired(now)) {
      return _Verdict(
        'Access token expired — renews on the next request',
        c.statusWarningFg,
        Icons.hourglass_bottom,
      );
    }
    return _Verdict('Session alive', c.statusSuccessFg, Icons.check);
  }
}

class _Verdict {
  const _Verdict(this.title, this.color, this.icon);

  final String title;
  final Color color;
  final IconData icon;
}

class _VerdictLine extends StatelessWidget {
  const _VerdictLine(this.verdict);

  final _Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    return Row(
      children: [
        Icon(verdict.icon, color: verdict.color, size: s.size(22)),
        SizedBox(width: s.space(8)),
        Expanded(
          child: Text(
            verdict.title,
            style: context.textTheme.headlineSmall?.copyWith(
              color: verdict.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TokenMeter extends StatelessWidget {
  const _TokenMeter({
    required this.label,
    required this.hint,
    required this.reading,
    required this.expiredNote,
  });

  final String label;
  final String hint;
  final TokenReading reading;
  final String expiredNote;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    if (!reading.isPresent) {
      return InspectorKeyValue(label, 'none', tone: InspectorTone.bad);
    }
    if (reading.format == TokenFormat.opaque) {
      return InspectorKeyValue(
        label,
        'opaque · id ${reading.fingerprint} · $hint',
      );
    }

    final now = DateTime.now();
    final expired = reading.isExpired(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label · ${reading.type ?? 'JWT'}',
                style: context.textTheme.bodyMedium,
              ),
            ),
            Text(
              expired ? 'EXPIRED' : reading.leftLabel(now),
              style: context.textTheme.bodyMedium?.copyWith(
                color: expired
                    ? context.colors.statusWarningFg
                    : context.colors.statusSuccessFg,
              ),
            ),
          ],
        ),
        SizedBox(height: s.space(4)),
        AppProgress.linear(
          value: reading.fractionLeft(now) ?? (expired ? 0 : 1),
          tone: expired ? AppProgressTone.warning : AppProgressTone.success,
          size: AppProgressSize.sm,
        ),
        SizedBox(height: s.space(4)),
        InspectorMuted(
          expired
              ? '${reading.leftLabel(now)} · $expiredNote'
              : '$hint · life ${reading.lifeLabel()} · '
                    '${reading.expiresAt == null ? 'no exp' : 'exp ${clockLabel(reading.expiresAt!)}'} · '
                    'id ${reading.fingerprint}',
        ),
      ],
    );
  }
}
