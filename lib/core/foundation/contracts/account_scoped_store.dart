/// **مخزنٌ يملك بياناتٍ تخصّ الحسابَ الداخل — فيُمحى معه.**
///
/// ## المشكلة التي وُجد لها
///
/// `AccountDataCleaner` يمحو ثلاثة أشياء: جداولَ الموديول، وبايتاتِ التخزين
/// الخاص، ولقطاتٍ نصّيةً **يعرف مفاتيحها بالاسم** (`_accountKeys`). وذلك يعمل
/// ما دام المفتاح ثابتاً يُكتب مرّةً بـ`PersistenceKeys`.
///
/// ولا يعمل لمخزنٍ مفاتيحُه **مولَّدة**: `UnitDraftStore` يكتب مفتاحاً لكل
/// مقسمٍ يُفتح (`unit_wip_<id>`)، ولا قائمةَ ثابتة تصفها. فبلا هذا العقد يبقى
/// **شغلٌ ميدانيّ نصفُ مكتوب لحسابٍ سابق** على جهازٍ سلّمه صاحبُه لغيره —
/// يُستأنف باستمارة من يليه.
///
/// ## ولماذا عقدٌ بـ`core` لا استيرادٌ مباشر
///
/// `core → features ❌`. فالمنظِّف يعرف **أن ثمّة مخازنَ تخصّ الحساب**، ولا
/// يعرف أيَّها ولا أين تسكن. يُحلّها بـ`getAll` وقتَ المسح، وكلُّ شريحةٍ
/// تُسجّل مخزنَها:
///
/// ```dart
/// @Named('unitDraftStore')
/// @LazySingleton(as: AccountScopedStore)
/// class SomeStore implements AccountScopedStore { … }
/// ```
///
/// > ⚠️ **وواحدٌ بلا `@Named`** — `getIt.isRegistered<T>()` تقرأ التسجيلات غير
/// > المسمّاة وحدها. راجع `lib/modules/sync/SETUP.md` §«واحدٌ بلا `@Named`».
///
/// ## ⛔ **ولا يكفي `as:` وحده متى كان الصنفُ يُحقن بذاته**
///
/// `@LazySingleton(as: AccountScopedStore)` يسجّل **تحت الواجهة وحدها**. فإن
/// حقنَ أحدٌ الصنفَ نفسه — لأنه يحتاج طرائقَ ليست بالعقد — انهار وقتَ التشغيل:
///
/// ```
/// StateError: GetIt: Object/factory with type UnitDraftStore is not registered
/// ```
///
/// **ووقع فعلاً**: `UnitFormCubit` يحقن `UnitDraftStore` (يحتاج `save`/`read`
/// /`clear`، ولا شيء منها هنا)، فكانت شاشةُ الاستمارة تنهار **بكل فتحة**. ولم
/// يره شيء قبل التشغيل: `injectable` يولّد `gh<UnitDraftStore>()` راضياً،
/// و`dart analyze` نظيف، ولا فاحصَ يقرأ الـDI (R28).
///
/// فالنمطُ الصحيح حينئذٍ **تسجيلان بنسخةٍ واحدة** — نفسُ ما يفعله
/// `SessionRepository` مع `AuthNetworkGateway`:
///
/// ```dart
/// @lazySingleton                                     // الصنفُ بذاته
/// class UnitDraftStore implements AccountScopedStore { … }
///
/// // injection_module.dart — الواجهةُ تُربط بالنسخة نفسها
/// @lazySingleton
/// AccountScopedStore accountScopedUnitDraftStore(UnitDraftStore s) => s;
/// ```
///
/// وتسجيلان مستقلّان يُنتجان **مخزنين**: يمحو المنظّفُ أحدَهما وتكتب الشاشةُ
/// بالآخر — فيبقى شغلُ حسابٍ سابق على الجهاز، وهو العطل الذي وُجد هذا العقد
/// لأجله.
abstract class AccountScopedStore {
  /// يمحو كلَّ ما يخصّ الحساب بهذا المخزن.
  ///
  /// **ولا يرمي**: مخزنٌ يُخفق مسحُه لا يجوز أن يمنع مسحَ البقيّة — والمنظِّف
  /// يلتقط على أي حال، لكن العقد يقول القصد.
  Future<void> clearForAccount();
}
