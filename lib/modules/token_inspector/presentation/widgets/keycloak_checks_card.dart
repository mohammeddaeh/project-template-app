import 'package:flutter/material.dart';

import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/keycloak_checks.dart';
import 'package:app_template/modules/token_inspector/integration/inspector_recorder.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/inspector_parts.dart';
import 'package:app_template/modules/token_inspector/token_inspector_config.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// «Keycloak checks» — تُحسب من آخر ردٍّ لنقطة الاعتماد، وتُعاد مع كل ردّ.
///
/// **لا تُرسم إلا حين يأتي التوكن من Keycloak** (`iss` بمسار `/realms/`): مع
/// توكنٍ معتم لا شيء من هذه الإعدادات يُرى أصلاً.
class KeycloakChecksCard extends StatelessWidget {
  const KeycloakChecksCard({required this.recorder, super.key});

  final InspectorRecorder recorder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GrantFacts?>(
      valueListenable: recorder.facts,
      builder: (context, facts, _) {
        if (facts == null || !facts.keycloak) return const SizedBox.shrink();
        const expect = TokenInspectorConfig.expectations;
        final checks = keycloakChecks(facts, expect);
        final missing = expect.missingKeys;
        final s = context.screen;
        return Padding(
          padding: EdgeInsets.only(top: s.space(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InspectorSectionTitle('Keycloak checks'),
              // `i` بلا هذا السطر يُقرأ «لا مشكلة» — وهو «لم يُقَل ما المتوقَّع».
              if (missing.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: s.space(8)),
                  child: InspectorMuted(
                    'No verdict without an expected value — add to '
                    '.env.<flavor>.json: ${missing.join(' · ')}',
                  ),
                ),
              for (final check in checks)
                Padding(
                  padding: EdgeInsets.only(bottom: s.space(8)),
                  child: _CheckTile(check),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile(this.check);

  final InspectorCheck check;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    final color = inspectorVerdictColor(context, check.verdict);
    return InspectorSurface(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                inspectorVerdictMark(check.verdict),
                style: context.textTheme.headlineSmall?.copyWith(color: color),
              ),
              SizedBox(width: s.space(8)),
              Expanded(
                child: Text(check.name, style: context.textTheme.headlineSmall),
              ),
            ],
          ),
          SizedBox(height: s.space(4)),
          InspectorKeyValue('Observed', check.observed),
          if (check.fix != null) InspectorKeyValue('Fix in', check.fix!),
        ],
      ),
    );
  }
}
