// ═══════════════════════════════════════════════════════════════════════════════
//  Widget library — تصدير مركزي لمكتبة الويدجتات
//  التوثيق الكامل: readme/widgets_usage.md
// ═══════════════════════════════════════════════════════════════════════════════

// ── States ────────────────────────────────────────────────────────────────────
// الويدجت الموحَّد (الأساسي — استخدمه في الكود الجديد)
export 'states/app_state_widget.dart';

// Aliases للتوافق مع الكود القديم — تُفوِّض الجميع لـ AppStateWidget
export 'states/empty_state_widget.dart';
export 'states/error_state_widget.dart';
export 'states/loading_widget.dart';
export 'states/no_internet_widget.dart';
export 'states/maintenance_widget.dart';
export 'states/retry_widget.dart';

// Placeholders
export 'placeholders/shimmer_loading_widget.dart';
export 'placeholders/skeleton_widget.dart';
export 'placeholders/skeleton_templates.dart';
export 'placeholders/image_placeholder_widget.dart';

// ── Inline Feedback States ─────────────────────────────────────────────────────
// ملاحظة: هذه inline widgets (داخل الصفحة) — ليست toasts.
// للـ toasts استخدم context.feedback.* من presentation/feedback/
// Aliases تُفوِّض لـ AppStateWidget
export 'feedback/success_state_widget.dart';
export 'feedback/warning_state_widget.dart';
export 'feedback/info_state_widget.dart';

// Images
export 'images/app_asset_image.dart';
export 'images/network_image_widget.dart';
export 'images/cached_image_widget.dart';
export 'images/svg_image_widget.dart';
export 'images/avatar_widget.dart';

// Layout
export 'layout/app_nav_bar.dart';
export 'layout/key_value_row.dart';
export 'layout/app_list_tile.dart';
export 'layout/expandable_section.dart';
export 'layout/stat_card.dart';
export 'layout/section_title.dart';
export 'layout/app_card.dart';
export 'layout/divider_widget.dart';
export 'layout/dashed_divider.dart';
export 'layout/spacing.dart';
export 'layout/app_button.dart';
export 'layout/primary_button.dart';

// Lists
export 'lists/pagination_builder_wdg.dart';
export 'lists/paginated_list_view.dart';
export 'lists/load_more_widget.dart';
export 'lists/refresh_wrapper.dart';

// Indicators
export 'indicators/app_loader.dart';
export 'indicators/progress_indicator_widget.dart';
export 'indicators/step_progress_indicator.dart';
export 'indicators/page_loading_indicator.dart';

// Wrappers
export 'wrappers/keyboard_dismiss_widget.dart';
export 'wrappers/safe_area_wrapper.dart';

// Inputs
export 'inputs/custom_text_field.dart';
export 'inputs/app_search_bar.dart';
export 'inputs/app_select_field.dart';
export 'inputs/chip_row.dart';

// Navigation
export 'navigation/app_tab_bar.dart';
export 'navigation/nav_item.dart';

// Dialogs
export 'dialogs/app_confirm_dialog.dart';
export 'dialogs/app_bottom_sheet.dart';
export 'dialogs/app_filter_sheet.dart';

// Connectivity
export 'connectivity/offline_banner.dart';
export 'connectivity/subtle_offline_dot.dart';
export 'connectivity/reconnect_countdown_chip.dart';
export 'connectivity/connectivity_overlay.dart';
export 'connectivity/sync_progress_overlay.dart';

// Misc
export 'misc/app_text.dart';
export 'misc/app_label.dart';
export 'misc/badge_widget.dart';
export 'misc/chip_widget.dart';
export 'misc/tag_widget.dart';
