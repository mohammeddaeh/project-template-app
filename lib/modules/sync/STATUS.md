# حالة موديول المزامنة — ما يعمل وما ينقص

> **اقرأ هذا قبل أن تبني على الموديول.** يصف الكود كما هو اليوم، بدليلٍ من الملف
> لكل سطر. **التصميم:** [`ARCHITECTURE.md`](ARCHITECTURE.md) · **التركيب:**
> [`SETUP.md`](SETUP.md) · **قواعد التطبيق بمشروع:** [`RULES.md`](RULES.md) ·
> **خطة التجريب ببيانات كبيرة:** [`LOAD_TEST_PLAN.md`](LOAD_TEST_PLAN.md)
>
> مراحل بناء الموديول وسجلُّ أعطاله المُصلَحة بمستودع القالب وحده:
> [`_template/sync/PLAN.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/sync/PLAN.md).

---

## أ) ما يعمل

| القدرة | الدليل |
|---|---|
| قاعدة محلية بمعاملات وهجرات متدرّجة | `data/sync_database.dart` · WAL · `foreign_keys=ON` |
| فحص سلامة وتعافٍ من التلف | `_checkIntegrity` يمسح التالف ويعيد البناء |
| طابور مستديم بأولويات واستحقاق | `sync_queue` + فهرس `(priority, next_retry_at, created_at)` |
| تراجع أسّي · قفل ضد التزامن · تحرير القفل البائت | `SyncBackoffPolicy` · `SyncLock.releaseIfStale` |
| سجلّ عمليات وتقليمه | `SyncOperationsLog.trim()` كل ٥٠ دورة |
| ترحيل نسخ الحمولة | `SyncContractMigrator` |
| الدفع والسحب والدمج | `SyncEngine` · `SyncGate` · `sync_meta` |
| قراءة نوعية وتفاعلية | `watch` على العقد |
| المرفقات — تنزيل مستأنَف · SHA-256 · رفع · تخزين خاص · Cache Manager | `attachments/` |
| التشغيل بالخلفية — **أندرويد فقط** | `background/sync_background_worker.dart` (WorkManager). iOS يُعرَض عليه `SyncKeepOpenNotice` بدل وعدٍ لا يُوفى |
| إحياء صفٍّ استنفد محاولاته | `SyncQueueRepository.reviveJob({jobId})` |
| سبب رفض المزامنة اليدوية يصل الواجهة | `triggerManualSync` تُعيد `SyncBlockReason?` · حالة `SyncBlocked` |
| فشل الدورات التلقائية يصل الواجهة | `SyncController._runCycleGuarded()` · `errorStream` ⇐ `SyncFailedState` |
| العلَم يُشعل أو يُعطّل ولا يُسقط التطبيق | `test/sync/sync_bootstrap_safety_test.dart` |

## ب) المفتوح — مرتّباً بالخطورة

| # | المفتوح | الأثر |
|---|---|---|
| ب١٣ | **صفر عقود منفَّذة بالقالب** | `getAll<SyncFeatureContractBase>()` يعيد صفراً. أوّل عقدٍ يكتبه المشروع — راجع [`SETUP.md`](SETUP.md) Step 3 |
| ب١٤ | **العلَم بلا عقودٍ = شبكةٌ كاملة بصمت** | تفعيل `AppFeatures.offlineSync` مع ب١٣ يترك التطبيق على الشبكة بلا انهيار ولا تحذير. `audit_template.dart` §٢ يكشفه |
| ب١٥ | **فخّ الرفع الصامت** | `AttachmentUploadManager` يُسجَّل فقط إن وُجد `AttachmentUploadTarget` واحد. فيتشرٌ له `AttachmentRecord` بلا `XxxAttachmentUploadTarget` مسجَّل ⇒ الرفع متوقّف بصمت تامّ. تحقّق من وجوده لكل فيتشر بمرفقات |
| ب٧ | **منطق الطابور والتعارض والترحيل بلا اختبار** | الاختبار يحتاج `sqflite_common_ffi`، غير موجودة بـ`pubspec` |
| ب٨ | **`PRAGMA integrity_check` عند كل إقلاع** | كلفته تتناسب طرداً مع حجم القاعدة |
| ب١٢ | **`SharedPrefsSyncSettingsStore` يتجاوز `StorageService`** | مخزنٌ رابع بمفاتيح نصّية خام |

## ج) غير موفَّر

القالب يشحن الموديول **مطفأً**، بمزامنةٍ **على مستوى الكيان**. بعض ما يلي لم يُبنَ
بعد، وبعضه خارج نطاق القالب بقصد:

| غير موفَّر | الحالة |
|---|---|
| `SyncBundle` + Manifest + حصّة التخزين | **لم يُبنَ.** الحصّة تُفحص من `totals` الـmanifest قبل أول بايت |
| خدمة أمامية للتنزيلات الكبيرة | **لم تُبنَ.** الخلفية الحالية تصرّف الصفوف لا المرفقات |
| تحقّق ميداني كامل (الجولة الذهبية: طيران · تعديلات · قتل التطبيق · عودة) | **لم يُجرَ** |
| خفض كلفة الفيتشر (`SyncWriteCommand.fromEntity` · `SyncAwareRepository<T>` عام) | **لم يُبنَ.** كل كيان يكتب مستودعه الموازي كاملاً |
| أرقام سعة وأداء | **لم تُقَس.** [`RULES.md`](RULES.md) §أ–ب فارغة حتى يُجرى [`LOAD_TEST_PLAN.md`](LOAD_TEST_PLAN.md) |
| تشفير القاعدة (SQLCipher) | **قرار المشروع** — تبعية ثقيلة لحساسيةٍ لا يعرفها القالب |
| `Assignment` / `Location` / النماذج | ❌ **لا تُبنى بالقالب أبداً** — شكلٌ مجالي. القالب يشحن الميكانيكا، والمشروع يسمّيها |
| الاستعلامات النوعية المولَّدة (Drift) | **قرار المشروع** |

## د) عقد الحذف

الخروج من الموديول: **احذف المجلد.** ولذلك أربعة منافذ وحدها تشير إليه من خارجه:

| المنفذ | ما فيه |
|---|---|
| `core/platform/features/app_features.dart` | `offlineSync` |
| `modules/modules_bootstrap.dart` | سطرٌ واحد يستدعي `SyncSDK.initialize` |
| `ui/state/sync/` | الـcubits والودجات — طبقة عرض تعتمد Flutter |
| `<feature>/data/sync/` | عقد الفيتشر ومُنفِّذاها وديكورها — **قاعدة موضع لا إذن استيراد** |

**الحارس:** `test/sync/deletion_contract_test.dart` يمسح `lib/` ويفشل على أي استيرادٍ
لـ`modules/sync/` من خارج المنافذ. **وخطوات الحذف:** [`SETUP.md`](SETUP.md) §Removing this module.
