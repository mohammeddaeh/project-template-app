import 'package:app_template/features/settings/presentation/cubits/theme_preset_cubit.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/selection_haptic.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/theme/theme_reveal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// منتقي الثيم — كلُّ ثيمٍ يُعرض باسمه وبلونَي هويته بالوضع المعروض الآن.
///
/// **لا يُرسم شيئاً ما دام `AppThemePresets.all` ثيماً واحداً**: مشروعٌ بهويةٍ
/// واحدة لا يرى خياراً لا معنى له.
class SettingsThemePresetSection extends StatelessWidget {
  const SettingsThemePresetSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppThemePresets.all.length < 2) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final brightness = Theme.of(context).brightness;
    return BlocBuilder<ThemePresetCubit, AppThemePreset>(
      builder: (context, current) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(LocaleKeys.themePreset.tr()),
            ...AppThemePresets.all.map((preset) {
              final isSelected = preset == current;
              final colors = preset.colorsFor(brightness);
              // Builder: the reveal starts from this tile, not the section.
              return Builder(
                builder: (tile) => ListTile(
                  title: Text(
                    preset.nameKey.tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textMuted,
                    ),
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.textMuted,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Swatch(colors.primary),
                      const SizedBox(width: 4),
                      _Swatch(colors.secondary),
                    ],
                  ),
                  onTap: () {
                    if (isSelected) return;
                    selectionHaptic();
                    ThemeReveal.run(
                      tile,
                      () => context.read<ThemePresetCubit>().setPreset(preset),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  static const _size = 20.0;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.fullRadius,
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: const SizedBox.square(dimension: _size),
    );
  }
}
