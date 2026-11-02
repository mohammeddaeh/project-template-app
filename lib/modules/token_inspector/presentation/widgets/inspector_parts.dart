import 'package:flutter/material.dart';

import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/domain/keycloak_checks.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// سطحُ بطاقةٍ بحدٍّ ملوَّن على البداية — لونُه حكمُ ما بداخله.
class InspectorSurface extends StatelessWidget {
  const InspectorSurface({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: s.size(4)),
            ),
          ),
          child: Padding(padding: EdgeInsets.all(s.space(12)), child: child),
        ),
      ),
    );
  }
}

class InspectorSectionTitle extends StatelessWidget {
  const InspectorSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.screen.space(8)),
    child: Text(text, style: context.textTheme.headlineMedium),
  );
}

class InspectorMuted extends StatelessWidget {
  const InspectorMuted(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    ),
  );
}

enum InspectorTone { plain, good, bad }

/// `Label: value` بعمودين — والقيمة تُلوَّن بما فيها.
class InspectorKeyValue extends StatelessWidget {
  const InspectorKeyValue(this.label, this.value, {this.tone, super.key});

  /// `Label: value` ⇒ صفٌّ بعمودين؛ وما سواه سطرٌ كامل.
  factory InspectorKeyValue.fromLine(String line) {
    final i = line.indexOf(': ');
    if (i <= 0) return InspectorKeyValue('', line);
    return InspectorKeyValue(line.substring(0, i), line.substring(i + 2));
  }

  final String label;
  final String value;
  final InspectorTone? tone;

  /// تغيّر/حُفظ ⇒ أخضر · فشل/انتهى ⇒ تحذير.
  InspectorTone get _resolved {
    final explicit = tone;
    if (explicit != null) return explicit;
    if (value.contains('✗') ||
        value.contains('EXPIRED') ||
        value.startsWith('none')) {
      return InspectorTone.bad;
    }
    if (value.contains('✓') || value.startsWith('CHANGED')) {
      return InspectorTone.good;
    }
    return InspectorTone.plain;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    final valueColor = switch (_resolved) {
      InspectorTone.good => context.colors.statusSuccessFg,
      InspectorTone.bad => context.colors.statusWarningFg,
      InspectorTone.plain => context.colors.textPrimary,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: s.space(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: s.size(110),
              child: Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ),
          Expanded(
            child: SelectableText(
              value,
              style: context.textTheme.bodySmall?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

Color inspectorKindColor(BuildContext context, InspectorEventKind kind) =>
    switch (kind) {
      InspectorEventKind.info => context.colors.primary,
      InspectorEventKind.success => context.colors.statusSuccessFg,
      InspectorEventKind.warning => context.colors.statusWarningFg,
      InspectorEventKind.error => context.colors.stateError,
    };

IconData inspectorKindIcon(InspectorEventKind kind) => switch (kind) {
  InspectorEventKind.info => Icons.info_outline,
  InspectorEventKind.success => Icons.check_circle_outline,
  InspectorEventKind.warning => Icons.wifi_off,
  InspectorEventKind.error => Icons.error_outline,
};

Color inspectorVerdictColor(BuildContext context, CheckVerdict verdict) =>
    switch (verdict) {
      CheckVerdict.pass => context.colors.statusSuccessFg,
      CheckVerdict.fail => context.colors.statusWarningFg,
      CheckVerdict.unknown => context.colors.textMuted,
      CheckVerdict.info => context.colors.primary,
    };

String inspectorVerdictMark(CheckVerdict verdict) => switch (verdict) {
  CheckVerdict.pass => '✓',
  CheckVerdict.fail => '✗',
  CheckVerdict.unknown => '?',
  CheckVerdict.info => 'i',
};
