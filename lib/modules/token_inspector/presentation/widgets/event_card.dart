import 'package:flutter/material.dart';

import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';
import 'package:app_template/modules/token_inspector/domain/token_reading.dart';
import 'package:app_template/modules/token_inspector/presentation/widgets/inspector_parts.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// بطاقةُ حدثٍ بالسجلّ: أيقونةٌ ولونٌ بالمعنى، ووقتٌ مع «منذ كم»، وتفاصيل بعمودين.
class InspectorEventCard extends StatelessWidget {
  const InspectorEventCard(this.event, {super.key});

  final InspectorEvent event;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    final color = inspectorKindColor(context, event.kind);
    return Padding(
      padding: EdgeInsets.only(bottom: s.space(10)),
      child: InspectorSurface(
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  inspectorKindIcon(event.kind),
                  color: color,
                  size: s.size(20),
                ),
                SizedBox(width: s.space(8)),
                Expanded(
                  child: Text(
                    event.title,
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: color,
                    ),
                  ),
                ),
                SizedBox(width: s.space(8)),
                InspectorMuted(_when(event.at)),
              ],
            ),
            if (event.details.isNotEmpty) SizedBox(height: s.space(8)),
            for (final line in event.details) InspectorKeyValue.fromLine(line),
          ],
        ),
      ),
    );
  }

  static String _when(DateTime at) {
    final ago = DateTime.now().difference(at).inSeconds;
    return '${clockLabel(at)}\n${readableDuration(ago)} ago';
  }
}
