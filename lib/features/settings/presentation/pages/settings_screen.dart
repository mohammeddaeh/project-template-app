import 'package:app_template/ui/theme/theme_switcher.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:app_template/modules/access_control/presentation/widgets/access_control_section.dart';
import 'package:app_template/modules/multi_device/presentation/widgets/devices_section.dart';
import 'package:app_template/modules/notification_center/presentation/widgets/notification_center_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_template/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_about_section.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_font_section.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_section_divider.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_theme_preset_section.dart';
import 'package:app_template/ui/locale/locale_switcher.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
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
          context.feedback.success(LocaleKeys.cacheClearedSuccessfully.tr());
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
    return ResponsiveContentBox(
      width: ContentWidth.content,
      horizontalPadding: false,
      child: ListView(
        children: const [
          _AppearanceSection(),
          SettingsSectionDivider(),
          SettingsFontSection(),
          SettingsSectionDivider(),
          _LanguageSection(),
          SettingsSectionDivider(),
          _NotificationsSection(),
          // Nothing when AppFeatures.notificationCenter is off.
          NotificationCenterSection(),
          SettingsSectionDivider(),
          // Renders nothing when AppFeatures.multiDevice is off — the module owns
          // that check, so this list never has to and the tile can never appear
          // without the dependencies behind it.
          DevicesSection(),
          // Same guarantee, same reason: nothing when AppFeatures.accessControl
          // is off, and hidden from an account without `roles.view` when it is on.
          AccessControlSection(),
          SettingsAboutSection(),
        ],
      ),
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
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(LocaleKeys.appearance.tr()),
        // **ودجةٌ واحدة للمبدِّل.** [ThemeSwitcher] هي المكتبة؛ كتلةُ `ListTile`
        // تُبنى هنا باليد نسخةٌ ثانية من قرارِ تصميمٍ واحد، تُشدَّد إحداهما يوماً
        // ولا تُشدَّد الأخرى (R34).
        const ThemeSwitcher(),
        // Nothing while AppThemePresets.all holds a single preset.
        const SettingsThemePresetSection(),
      ],
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
        SettingsSectionHeader(LocaleKeys.language.tr()),
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
        SettingsSectionHeader(LocaleKeys.notifications.tr()),
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
