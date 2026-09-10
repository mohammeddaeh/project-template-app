import 'package:get_it/get_it.dart';

import 'package:app_template/modules/in_app_updates/data/app_update_settings_api.dart';
import 'package:app_template/modules/in_app_updates/data/app_update_settings_store.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// ⛔ **هذا الملفُّ وحدَه يعرف أن `modules/sync/` موجود** — من هذا الموديول كلِّه.
///
/// ## لماذا يُحصَر هنا
///
/// `test/sync/deletion_contract_test.dart` يشهد على أن حذفَ موديول المزامنة
/// **حذفُ مجلَّدٍ لا بحثٌ بالشجرة**، ويسمح بشكلٍ واحدٍ من الانخراط: ملفٌّ
/// بـ`integration/` لا غير. فلو نادى `in_app_updates_module.dart` اسمَ `SyncRefreshTask`
/// بنفسه — ولو لمجرّد وسيطٍ نوعيّ — صار لموديولٍ اختياريٍّ **مدخلان** إلى آخر،
/// ومن حذف المزامنة يقع على خطأ تصريفٍ بملفٍّ لا يتوقّعه.
///
/// فالتسجيل يسكن هنا، و[InAppUpdatesModule] ينادي دالّةً لا يعرف ما تُسجِّل.
class AppUpdateSettingsRefreshTask implements SyncRefreshTask {
  const AppUpdateSettingsRefreshTask(this._api, this._store);

  final AppUpdateSettingsApi _api;
  final AppUpdateSettingsStore _store;

  @override
  String get name => 'app-update-settings';

  @override
  Future<void> refresh() async => _store.write(await _api.fetch());
}

/// يسجّل مهمّةَ التحديث بالـDI — **ولا يُنادى إلا والعلَمُ مُشعَل**.
///
/// و[instanceName] يأتي من المستدعي لأنه هو من يملك الاسم: `allOf` بالمحرّك
/// يجمع المسجَّلين بأسمائهم، واسمٌ يُكتب بموضعين يفترق بأحدهما يوماً.
void registerAppUpdateRefreshTask(GetIt di, {required String instanceName}) {
  if (di.isRegistered<SyncRefreshTask>(instanceName: instanceName)) return;
  di.registerLazySingleton<SyncRefreshTask>(
    () => AppUpdateSettingsRefreshTask(
      di<AppUpdateSettingsApi>(),
      di<AppUpdateSettingsStore>(),
    ),
    instanceName: instanceName,
  );
}
