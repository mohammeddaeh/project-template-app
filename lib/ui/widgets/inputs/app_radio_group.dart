import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  AppRadioGroup — قائمة اختيارٍ واحد، صفٌّ لكل خيار
/// ═══════════════════════════════════════════════════════════════════════════
///
/// ## متى هذه لا البطاقات المبسوطة
///
/// البطاقات المتجاورة تعمل حتى ثلاثة خيارات نصُّها كلمة أو كلمتان. وما زاد على
/// ذلك — أو نصُّه جملة — يُقصّ بـ`ellipsis` أو يهرب لسطرين متفاوتَي الارتفاع.
/// هذه تُنزل كل خيارٍ صفّاً كامل العرض: النصّ يُقرأ كاملاً، والدائرة تقول
/// «واحدٌ لا غير» قبل أن يقرأ المستخدم خياراً واحداً.
///
/// وهي **الشكل نفسه بأكثر من موضع** — لذا تسكن هنا لا بشريحةٍ بعينها: أي شاشة
/// تحتاج «اختر واحداً من قائمةٍ نصُّها طويل» تستدعيها بلا نسخ.
///
/// ```dart
/// AppRadioGroup<String>(
///   options: {
///     'ownership': LocaleKeys.unitCourtOwnership.tr(),
///     'eviction':  LocaleKeys.unitCourtEviction.tr(),
///   },
///   value: selected,
///   onChanged: (v) => cubit.select(v),
///   footnote: LocaleKeys.unitCourtTypesPending.tr(),
/// )
/// ```
///
/// ## ما تتكفّل به
///
/// 1. **الاتجاه**: الدائرة بجهة **البداية** — يميناً بالعربية ويساراً
///    بالإنجليزية — بلا سطرٍ إضافيّ بموضع الاستدعاء.
/// 2. **الثيم**: كل لونٍ من `context.colors`، فالفاتح والداكن يتبدّلان وحدهما.
/// 3. **الانتقال**: تغيّر الاختيار يُحرَّك ([AnimatedContainer]) بدل أن يقفز.
/// 4. **الدلالة**: كل صفّ `inMutuallyExclusiveGroup`، فقارئ الشاشة ينطقها
///    «خيارٌ ضمن مجموعة» لا «زرّاً» ستّ مرات.
/// 5. **إلغاء التحديد** ([onDeselect]): نقرةٌ ثانية على المختار تمحوه.
///    **اختياريّ لا افتراضيّ** — القائمة التي لا تُمرَّر إليها تبقى كما كانت:
///    لا مخرج من الاختيار إلا باختيارٍ آخر. وبلا هذا يبقى جوابُ سؤالٍ غير
///    إلزاميّ **لا يُمحى أبداً** بعد أول لمسة: لا زرّ مسحٍ بالحقل ولا خيار «لا
///    شيء» بالقائمة.
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    required this.options,
    required this.value,
    required this.onChanged,
    this.onDeselect,
    this.descriptions = const {},
    this.enabled = true,
    this.footnote,
    this.spacing = 8,
    super.key,
  });

  /// الخيارات بترتيب العرض — `Map` بلغة Dart يحفظ ترتيب الإدراج.
  final Map<T, String> options;

  /// المختار، أو `null` قبل أي اختيار.
  final T? value;

  final ValueChanged<T> onChanged;

  /// نقرةٌ على الخيار **المختار أصلاً** — حين تُمرَّر تُقرأ إلغاءً للتحديد.
  ///
  /// `null` ⇒ إعادة النقر لا تفعل شيئاً، وهو السلوك الافتراضيّ.
  final VoidCallback? onDeselect;

  /// سطرٌ ثانٍ تحت عنوان الخيار — للخيار الذي لا يكفيه اسمه.
  final Map<T, String> descriptions;

  final bool enabled;

  /// سطرٌ تحت القائمة كلها — تحفّظٌ أو مصدرٌ أو حالة اعتماد.
  final String? footnote;

  /// الفراغ بين الصفوف.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) SizedBox(height: spacing),
          _RadioRow<T>(
            label: entries[index].value,
            description: descriptions[entries[index].key],
            selected: entries[index].key == value,
            enabled: enabled,
            onTap: entries[index].key == value && onDeselect != null
                ? onDeselect!
                : () => onChanged(entries[index].key),
          ),
        ],
        if (footnote case final note?) ...[
          SizedBox(height: spacing + 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              note,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  static const _radius = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // الاختيار يُقرأ من الدائرة والحدّ ولمسةٍ من لون العلامة بالخلفية — لا من
    // صفٍّ مصمَتٍ بالأخضر: ستّة صفوف أحدها مطليّ بالكامل تُثقل القائمة، والدائرة
    // وحدها كافية للإجابة عن «أيّها المختار».
    final border = selected ? colors.primary : colors.borderSubtle;
    final background = selected
        ? colors.primary.withValues(alpha: .06)
        : colors.bgCard;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: border, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? colors.primary : colors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? colors.textPrimary
                              : colors.textMuted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (description case final text?) ...[
                        const SizedBox(height: 2),
                        Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
