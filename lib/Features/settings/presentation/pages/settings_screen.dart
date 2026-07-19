import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_template/Features/settings/presentation/cubits/font_preference_cubit.dart';
import 'package:app_template/Features/settings/presentation/cubits/settings_cubit.dart';
import 'package:app_template/Features/settings/presentation/cubits/settings_state.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/presentation/locale/locale_switcher.dart';
import 'package:app_template/presentation/theme/app_theme_mode.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage(name: 'SettingsRoute')
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit()..init(),
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) =>
            prev.isClearingCache && !curr.isClearingCache,
        listener: (context, _) {
          // مسح الـ image cache عند انتهاء العملية
          PaintingBinding.instance.imageCache.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocaleKeys.cacheClearedSuccessfully.tr())),
          );
        },
        child: Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.settings.tr())),
          body: const _SettingsBody(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _AppearanceSection(),
        _SectionDivider(),
        _FontSection(),
        _SectionDivider(),
        _LanguageSection(),
        _SectionDivider(),
        _NotificationsSection(),
        _SectionDivider(),
        _AboutSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appearance — theme selector
// ─────────────────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    final current = AdaptiveTheme.of(context).mode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(LocaleKeys.appearance.tr()),
        ...[
          (AdaptiveThemeMode.light, LocaleKeys.themeLight.tr()),
          (AdaptiveThemeMode.dark, LocaleKeys.themeDark.tr()),
          (AdaptiveThemeMode.system, LocaleKeys.themeSystem.tr()),
        ].map((entry) {
          final (mode, label) = entry;
          final isSelected = current == mode;
          return ListTile(
            title: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.textMuted,
              ),
            ),
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? context.colors.primary
                  : context.colors.textMuted,
            ),
            onTap: () => context.setThemeMode(mode),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font picker
// ─────────────────────────────────────────────────────────────────────────────

class _FontSection extends StatelessWidget {
  const _FontSection();

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return BlocBuilder<FontPreferenceCubit, AppFontOption>(
      builder: (context, current) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(LocaleKeys.typography.tr()),
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
                        : context.colors.textMuted,
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
                          color: context.colors.textMuted,
                        ),
                      )
                    : null,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.textMuted,
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

// ─────────────────────────────────────────────────────────────────────────────
// Language
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(LocaleKeys.language.tr()),
        const LocaleSwitcher.tile(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(LocaleKeys.notifications.tr()),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => SwitchListTile.adaptive(
            title: Text(LocaleKeys.enableNotifications.tr()),
            value: state.notificationsEnabled,
            onChanged: (_) =>
                context.read<SettingsCubit>().toggleNotifications(),
            activeTrackColor: context.colors.primary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About
// ─────────────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(LocaleKeys.appInfo.tr()),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.dividerSubtle,
    );
  }
}
