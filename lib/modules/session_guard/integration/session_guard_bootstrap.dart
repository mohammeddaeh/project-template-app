import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/contracts/account_scoped_store.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/session_guard/data/session_guard_pin_store.dart';

/// يسجّل تبعيات الموديول. يُنادى مرّة من `SessionGuardPlugin.initialize`.
///
/// تسجيلٌ يدويّ لا `@injectable` — نفس سبب كل موديول هنا: مولِّد `injectable`
/// يمسح `lib/` كلّه، فصنفٌ موسومٌ يُوصَل بـ`injection.config.dart` سواء
/// كان علَمُه مُشعَلاً أم لا، وموديولاً يشحن مطفأً يجب ألّا يكلّف شيئاً.
///
/// **وتسجيلان لا واحد** لـ[SessionGuardPinStore] — نفس نمط `AccountScopedStore`
/// الموثَّق بالعقد نفسه: النسخةُ نفسُها تُحقَن بذاتها (لأن الشاشات تحتاج
/// `setPin`/`verify`/`hasPin` التي ليست بالعقد العام) وتحت واجهة
/// `AccountScopedStore` (ليمحوها `AccountDataCleaner` مع أي خروج).
void registerSessionGuard(GetIt di) {
  if (!di.isRegistered<SessionGuardPinStore>()) {
    di.registerLazySingleton<SessionGuardPinStore>(
      () => SessionGuardPinStore(di<SecureStorageService>()),
    );
  }

  if (!di.isRegistered<AccountScopedStore>(instanceName: 'sessionGuardPin')) {
    di.registerLazySingleton<AccountScopedStore>(
      () => di<SessionGuardPinStore>(),
      instanceName: 'sessionGuardPin',
    );
  }
}
