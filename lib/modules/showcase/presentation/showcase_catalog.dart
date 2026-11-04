import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/pages/data/api_simulator_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/data/crud_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/data/failures_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/data/pagination_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/audio_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/ink_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/scan_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/system_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/video_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/voice_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/foundations/colors_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/foundations/formats_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/foundations/screen_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/foundations/spacing_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/foundations/typography_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/access_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/auth_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/data_transfer_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/devices_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/notifications_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/session_guard_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sync_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/token_inspector_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/updates_sim_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/motion/back_guard_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/motion/motion_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/platform/connectivity_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/platform/flags_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/platform/haptics_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/platform/services_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/platform/theme_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/buttons_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/dialogs_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/display_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/feedback_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/inputs_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/media_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/navigation_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/states_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/foundations/tools_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/gestures_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/data/cubits_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/platform/storage_demo.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/bottom_bar_demo.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The tour's chapters, in the order the home tab shows them.
enum ShowcaseGroup {
  foundations(LocaleKeys.showcaseGroupFoundations, Icons.architecture),
  widgets(LocaleKeys.showcaseGroupWidgets, Icons.widgets_outlined),
  motion(LocaleKeys.showcaseGroupMotion, Icons.animation),
  data(LocaleKeys.showcaseGroupData, Icons.storage_outlined),
  modules(LocaleKeys.showcaseGroupModules, Icons.extension_outlined),
  platform(LocaleKeys.showcaseGroupPlatform, Icons.phone_android),
  devices(LocaleKeys.showcaseGroupDevices, Icons.settings_input_component);

  const ShowcaseGroup(this.titleKey, this.icon);

  final String titleKey;
  final IconData icon;

  List<ShowcasePage> get pages =>
      ShowcaseCatalog.pages.where((p) => p.group == this).toList();
}

/// One page of the tour.
class ShowcasePage {
  const ShowcasePage(
    this.group,
    this.titleKey,
    this.icon,
    this.body, {
    this.ownsScroll = false,
  });

  final ShowcaseGroup group;
  final String titleKey;
  final IconData icon;

  /// The demo itself — a widget that lays out its examples top to bottom.
  final Widget Function({Key? key}) body;

  /// The demo scrolls by itself (a list that pages, a queue) — it fills the
  /// screen instead of sitting in the page's scroll view.
  final bool ownsScroll;
}

/// **Every page of the tour** — a new page is one line here and one file
/// under `pages/<group>/`.
abstract final class ShowcaseCatalog {
  static final List<ShowcasePage> pages = [
    ShowcasePage(
      ShowcaseGroup.foundations,
      LocaleKeys.showcaseColors,
      Icons.palette_outlined,
      ColorsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.foundations,
      LocaleKeys.showcaseTypography,
      Icons.text_fields,
      TypographyDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.foundations,
      LocaleKeys.showcaseSpacing,
      Icons.space_bar,
      SpacingDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.foundations,
      LocaleKeys.showcaseScreen,
      Icons.devices_outlined,
      ScreenDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.foundations,
      LocaleKeys.showcaseFormats,
      Icons.calendar_month_outlined,
      FormatsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.foundations,
      LocaleKeys.showcaseTools,
      Icons.build_outlined,
      ToolsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseButtons,
      Icons.smart_button_outlined,
      ButtonsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseInputs,
      Icons.edit_note_outlined,
      InputsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseDisplay,
      Icons.view_agenda_outlined,
      DisplayDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseGestures,
      Icons.swipe,
      GesturesDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseMedia,
      Icons.image_outlined,
      MediaDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseNavigation,
      Icons.tab_outlined,
      NavigationDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseBottomBar,
      Icons.space_dashboard_outlined,
      BottomBarDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseDialogs,
      Icons.web_asset_outlined,
      DialogsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseFeedback,
      Icons.notifications_none_outlined,
      FeedbackDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.widgets,
      LocaleKeys.showcaseStates,
      Icons.inbox_outlined,
      StatesDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.motion,
      LocaleKeys.showcaseMotion,
      Icons.animation_outlined,
      MotionDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.motion,
      LocaleKeys.showcaseBackGuard,
      Icons.undo_outlined,
      BackGuardDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.data,
      LocaleKeys.showcasePagination,
      Icons.format_list_numbered,
      PaginationDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.data,
      LocaleKeys.showcaseCubits,
      Icons.account_tree_outlined,
      CubitsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.data,
      LocaleKeys.showcaseCrud,
      Icons.edit_outlined,
      CrudDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.data,
      LocaleKeys.showcaseFailures,
      Icons.error_outline,
      FailuresDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.data,
      LocaleKeys.showcaseApiSimulator,
      Icons.swap_vert,
      ApiSimulatorDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseAuthSim,
      Icons.login,
      AuthSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseDataTransferSim,
      Icons.import_export,
      DataTransferSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseAccessSim,
      Icons.admin_panel_settings_outlined,
      AccessSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseSyncSim,
      Icons.sync,
      SyncSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseDevicesSim,
      Icons.devices_outlined,
      DevicesSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseGuardSim,
      Icons.lock_outline,
      SessionGuardSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseNotifSim,
      Icons.notifications_outlined,
      NotificationsSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseUpdatesSim,
      Icons.system_update_outlined,
      UpdatesSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.modules,
      LocaleKeys.showcaseInspectorSim,
      Icons.key_outlined,
      TokenInspectorSimDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.platform,
      LocaleKeys.showcaseHaptics,
      Icons.vibration,
      HapticsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.platform,
      LocaleKeys.showcaseServices,
      Icons.ios_share,
      ServicesDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.platform,
      LocaleKeys.showcaseConnectivity,
      Icons.wifi,
      ConnectivityDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.platform,
      LocaleKeys.showcaseFlags,
      Icons.flag_outlined,
      FlagsDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.platform,
      LocaleKeys.showcaseStorage,
      Icons.sd_storage_outlined,
      StorageDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.devices,
      LocaleKeys.showcaseVoice,
      Icons.record_voice_over_outlined,
      VoiceDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.devices,
      LocaleKeys.showcaseAudio,
      Icons.graphic_eq,
      AudioDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.devices,
      LocaleKeys.showcaseScan,
      Icons.qr_code_scanner,
      ScanDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.devices,
      LocaleKeys.showcaseVideo,
      Icons.smart_display_outlined,
      VideoDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.devices,
      LocaleKeys.showcaseSystem,
      Icons.app_shortcut,
      SystemDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.devices,
      LocaleKeys.showcaseInk,
      Icons.gesture,
      InkDemo.new,
    ),
    ShowcasePage(
      ShowcaseGroup.platform,
      LocaleKeys.showcaseTheme,
      Icons.palette_outlined,
      ThemeDemo.new,
    ),
  ];
}

/// One page of the tour, opened from its card on the home tab.
class ShowcasePageScreen extends StatelessWidget {
  const ShowcasePageScreen({required this.page, super.key});

  final ShowcasePage page;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(page.titleKey.tr())),
      body: ResponsiveContentBox(
        child: page.ownsScroll
            ? page.body()
            : ListView(
                padding: EdgeInsets.symmetric(
                  vertical: context.screen.space(16),
                ),
                children: [page.body()],
              ),
      ),
    );
  }
}
