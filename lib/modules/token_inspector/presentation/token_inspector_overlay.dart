import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/presentation/token_inspector_panel.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/event_card.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/inspector_parts.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// زرٌّ عائم فوق كل الشاشات — يُسحب بالإصبع، بلون آخر حدث وعددِ الأحداث —
/// وضغطتُه تفتح الورقة. ويعرض toast عند الدخول والتجديد والرفض.
///
/// يُركَّب بـ`AppOverlays` من `TokenInspectorPlugin`، فلا يعرفه `app.dart`.
class TokenInspectorOverlay extends StatefulWidget {
  const TokenInspectorOverlay({
    required this.recorder,
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final InspectorRecorder recorder;

  /// الورقة والـtoast يحتاجان سياقاً تحت الـ`Navigator`، والطبقةُ فوقه.
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<TokenInspectorOverlay> createState() => _TokenInspectorOverlayState();
}

class _TokenInspectorOverlayState extends State<TokenInspectorOverlay> {
  Offset? _offset;
  StreamSubscription<String>? _notices;

  @override
  void initState() {
    super.initState();
    _notices = widget.recorder.notices.listen(_toast);
  }

  @override
  void dispose() {
    _notices?.cancel();
    super.dispose();
  }

  void _toast(String message) {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    ctx.feedback.toast(message);
  }

  void _open() {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    AppBottomSheet.show<void>(
      ctx,
      title: 'Token inspector',
      child: _InspectorSheet(recorder: widget.recorder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    final size = MediaQuery.sizeOf(context);
    final bubble = s.size(60);
    final offset = _offset ?? Offset(s.space(12), size.height - s.size(170));

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: GestureDetector(
            onTap: _open,
            onPanUpdate: (d) => setState(() {
              final next = offset + d.delta;
              _offset = Offset(
                next.dx.clamp(0, size.width - bubble),
                next.dy.clamp(0, size.height - bubble),
              );
            }),
            child: _Bubble(recorder: widget.recorder),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.recorder});

  final InspectorRecorder recorder;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    return ValueListenableBuilder<List<InspectorEvent>>(
      valueListenable: recorder.events,
      builder: (context, events, _) {
        final color = events.isEmpty
            ? context.colors.textMuted
            : inspectorKindColor(context, events.first.kind);
        return Material(
          color: context.colors.bgCard,
          elevation: 6,
          shape: StadiumBorder(side: BorderSide(color: color, width: 2)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: s.space(10),
              vertical: s.space(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key, size: s.size(16), color: color),
                SizedBox(width: s.space(4)),
                Text(
                  '${events.length}',
                  style: context.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InspectorSheet extends StatelessWidget {
  const _InspectorSheet({required this.recorder});

  final InspectorRecorder recorder;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TokenInspectorPanel(),
            SizedBox(height: s.space(20)),
            _HistoryHeader(recorder: recorder),
            SizedBox(height: s.space(8)),
            ValueListenableBuilder<List<InspectorEvent>>(
              valueListenable: recorder.events,
              builder: (context, events, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (events.isEmpty) const InspectorMuted('No events yet'),
                  for (final e in events) InspectorEventCard(e),
                ],
              ),
            ),
            SizedBox(height: s.space(16)),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.recorder});

  final InspectorRecorder recorder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'History — newest first',
            style: context.textTheme.headlineMedium,
          ),
        ),
        AppButton(
          text: 'Clear',
          variant: AppButtonVariant.text,
          size: AppButtonSize.small,
          leadingIcon: Icons.delete_outline,
          onTap: recorder.clear,
        ),
      ],
    );
  }
}
