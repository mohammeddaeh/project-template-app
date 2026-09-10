import 'package:injectable/injectable.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/contracts/account_scoped_store.dart';
import 'package:app_template/core/foundation/di/get_it_all_extension.dart';
import 'package:app_template/core/foundation/contracts/local_data_wiper.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// **المكانُ الواحد الذي يُنهي وجود حسابٍ على هذا الجهاز.**
///
/// ## لماذا خدمةٌ لا سطران بكل مستدعٍ
///
/// ما يخصّ الحساب موزَّعٌ بثلاثة أماكن: جداولُ الموديول، وبايتاتُ التخزين
/// الخاص، ولقطاتٌ نصّية بـ`StorageService`. ومن يمحو واحداً وينسى الآخرين لا
/// يقع بخطأٍ يُرى — يقع بجهازٍ **يبدو نظيفاً** ويحمل بيانات غيره.
///
/// واللقطات أخبثُها: `accountOverviewSnapshot` تُعرض بتبويب «حسابي» **بلا
/// شبكة**، فيرى الداخلُ الجديد دورَ سلفه ومحافظتَه وسلسلة مستلميه — قبل أن يصل
/// أي طلب.
///
/// ## متى تُنادى، ومتى لا
///
/// | الحدث | يُمحى؟ | لماذا |
/// |---|---|---|
/// | خروجٌ **متعمَّد** | ✅ | الموظّف سلّم الجهاز أو أنهى عمله |
/// | **تبديل حساب** عند الدخول | ✅ | وهو الأخطر — راجع [clearIfAccountChanged] |
/// | انتهاءُ جلسة (401) | ❌ | **نفس المستخدم** سيدخل ثانيةً، وطابورُه عملٌ ميداني لا يُمحى لأن توكناً انتهى |
/// | تعذُّرُ الشبكة | ❌ | لا علاقة له بالحساب |
///
/// والثالث هو الفرق الذي يجعل هذه الخدمة تُنادى من مواضع معدودة لا من كل مسار
/// خروج: `AuthEventBus.sessionExpired` يُطلَق من الـinterceptor بكل 401، ومسحٌ
/// هناك يعني **ضياع جولةٍ ميدانية لأن توكناً عمرُه ساعة انقضى**.
@lazySingleton
class AccountDataCleaner {
  const AccountDataCleaner(this._storage, this._wiper);

  final StorageService _storage;

  /// يمحو ما يملكه الموديول. الافتراضي لا يفعل شيئاً — راجع [LocalDataWiper].
  final LocalDataWiper _wiper;

  static const _tag = 'ACCOUNT-DATA';

  /// اللقطاتُ والمفاتيح التي **تخصّ الحساب** — تُمحى واحداً واحداً.
  ///
  /// و`StorageService.clear()` **ممنوعة** لمسح جزء: استُدعيت مرّةً فمحت الثيم
  /// واللغة والخط مع ما قصدته. وما ليس بهذه القائمة يبقى عمداً: `deviceId` و
  /// `fcmToken` يخصّان الجهاز، و`selectedFontKey` و`notificationsEnabled`
  /// تفضيلاتٌ لا تُعاد إلى الصفر لأن مستخدماً خرج.
  static const _accountKeys = [
    PersistenceKeys.cachedCurrentUser,
    PersistenceKeys.cachedAbilities,
    // 👇 **وهنا تُضاف لقطاتُ مشروعك.** كلُّ مفتاحٍ يحمل بياناً يخصّ الحساب
    //    يُسجَّل هنا يومَ يُولد — لا يوم يُكتشف أن الجهاز يعرض بيانات غيره.
    //    وأمثلةٌ مقيسة من مشروعٍ حقيقيّ: لقطةُ لوح الحساب (تُعرض بلا شبكة،
    //    فيرى الداخلُ الجديد دورَ سلفه ومحافظتَه)، ووجهةُ صورةٍ كانت تُلتقط
    //    لحسابٍ آخر (استعادتُها بعده تُودع صورتَه باستمارة من يليه).
    // جلسةُ الجهاز بالموديول متعدّد الأجهزة — تخصّ الحساب لا الجهاز.
    PersistenceKeys.deviceSessionId,
    PersistenceKeys.deviceIsPrimary,
    // آخرُ تبويبٍ نشط: تفصيلٌ صغير، ودخولُ موظّفٍ على «مرفوضات» سلفه يُقرأ
    // شاشةَ غيره.
    PersistenceKeys.navLastTabIndex,
  ];

