import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/features/settings/presentation/cubits/font_preference_cubit.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// منتقي الخطّ — كلُّ خطٍّ يُعرض باسمه وبخطِّه نفسِه.
class SettingsFontSection extends StatelessWidget {
  const SettingsFontSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return BlocBuilder<FontPreferenceCubit, AppFontOption>(
      builder: (context, current) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(LocaleKeys.typography.tr()),
            ...AppFonts.available.map((font) {
              final isSelected = font.key == current.key;
              return ListTile(
                title: Text(
                  font.labelFor(languageCode),
                  style: TextStyle(
                    fontFamily: font.familyFor(languageCode),
                    fontSize: 15,
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.textSecondary,
                  ),
                ),
                subtitle: font.arabicFamily != font.latinFamily
                    ? Text(
                        languageCode == 'ar'
                            ? font.latinLabel
                            : font.arabicLabel,
                        style: TextStyle(
                          fontFamily: languageCode == 'ar'
                              ? font.latinFamily
                              : font.arabicFamily,
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      )
                    : null,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.textSecondary,
                ),
                onTap: () => context.read<FontPreferenceCubit>().setFont(font),
              );
            }),
          ],
        );
      },
    );
  }
}
