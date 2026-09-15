import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/contracts/account_scoped_store.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/notification_center/data/notification_center_store.dart';
import 'package:app_template/modules/notification_center/presentation/cubits/notification_center_cubit.dart';
import 'package:app_template/modules/notification_center/services/notification_center_listener.dart';
import 'package:app_template/modules/push_notifications/push_notifications_service.dart';

/// يسجّل تبعيات الموديول، ويحمّل القائمة المخزَّنة، ويبدأ الاستماع إن كان
/// `PushNotificationsService` مسجَّلاً. يُنادى مرّة من
/// `NotificationCenterPlugin.initialize`.
///
/// تسجيلٌ يدويّ لا `@injectable` — نفس سبب كل موديول هنا: مولِّد `injectable`
/// يمسح `lib/` كلّه، فصنفٌ موسومٌ يُوصَل بـ`injection.config.dart` سواء كان
/// علَمُه مُشعَلاً أم لا، وموديولاً يشحن مطفأً يجب ألّا يكلّف شيئاً.
///
/// **وتسجيلان لا واحد** لـ[NotificationCenterStore] — نفس نمط
/// `AccountScopedStore` الموثَّق بالعقد نفسه: النسخةُ نفسُها تُحقَن بذاتها
/// (لأن الاستماع والقراءة يحتاجان `add`/`changes`/`items` التي ليست بالعقد
/// العام) وتحت واجهة `AccountScopedStore` (ليمحوها `AccountDataCleaner` مع
/// أي خروج).
Future<void> registerNotificationCenter(GetIt di) async {
  if (!di.isRegistered<NotificationCenterStore>()) {
    di.registerLazySingleton<NotificationCenterStore>(
      () => NotificationCenterStore(di<StorageService>()),
    );
  }

  if (!di.isRegistered<AccountScopedStore>(instanceName: 'notificationCenter')) {
    di.registerLazySingleton<AccountScopedStore>(
      () => di<NotificationCenterStore>(),
      instanceName: 'notificationCenter',
    );
  }

  await di<NotificationCenterStore>().load();

  if (!di.isRegistered<NotificationCenterCubit>()) {
    di.registerFactory<NotificationCenterCubit>(
      () => NotificationCenterCubit(di<NotificationCenterStore>()),
    );
  }

  // بلا `PushNotificationsService` لا مصدر إشعاراتٍ يُستمع إليه — الموديول
  // يبقى مسجَّلاً (القائمة المخزَّنة سلفاً تبقى مقروءة) لكن لن يزيد عليها شيء
  // أبداً. `AppFeatures.notificationCenter` يوثّق هذا صراحةً.
  if (!di.isRegistered<PushNotificationsService>()) {
    LogService.warning(
      'NotificationCenterPlugin enabled without PushNotificationsService — '
      'nothing will ever be added to the list. Enable AppFeatures.pushNotifications too.',
      tag: 'NOTIFICATION_CENTER',
    );
    return;
  }

  if (!di.isRegistered<NotificationCenterListener>()) {
    di.registerLazySingleton<NotificationCenterListener>(
      () => NotificationCenterListener(
        di<NotificationCenterStore>(),
        di<PushNotificationsService>(),
      ),
    );
  }
  di<NotificationCenterListener>().start();
}