  /// **الخروج المتعمَّد** — يمحو كل شيء ويُنسي الجهازَ من كان.
  Future<void> clearForSignOut() async {
    await _wipe();
    await _forget(PersistenceKeys.lastAccountUsername);
    LogService.info('Account data cleared after sign-out.', tag: _tag);
  }

  /// **تبديلُ الحساب** — يُمحى ما بالجهاز **قبل** أن تبدأ جلسةُ الداخل الجديد.
  ///
  /// ## ولماذا عند الدخول لا عند الخروج وحده
  ///
  /// الخروجُ المتعمَّد ليس الطريق الوحيد إلى جهازٍ يحمل بيانات غيره: التطبيق
  /// قد يُقتل، أو تنتهي الجلسة فيُترك، أو يُسلَّم الجهاز وهو مفتوح. وبكل هذه
  /// لا يمرّ أحدٌ بـ[clearForSignOut] إطلاقاً.
  ///
  /// فالحارسُ الحقيقي هنا: **أيّاً كان ما حدث قبل، لا يبدأ حسابٌ جلسةً فوق
  /// بيانات حسابٍ آخر.**
  ///
  /// ويُنادى **قبل** حفظ التوكن ونشر المستخدم، فلا تقع نافذةٌ تقرأ فيها شاشةٌ
  /// صفوفَ السابق بهوية اللاحق.
  ///
  /// يعود `true` إن وقع مسح.
  Future<bool> clearIfAccountChanged(String username) async {
    final previous = await _storage.readString(
      PersistenceKeys.lastAccountUsername,
    );
    // أولُ دخولٍ على جهازٍ نظيف — لا سابق يُقارَن به، ولا شيء يُمحى.
    if (previous == username) return false;

    if (previous != null && previous.isNotEmpty) {
      LogService.warning(
        'Account switch on this device ("$previous" → "$username") — wiping '
        'the previous account data before the new session starts.',
        tag: _tag,
      );
      await _wipe();
    }

    await _remember(username);
    return previous != null && previous.isNotEmpty;
  }

  Future<void> _wipe() async {
    // الموديول أولاً: الطابور هو الأخطر، وإخفاقُ مفتاحٍ نصّي بعده لا يمنعه.
    try {
      await _wiper.wipeAll();
    } catch (e) {
      LogService.error(
        'The local data wiper threw — snapshot keys are still cleared below.',
        tag: _tag,
        error: e,
      );
    }
    // **مخازنُ الشرائح ذاتُ المفاتيح المولَّدة** — راجع [AccountScopedStore].
    //
    // و`getAll` لا `isRegistered`: الأخيرة تقرأ التسجيلات **غير المسمّاة**
    // وحدها. ويُحلّ وقتَ النداء لا وقتَ البناء: هذه الخدمة `lazySingleton`
    // تُبنى مبكّراً، ومخازنُ الشرائح قد تُسجَّل بعدها.
    //
    // وكلُّ مخزنٍ بمحاولةٍ خاصّة: واحدٌ يُخفق لا يمنع البقيّة — وجهازٌ مُسح
    // نصفُه أسوأ من جهازٍ لم يُمسح، لأنه **يبدو نظيفاً**.
    for (final store in getIt.allOf<AccountScopedStore>()) {
      try {
        await store.clearForAccount();
      } catch (e) {
        LogService.error(
          'An account-scoped store threw while clearing — the rest still run.',
          tag: _tag,
          error: e,
        );
      }
    }
    for (final key in _accountKeys) {
      await _forget(key);
    }
  }

  Future<void> _remember(String username) async {
    try {
      await _storage.writeString(
        PersistenceKeys.lastAccountUsername,
        username,
      );
    } catch (e) {
      // **الأثر يُقال**: بلا هذا المفتاح لا يُكشف التبديل التالي، فيبدأ حسابٌ
      // ثالث فوق بيانات الثاني بصمت.
      LogService.error(
        'Could not record the signed-in account — the next account switch on '
        'this device will not be detected.',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<void> _forget(String key) async {
    try {
      await _storage.delete(key);
    } catch (e) {
      LogService.warning('Could not clear "$key": $e', tag: _tag);
    }
  }
}
