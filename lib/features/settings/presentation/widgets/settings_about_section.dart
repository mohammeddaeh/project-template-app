import 'package:app_template/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// معلومات التطبيق: الإصدار، ومسح الذاكرة المؤقّتة.
class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(LocaleKeys.appInfo.tr()),
        BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (p, c) => p.appVersion != c.appVersion,
          builder: (context, state) => ListTile(
            title: Text(LocaleKeys.appVersion.tr()),
            trailing: Text(
              state.appVersion,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
        ),
        BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (p, c) => p.isClearingCache != c.isClearingCache,
          builder: (context, state) => ListTile(
            title: Text(LocaleKeys.clearCache.tr()),
            trailing: state.isClearingCache
                ? const AppProgress.circular(size: AppProgressSize.sm)
                : Icon(
                    Icons.delete_sweep_outlined,
                    color: context.colors.stateError,
                  ),
            onTap: state.isClearingCache
                ? null
                : () => context.read<SettingsCubit>().clearCache(),
          ),
        ),
      ],
    );
  }
}
