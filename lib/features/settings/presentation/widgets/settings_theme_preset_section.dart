import 'package:app_template/features/settings/presentation/cubits/theme_preset_cubit.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/selection_haptic.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/theme/theme_reveal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// منتقي الثيم — كلُّ ثيمٍ بطاقةٌ ترسم التطبيقَ مصغَّراً بألوانه، بالوضع
/// المعروض الآن (فاتح أو داكن): خلفيةٌ وشريطٌ وبطاقةٌ بسطرَين وزرّ.
///
/// **لا يُرسم شيئاً ما دام `AppThemePresets.all` ثيماً واحداً**: مشروعٌ بهويةٍ
/// واحدة لا يرى خياراً لا معنى له. والبطاقاتُ صفٌّ يمرَّر أفقياً، فثيماتٌ كثيرة
/// لا تطيل الإعدادات.
class SettingsThemePresetSection extends StatelessWidget {
  const SettingsThemePresetSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppThemePresets.all.length < 2) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final s = context.screen;
    final brightness = Theme.of(context).brightness;
    return BlocBuilder<ThemePresetCubit, AppThemePreset>(
      builder: (context, current) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(LocaleKeys.themePreset.tr()),
          SizedBox(
            height: s.size(_PresetCard.height),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: s.gutter),
              itemCount: AppThemePresets.all.length,
              separatorBuilder: (_, _) => SizedBox(width: s.space(12)),
              itemBuilder: (_, i) {
                final preset = AppThemePresets.all[i];
                final isSelected = preset == current;
                return _PresetCard(
                  name: preset.nameKey.tr(),
                  colors: preset.colorsFor(brightness),
                  isSelected: isSelected,
                  // The reveal starts from the tapped card, not the section.
                  onTap: (card) {
                    if (isSelected) return;
                    selectionHaptic();
                    ThemeReveal.run(
                      card,
                      () => context.read<ThemePresetCubit>().setPreset(preset),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: s.space(12)),
        ],
      ),
    );
  }
}

/// A theme's card: the app in miniature, in [colors], and its name below.
class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.name,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  static const double width = 104;
  static const double height = 156;

  final String name;

  /// The preset's own colours — the miniature is drawn in these, while the
  /// frame and the name follow the theme in use, like the rest of the screen.
  final AppColors colors;
  final bool isSelected;

  /// Called with the card's own context — the reveal starts at its centre.
  final ValueSetter<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    final ui = context.colors;
    final motion = AppMotion.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onTap(context),
        child: SizedBox(
          width: s.size(width),
          child: Column(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: motion.fast,
                  curve: AppMotion.fastCurve,
                  padding: EdgeInsets.all(s.space(3)),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: isSelected ? ui.primary : ui.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _Miniature(colors: colors)),
                      if (isSelected)
                        // Bottom-start, on the page — not on the top bar, which
                        // can be the very colour of the check.
                        PositionedDirectional(
                          bottom: s.space(6),
                          start: s.space(6),
                          child: _Check(
                            color: ui.primary,
                            on: ui.textOnPrimary,
                            ring: ui.bgCard,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: s.space(6)),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: isSelected ? ui.primary : ui.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app drawn small: page, top bar, a card with a title and a line, and
/// the accent button — enough to tell one identity from another at a glance.
class _Miniature extends StatelessWidget {
  const _Miniature({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    return ClipRRect(
      borderRadius: AppRadius.smRadius,
      child: ColoredBox(
        color: colors.bgPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: s.size(18), color: colors.primary),
            Padding(
              padding: EdgeInsets.all(s.space(8)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Padding(
                  padding: EdgeInsets.all(s.space(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Line(color: colors.textPrimary, widthFactor: 0.8),
                      SizedBox(height: s.space(4)),
                      _Line(color: colors.textSecondary, widthFactor: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s.space(8)),
              child: Row(
                children: [
                  Expanded(child: _Tile(color: colors.bgCard)),
                  SizedBox(width: s.space(6)),
                  Expanded(child: _Tile(color: colors.bgCard)),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Padding(
                padding: EdgeInsets.all(s.space(8)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: SizedBox.square(dimension: s.size(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.fullRadius,
      ),
      child: SizedBox(height: context.screen.size(4)),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.smRadius),
    child: SizedBox(height: context.screen.size(24)),
  );
}

class _Check extends StatelessWidget {
  const _Check({required this.color, required this.on, required this.ring});

  final Color color;
  final Color on;

  /// Parts the check from whatever page colour it sits on.
  final Color ring;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: ring, width: 2),
    ),
    child: Padding(
      padding: EdgeInsets.all(context.screen.space(2)),
      child: Icon(Icons.check, size: context.screen.size(14), color: on),
    ),
  );
}
