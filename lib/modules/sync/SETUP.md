# Sync Module — Quick Setup Guide

> **الحالة الحقيقية والمراحل:** [`PLAN.md`](PLAN.md) · **التصميم:** [`ARCHITECTURE.md`](ARCHITECTURE.md)
> **الوصف القديم:** [`readme/sync.md`](../../../readme/90_archive/sync_design_spec.md) — يصف التصميم المقصود لا الكود القائم

---

## 📥 نقطة الدخول الوحيدة

```dart
import 'package:app_template/modules/sync/sync_plugin.dart';
```

**كل ما تحتاجه من الموديول يخرج من هذا الملف، ولا شيء غيره.** ما تحته —
`SyncEngine` · `SyncDatabase` · الـ`Sql*` stores · `SyncLock` · `SyncGate` ·
`AttachmentFileStore` · `SyncContractValidator` — تفصيلُ تنفيذٍ حرّ في التغيّر.

والقاعدة مفروضة لا مطلوبة: `test/sync/deletion_contract_test.dart` يفشل على أي
استيراد لـ`modules/sync/` من خارج الموديول لا ينتهي عند `sync_plugin.dart`.
فإن احتجت رمزاً غير مُصدَّر، **فذلك سؤالٌ عن سطح الموديول لا إذنٌ بتجاوزه**:
إمّا يُضاف سطر `export … show` واحد، أو أنك تصل إلى داخليٍّ وتحتاج مَنفذاً آخر.

> استثناءان: ملفات الموديول نفسها، واختباراته بـ`test/sync/` — وُجدت لتمارس
> الداخل. والملفات المولَّدة (`injection.config.dart`) تسمّي ملفَ كل نوع مسجَّل
> ولا يمكن توجيهها عبر باريل.

---

## ✅ ما **يوفّره** هذا الموديول اليوم — والحالة مأخوذة من الكود

| القدرة | الحالة | الدليل بالكود |
|---|---|---|
| **الدفع** — طابور مستديم بأولويات وتراجع أسّي وقفل و`Idempotency-Key` | ✅ | `SyncEngine._processPushQueue` · `SqlSyncQueueRepository` |
| **السحب** — `/delta` بمؤشر keyset ثنائي ومؤشرٍ لكل كيان | ✅ | `SyncEngine._processPullPhase` · `SyncCursorStore` |
| **القراءة التفاعلية** — `watch()` بلا polling | ✅ | `SyncChangeNotifier` · `SyncEntityStore.watch` |
| **القراءة النوعية** — عبر عقد الفيتشر لا تحليلاً يدوياً | ✅ | `SyncEntityStore.readTyped<T>` |
| **حلّ التعارض** — خمس سياسات، الاختيار لكل كيان | ✅ | `SyncConflictResolver` · `SyncConflictStrategy` |
| **ترحيل نسخ الحمولة** | ✅ | `SyncContractMigrator` · `contract_version` |
| **المرفقات** — تنزيل مستأنَف · تحقق SHA-256 · رفع · تخزين خاص · إخلاء | ◐ **جزئي** | راجع [§Step 7](#step-7--attachments-optional) |
| **مثال مرجعي حيّ** — عقد · مُنفِّذا دفع وسحب · ديكور · هدف رفع | ✅ | `lib/features/notes/data/sync/` |

## ⛔ ما **لا** يوفّره — وليس نقصاً مؤقتاً

| غير موفَّر | الحالة |
|---|---|
| **طابور تنزيل / جلبٌ مسبق** | ❌ جدول `download_queue` منشأ بلا كود يقرؤه. التنزيل **عند الطلب فقط** عبر `AttachmentDownloadManager.access()` |
| **Manifest وحصّة التخزين** | يُبنى — P3.5 |
| **التشغيل بالخلفية** | قرارٌ مؤجَّل — P7. الدورة تعمل بـ`Timer` ومستمعِ اتصال **داخل العملية**، وتتوقف بتوقّف التطبيق |
| **فحص المساحة قبل التنزيل · البطارية · صحّة السيرفر** | ❌ `SyncGate` يعلن ما لا يفحصه بجدولٍ فيه |
| تشفير القاعدة (SQLCipher) | قرار المشروع |
| **`Assignment` / `Location` / النماذج** | ❌ **لا تُبنى هنا أبداً** — شكلٌ مجالي. الموديول يشحن ميكانيكا `SyncBundle` والمشروع يسمّيها ويكتب دورتها |

> **لا تبنِ شاشةً على قدرةٍ من هذه القائمة.** الوعد بها كان مكتوباً في وثيقةٍ
> ومختوماً «COMPLETE» بينما نصفه غير موجود — وهذا القسم موجود ليمنع تكرار ذلك.

---

## Prerequisites

| Requirement | Version |
|---|---|
| Flutter | ≥ 3.19 |
| Dart | ≥ 3.3 |
| sqflite | ≥ 2.3 |
| dartz | ≥ 0.10 |
| get_it + injectable | any |

---

## Step 1 — Enable the feature flag

```dart
// lib/core/platform/features/app_features.dart
static const offlineSync = true;   // ← change false → true
```

---

## Step 2 — Bootstrap in main.dart ✅ (already done)

```dart
await SyncSDK.initialize(
  const SyncSdkConfig(
    enabled: AppFeatures.offlineSync,
    mode: SyncMode.active,          // active | passive | disabled
    periodicIntervalSeconds: 300,   // every 5 min; null = disable timer
    wifiOnly: false,                // true = only sync on WiFi
  ),
  getIt,
);
```

> `SyncSDK.initialize()` is a no-op when `AppFeatures.offlineSync == false`.

---

## Step 3 — Add your first entity

> **مثالٌ حيّ يُنسخ منه:** [`lib/features/notes/data/sync/`](../../features/notes/data/sync/)
> — ستة ملفات منفَّذة فعلاً (~٨٢٠ سطراً بالتعليقات) مقابل
> `backend_template/src/features/notes/`، وكلها تستورد `sync_plugin.dart`
> وحده. الشيفرة أدناه تشرح على كيان `mosques` **لا وجود له**؛ اقرأ `notes`
> أولاً، فهي الوحيدة التي تُصرَّف وتُختبر.
>
> **وموضعها ليس اختياراً**: مُحوِّلات المزامنة تسكن `<feature>/data/sync/`
> وحدها — `deletion_contract_test.dart` يرفض غيره، ليبقى حذف الموديول نمطاً
> واحداً لا بحثاً.

كل ملف من الأربعة أدناه يبدأ بسطر الاستيراد نفسه:

```dart
import 'package:app_template/modules/sync/sync_plugin.dart';
```

### 3a. Declare a feature contract

```dart
// lib/features/<name>/data/sync/<name>_feature_contract.dart

@LazySingleton(as: SyncFeatureContractBase)   // ← `as:` إلزامي · وبلا @Named
class MosquesFeatureContract extends SyncFeatureContractBase {
  const MosquesFeatureContract();

  @override String get entityName => 'mosques';
  @override Type get repositoryContractType => MosquesRepository;
  @override Object resolveRepository(GetIt di) => di<MosquesRepository>();

  // Override for entity-specific conflict strategy:
  @override
  SyncConflictStrategy get conflictStrategy => SyncConflictStrategy.serverWins;
}
```

> ### ⚠️ سطر التسجيل هذا هو الفرق بين موديولٍ يعمل وموديولٍ صامت
>
> `GetIt` يفهرس **بالنوع الحرفي**، والموديول يبحث عن `SyncFeatureContractBase`.
> فأيّ انحراف عن السطر أعلاه يجعل `validatePreInitialization()` تعيد `false`،
> فيخرج `SyncSDK.initialize` مبكراً، **ويظلّ التطبيق يعمل أونلاين بالكامل رغم
> أن `AppFeatures.offlineSync = true`** — بلا رمية، وبلا اختبارٍ يحمرّ، و
> `dart analyze` نظيف. عَلَمٌ لا يفعل شيئاً بصمت أسوأ من عَلَمٍ يفشل.
>
> | الشكل | `getAll` | `isRegistered` | النتيجة |
> |---|---|---|---|
> | `@LazySingleton()` (بالنوع الصريح) | ❌ يرمي | ❌ | الموديول لا يبدأ |
> | `@LazySingleton(as: …)` **+ `@Named`** | ✅ يجده | ❌ | الموديول لا يبدأ |
> | `@LazySingleton(as: SyncFeatureContractBase)` | ✅ | ✅ | ✅ يعمل |
>
> الصفّ الأوسط هو الفخّ: `getAll<T>()` يدمج المسمّى وغير المسمّى فيجد العقد،
> لكن كل مستدعٍ يمرّ أولاً بـ`if (!di.isRegistered<SyncFeatureContractBase>())`
> — و`isRegistered` بلا `instanceName` يقرأ القائمة **غير المسمّاة** وحدها، فلا
> يرى تسجيلاً مسمّى. الحارس يقصر الطريق قبل أن يصل `getAll` أصلاً.
>
> والحارس على هذا كلّه:
> ⬜ **ولا اختبارَ يحرس التسجيل** — حُذف مع الشريحة المرجعية (2026-09-08).
> وأولُ محوّلٍ تكتبه يستحقّ اختباراً يقرأ `injection.config.dart` ويؤكّد أن كلَّ
> صنفٍ مسجَّلٌ **تحت نوعه المجرَّد**: `getAll<T>()` يُفهرس عليه، و`as:` منسيّةٌ
> لا يراها شيءٌ قبل وقت التشغيل.
> — يسجّل العقد **بالشكل الذي يولّده `build_runner`** لا بالشكل الذي يريح
> الاختبار، ويثبّت الشكلين الفاشلين معاً.

### 3b. Implement a sync executor

```dart
// lib/features/<name>/data/sync/<name>_sync_executor.dart

@SyncExecutorFor('mosques')
@LazySingleton(as: SyncExecutor)
class MosquesSyncExecutor implements SyncExecutor {
  const MosquesSyncExecutor(this._syncApi);
  final MosquesSyncApiService _syncApi;

  @override String get entityName => 'mosques';
  @override Set<int> get supportedContractVersions => {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;
    final opts = Options(headers: {'Idempotency-Key': job.effectiveIdempotencyKey});
    return switch (job.type) {
      SyncJobType.create => _create(payload, opts, job),
      SyncJobType.update => _update(job.entityId, payload, opts, job),
      SyncJobType.delete => _delete(job.entityId, opts, job),
    };
  }
}
```

> ❌ **NEVER** call a GET endpoint inside an executor.  
> Executors **PUSH** (POST / PATCH / DELETE) only. Reads happen via repositories.

> `@SyncExecutorFor` هنا **وسمٌ وصفي لا آلية**: لا شيء يقرؤه وقت التشغيل،
> والمحرّك يبني خريطته من `SyncExecutor.entityName` وحده
> (`SyncEngine._buildExecutorCache`). فإن اختلف الاسمان فالـgetter هو الذي
> يُطبَّق — والوسم لن يشتكي.

### 3b-pull. Implement a pull executor (اختياري لكل كيان)

كيانٌ بلا مُنفِّذ سحب **لا يُسحب** — وهذا خيارٌ سليم لبيانات يكتبها هذا الجهاز
وحده. سجّل واحداً متى كان الكيان يُعدَّل من أكثر من جهاز أو من لوحة إدارة.

```dart
// lib/features/<name>/data/sync/<name>_sync_pull_executor.dart

@LazySingleton(as: SyncPullExecutor)
class MosquesSyncPullExecutor implements SyncPullExecutor {
  const MosquesSyncPullExecutor(this._dataSource);
  final MosquesRemoteDataSource _dataSource;

  @override String get entityName => 'mosques';

  @override
  Future<Either<Failure, SyncPullPage>> pull({
    required SyncCursor cursor,
    required bool includeDeleted,
    required int limit,
  }) async { /* GET /mosques/delta — راجع Step 6 */ }
}
```

المحرّك يخزّن مؤشر كل كيان على حدة، ويُبقيه دون تغيير عند فشل صفحة، فخطأ كيانٍ
لا يوقف غيره ولا يقفز فوق تغييراته. المرجع الحيّ:
`<feature>/data/sync/<feature>_sync_pull_executor.dart` بمشروعك.

### 3c. Wire write path via SyncWriteGateway

```dart
// In MosquesRepositoryImpl.createMosque():
await _syncWriteGateway.write(SyncWriteCommand(
  entityName: 'mosques',
  localId: mosque.id,
  serverId: mosque.serverId,
  dataJson: jsonEncode(mosque.toJson()),
  updatedAt: DateTime.now().millisecondsSinceEpoch,
  version: 1,
  isDeleted: false,
  jobType: SyncJobType.create,
  jobPayloadJson: jsonEncode(mosque.toJson()),
  contractVersion: 1,
  enqueue: true,                        // false = cache-only, no push
));
```

### 3d. Register repository decorator (**إلزامي** — للقراءات offline-first)

> صُحِّح 2026-08-17: كان مكتوباً «(optional)» بينما
> `SyncContractValidator._validateDecoratorAvailability` يرمي عند غيابه فيمنع
> الإقلاع. الوثيقة كانت تصف اختياراً لا يملكه المطوّر.
> إلغاء الإلزام مُدرَج في P0 بـ[`PLAN.md`](PLAN.md) — وحتى تُنفَّذ، **سجِّل decorator**.

```dart
// lib/features/mosques/data/sync/mosques_sync_repository_decorator.dart

@LazySingleton(as: SyncRepositoryDecorator)
class MosquesSyncRepositoryDecorator implements SyncRepositoryDecorator {
  const MosquesSyncRepositoryDecorator();

  @override
  Future<void> decorate(GetIt getIt) async {
    // يُحلّ **قبل** الإلغاء: النسخة الداخلية هي ما كان مربوطاً فعلاً — التنفيذ
    // العادي اليوم، أو ما ركّبه ديكورٌ آخر قبل هذا. وتسمية `…RepositoryImpl`
    // صراحةً تُسقط تلك الطبقة بصمت: كل شيء يُصرَّف وسلوكٌ واحد يختفي.
    final inner = getIt<MosquesRepository>();
    await getIt.unregister<MosquesRepository>();

    getIt.registerLazySingleton<MosquesRepository>(
      () => SyncAwareMosquesRepository(
        inner,
        getIt<SyncEntityStore>(),
        getIt<SyncWriteGateway>(),
        getIt<Uuid>(),
        const MosquesFeatureContract(),
      ),
    );
  }
}
```

> المُحوِّل لا يأخذ `SyncSettingsStore` — الوضع والتفعيل يقرؤهما
> `SqlSyncWriteGateway` بنفسه عند كل كتابة، ولا وجه لتمريرهما هنا. والمرجع
> المُصرَّف هو
> `<feature>/data/sync/<feature>_sync_decorator.dart` بمشروعك.


### 3e. ⚠️ و«فارغ» جوابان لا جواب — `SyncHydration`

كلُّ مغلِّفٍ محلّيٍّ‑أولاً يميل إلى هذا الشكل:

```dart
final matches = local.items.where(...).toList();
if (matches.isNotEmpty) return Right(matches);
return inner.getSomething(...);   // ← الشبكة
```

**و«فارغ» ليست جواباً واحداً**، بل جوابين لا يفرّق بينهما هذا السطر:

| المعنى | الصواب |
|---|---|
| «سُحب الكيان، ولا شيء يخصّ هذا المفتاح» | يُعرض فراغٌ مطمئن — **ولا شبكة** |
| «لم يُسحب بعد» | تُسأل الشبكة |

وخلطُهما يجعل **الحالة الطبيعية** — سجلٌّ بلا أبناء — تضرب الشبكةَ بكل فتحة.
فأوف‑لاين تفشل ويرى المستخدم شاشةَ خطأ حيث يجب أن يرى «لا توجد عناصر»؛ وأونلاين
تعمل، لكنها تدفع ثمنَ حارس الاتصال كاملاً قبل أن تُجيب.

```dart
if (matches.isNotEmpty) return Right(matches);
// سُحب الكيانُ مرّةً على الأقل ⇒ الفراغُ صادقٌ وكامل.
if (await _hydration.isHydrated('mosques')) return const Right([]);
return inner.getSomething(...);
```

**ولا مؤشّرَ جديد يُخزَّن** — الجوابُ موجودٌ سلفاً: `SyncCursor.isBeginning`
تعني «لم يُكتب مؤشّرٌ لهذا الكيان بعد»، والمحرّكُ لا يكتبه إلا **بعد** أن يدمج
صفحةً بنجاح.

⚠️ **والإخفاق يُقرأ `false`**: قاعدةٌ لا تُقرأ لا يجوز أن تُقنع المغلِّف بأن
الفراغَ الذي يراه صادق. وأسوأُ ما تفعله `false` أن تُرسل طلباً زائداً.


### 3f. بيانٌ يملكه الخادم ولا جدولَ له — `SyncRefreshTask`

`SyncPullExecutor` يخدم كياناً **بمخزن المزامنة**: صفوفٌ لها `local_id` وختمٌ
ونسخةٌ وشاهدةُ قبر. وبعضُ البيان ليس كذلك — لوحُ حساب، أو إعداداتٌ يملكها
الخادم، أو قائمةٌ يردّها كاملةً بلا مؤشّر.

```dart
@LazySingleton(as: SyncRefreshTask)
class SettingsRefreshTask implements SyncRefreshTask {
  @override
  String get name => 'server-settings';   // يظهر بسطر الإخفاق

  @override
  Future<void> refresh() async => _store.write(await _api.fetch());
}
```

يناديها المحرّك **بذيل الدورة الناجحة**: بعد السحب وقبل الملفّات. وكلُّ مهمّةٍ
تحمل حدَّ إخفاقها — لقطةٌ اختيارية لا تُسقط دورةً اكتملت — و`refresh()`
**لا ترمي ولا تُبلّغ**: لا شاشةَ تنتظرها.

**والبديلُ الذي تُنهيه** هو `unawaited(_refreshQuietly())` بكل فتحةِ شاشة:

| | دورةُ المزامنة | `unawaited` بكل `build` |
|---|---|---|
| البوّابة | `SyncGate` — توكن · تغطية · واي‑فاي فقط | **لا شيء** |
| الخنق | قفلٌ مستديم + نافذةُ استقرار | **لا شيء** |
| متى | حدثٌ يستحقّ | **بكل بناء** |

⚠️ **وليست بديلاً عن خدمةٍ تتبع دورةَ حياة التطبيق.** `SessionSyncService`
يسأل «من المستخدم؟» **عند العودة إلى المقدّمة** وبسقفٍ زمنيّ خاصّ — وهي دلالةٌ
أخرى، ولا تقع بذيل دورةٍ قد لا تجري أصلاً حين يكون `offlineSync` مطفأً.
والقاعدة: **ما يلزم بلا مزامنة يبقى خارجها**.


### 3g. ⚠️ ومتى **لا** يتقدّم مؤشّرٌ فوق صفٍّ تُرك

الدمجُ يترك الصفَّ الذي يحمل كتابةً لم يرها الخادم (`pending*` · `failed` ·
`conflicted`). والسؤالُ بعده: **هل يتقدّم ما يقيس «إلى أين وصلنا»؟**

والجوابُ يختلف بشكل المؤشّر، ولا يُنقل من بروتوكولٍ إلى آخر:

| الشكل | يتقدّم فوق المتروك؟ | لماذا |
|---|---|---|
| **مؤشّرٌ للكيان** (`updated_since` + `after_id`) — وهو ما بالقالب | ✅ **نعم** | الصفُّ المتروك يحمل تعديلاً **أحدثَ** سيُدفع بالدورة نفسِها، والواردُ أقدمُ بالتعريف. والمؤشّرُ **واحدٌ للكيان كلِّه**، فإيقافُه يُجمّد سحبَ الكيان بأسره حتى يحلّ إنسانٌ تعارضاً واحداً — عطلٌ أوسعُ ممّا يمنع |
| **ختمٌ لكلِّ أبٍ** (watermark لكل سجلٍّ أعلى) | ⛔ **لا** | الختمُ يقول «هذا الأبُ مُشيَّك فلا تنزل إليه». وتقديمُه بعد تركِ ابنٍ يعني أن الدورةَ التالية **لا تسأل عن ذلك الأب أصلاً** — فتضيع حالةُ الخادم لابنه **إلى الأبد**، لا بهذه الدورة وحدها |

**والفرقُ أن الأول يُعيد السؤال حتماً والثاني قد لا يُعيده.** فمشروعٌ يبني
بروتوكولَ علامةِ مياهٍ (نداءُ فهرسٍ ثم نزولٌ إلى الأبناء) **يجب** أن يُبقي ختمَ
الأب قديماً متى تُرك ابنٌ:

```dart
final merge = await mergeChildren(parentId, page);
// ثمنُ الوقوف نزولٌ ثانٍ بالدورة التالية، ويزول متى ارتفع المعلَّق.
// أمّا الثمنُ الآخر فلا يُسترجَع.
if (merge.skipped == 0) await watermarks.write(parentId, serverStamp);
```

⚠️ **ولا يُقاس الختمُ على صفّ الأب** (`synced_entities.updated_at`): ذاك يتقدّم
مع كل قراءةٍ ناجحة للقائمة — وهي تقع بكل فتحةِ تبويب — فيُقرأ الأبُ «محدَّثاً»
بلا أن يُنزَّل ابنٌ واحد.


### 3h. الصورُ والملفّات — `SyncMediaCatalog`

السحبُ ينزّل **الصفوف** وحدها: حقلُ ملفٍّ ينزل مسارَ تخزينٍ نصّاً لا بايتات.
فمن حمّل بياناته على Wi‑Fi ومضى إلى حيث لا تغطية يجد المرفقات **سطراً يُقرأ
ولا يُرى** — ولا شيء بالشاشة قال ذلك.

```dart
@LazySingleton(as: SyncMediaCatalog)
class NotesMediaCatalog implements SyncMediaCatalog {
  @override
  String get name => 'notes';

  @override
  Future<List<SyncMediaTarget>> targets() async => /* كلُّ ما تشير إليه صفوفُك */;
}
```

**والشريحةُ تقول أين ملفّاتُها، والموديولُ ينزّلها** — `modules → features ❌`.

⚠️ **ولا تُصفّي الشريحةُ ما نزل**: الجردُ **كلُّ** ما تشير إليه الصفوف، والمنفّذُ
وحده يسأل المخزنَ أيُّها بالجهاز. وتصفيةٌ بالشريحة تعني قاعدتين لسؤالٍ واحد
(R34) — وأسوأُ منها شريحةٌ تنسى مساراً نزل فتُعيد تنزيله بكل دورة.

**ولا دفترَ يقول «ماذا نزل»**: ما بالقرص هو الجواب، وما قال الخادمُ إنه ذهب
يُطرح. فالباقي وحده يُطلب **والاستئنافُ مجّانيّ** — انقطاعٌ بمنتصف المئة يترك
سبعين، والجولةُ التالية تسأل عن الثلاثين.

#### وموضعُه من الدورة شرطٌ لا ترتيب

```
دفعٌ ← سحبٌ ← تحديثٌ ← **ختمُ النجاح** ← إفراجُ القفل ← تنزيلُ الملفّات
```

- **خارج القفل**: القفلُ يحمي الكتابةَ بالقاعدة، وهذا يكتب بايتاتٍ بمجلَّده
  وحده. وحبسُه تحته يجعل صفّاً يحفظه المستخدم الآن ينتظر مئةَ ميغابايتٍ تنزل
  قبل أن يُدفع — نقيضُ «الدفعُ أوّلاً».
- **بعد الختم**: `SyncCycleStamp` مقياسُه الصفوف، وتأخيرُه خلف تنزيلٍ يطول يجعل
  الشاشة تقول «منذ ستّ دقائق» عن بيانٍ وصل قبل خمس.

#### وWi‑Fi وحده افتراضاً — عكسَ الدفع

| | `wifiOnly` (الدفع) | `mediaWifiOnly` (التنزيل) |
|---|---|---|
| الافتراضي | **مطفأ** | **مُشعَل** |
| الحمولة | كتابةُ مستخدمٍ لا نسخةَ لها | ملفّاتٌ يملكها الخادم أصلاً |
| ثمنُ التأخير | **شغلٌ لا يصل** | ساعةٌ لا تُضيّع شيئاً |

**والافتراضان معكوسان لأن السؤالين معكوسان.**

⚠️ **والوقوفُ حالةٌ تُبَثّ لا فراغٌ يُخفى** (`MediaPrefetchStatus`): «هل نزلت
الصور؟» سؤالٌ يُسأل قبل الخروج، وشاشةٌ تسكت عنه تُقرأ «لا أعرف». و`onMobileData`
هي الحَكَمُ على رسم زرّ «نزّل الآن» — **زرٌّ لا يُنفَّذ أسوأُ من غيابه**.


---

## 📐 قواعدُ «الجهازُ مصدرُ الحقيقة» — `L01…L06`

> **تنطبق متى كان `offlineSync` مُشعَلاً.** وتطبيقٌ يقرأ من الشبكة بكل شاشة لا
> يحتاجها — لكنه يحتاج أن يعرف أنه اختار ذلك، لا أن ينزلق إليه.

### L01 · الـcubit لا يعرف الشبكة 🔒

المستودعُ يُعيد بياناتٍ من المخزن المحلّي. ولا `isOnline` ولا `NoInternetFailure`
يصعدان إلى `presentation/` **بمسار القراءة**.

```dart
// ❌ شاشةٌ تسأل عن الشبكة قبل أن تعرض ما تملكه
if (!await ConnectivityService.isOnline()) emit(NoInternet());

// ✅ تعرض ما بالجهاز، ومؤشّرُ المزامنة يقول الباقي
final rows = await _getItems(parentId);
```

> **لماذا**: الصفوفُ موجودةٌ على الجهاز. ورفضُ عرضها لأن الهوائي صامت **حجبُ
> عملِ المستخدم عنه بحجّةٍ لا تخصّه**.

### L02 · `NoInternetWidget` لمسار الشبكة وحده 👁

يبقى مشروعاً لما **يحتاج الشبكة فعلاً**: تسجيلُ الدخول، وتنزيلُ مرفقٍ غير
مخزَّن. أمّا قائمةٌ لها بياناتٌ بالجهاز فلا.

### L03 · كل كتابة تنجح محلياً أوّلاً 🔒

```dart
await _store.upsert(entity);              // ١ · نجح — والشاشة تُحدَّث بـwatch()
await syncWrite(SyncWriteCommand(...));   // ٢ · صُفَّ للرفع
```

**ولا `await` على الشبكة بمسار الحفظ.** زرُّ حفظٍ ينتظر الخادمَ يجعل التطبيق
عديمَ الفائدة **بالضبط حيث وُجد ليعمل**.

### L04 · القراءة تفاعلية بـ`watch()` لا بـ`refresh()` 🔒

`SyncEntityStore.watch(entityName)` يبثّ عند كل تغيير — من المستخدم أو من دورة
المزامنة. فشاشةٌ تقرأ مرّةً ثم تنتظر سحباً لا تعرف أنه وقع **تعرض أمسَ بثقة**.

### L05 · المعرّفُ المحلّيُّ يسبق معرّفَ الخادم 🔒

الصفُّ يُولد بمعرّفٍ يصنعه الجهاز، ومعرّفُ الخادم يُختم عليه عند أوّل ردّ ناجح.
⚠️ **ويُكتب فورَ الولادة لا عند اعتماد الردّ**: تأجيلُه يجعل الإخفاقَ يترك الصفَّ
بلا معرّف، **فتُنشئ المحاولةُ التالية توأماً عند الخادم**.

**وخمسُ قواعدٍ فرعية تلزم معه:**

| # | القاعدة |
|---|---|
| L05‑أ | **لكلِّ حقلٍ مالكٌ واحد — ولا يكتبه الطرفان.** حقلٌ يكتبه الجهازُ والخادمُ معاً يفترق بصمت، ولا يُخفق شيء |
| L05‑ب | **نيّةُ العملية تسكن الكيان لا وظيفةَ الطابور.** الوظيفةُ تُلغى وتُعاد، والنيّةُ تبقى |
| L05‑ج | **الطابورُ هو البوّابةُ الوحيدة — ولا فعلَ «إرسال» بالواجهة.** زرٌّ يدفع مباشرةً يتخطّى البوّابة والقفل والتراجع |
| L05‑د | **الحالةُ المعروضة من الخادم وحده — ولا يخترع الجهازُ حالة.** واشتقاقُها محلياً يجعل الشاشة تقول «مقبول» عمّا لم يُسلَّم |
| L05‑هـ | **ما لا يُفتح لا يُعرض.** بابٌ إلى شاشةٍ تُخفق حتماً أسوأُ من غيابه |
| L05‑و | **ما لم يؤكّده الخادم لا يُعرض كأنه مؤكَّد — «الحَجْر».** سطرٌ يقول كم حقلاً لم يصل، ومخرجان لمن مات عملُه: «أعد المحاولة» و«تراجع». **والعدّادُ الكبير لا يُنقص** |

### L06 · «آخرُ مزامنة» حقيقةٌ لا تزيين 👁

«ناجحة» تعني **بلا إخفاقٍ واحد** — راجع `SyncCycleStamp`. ودورةٌ دفعت تسعةَ صفوفٍ
وأخفقت بالعاشر ليست مزامنةً ناجحة: المستخدم يقرأ الوقتَ المعروض **إقراراً بأن
عمله كلَّه هناك**، ويحذف التطبيق بناءً عليه.

---

## Step 4 — Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib
```

---

## Step 5 — Add UI scaffolding

### Global offline banner (app-level)

Wrap your root scaffold or top-level widget with `SyncUiHost`:

```dart
// lib/app.dart — inside MaterialApp builder:
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<SyncManagerCubit>()),
    BlocProvider(create: (_) => getIt<OfflineUxCubit>()),
  ],
  child: SyncUiHost(child: child!),
)
```

### Pending changes badge (per-screen AppBar)

```dart
AppBar(
  title: const Text('Mosques'),
  actions: const [PendingChangesChip()],
)
```

### Available widgets

كلها بـ[`lib/ui/state/sync/`](../../ui/state/sync/) — خارج
الموديول لأنها تعتمد Flutter وهو لا يعتمده.

| Widget | Purpose | يحرس نفسه على العلم؟ |
|---|---|---|
| `SyncUiHost` | يلفّ شاشة — شريط + ورقة تعارض + snackbar خطأ | ❌ **لا** — يتطلّب الـcubitين فوقه |
| `SyncStatusBanner` | شريط «دون اتصال / تغييرات معلّقة» | — |
| `PendingChangesChip` | شارة AppBar بعدد المعلّق وزر مزامنة | ✅ نعم |
| `AttachmentsSection` | مرفقات صفٍّ: عرض · التقاط · رفع | ✅ نعم |
| `AttachmentView` | عرض مرفق واحد بمساره الكسول | ✅ نعم |

> ⚠️ `SyncUiHost` يستدعي `context.read<OfflineUxCubit>()` في `initState`،
> و`OfflineUxCubit` يعتمد `SyncQueueRepository` التي **لا تُسجَّل ما لم يبدأ
> الموديول**. فالمزوِّدان فوقه إلزاميان، ولا تركّبه على build عَلَمُه مطفأ.
> `PendingChangesChip` يفحص العلم والتسجيل بنفسه، فيصلح لأي شاشة بلا شرط.

---

## Step 6 — Backend contract (required)

> **مُنفَّذ فعلاً على `notes`** بـ`backend_template` منذ 2026-08-17 (المرحلة P1 من
> [`PLAN.md`](PLAN.md)). اقرأ `src/features/notes/` و`docs/12_REST_API.md` §notes —
> فالعقد أدناه صار كوداً يعمل واختبارات تحرسه، لا وصفاً.

Your API endpoints MUST support:

```
GET  /resource/delta?updated_since=<ISO>&after_id=<uuid>&include_deleted=true&limit=200
POST   /resource                 ← create (accepts a client-generated `id`)
PATCH  /resource/{id}            ← update (optional `version` in the body)
DELETE /resource/{id}?version=   ← SOFT delete
```

**`/delta` is its own route, not `?updated_since=` on the list.** The list is
`created_at DESC`, page-numbered and hides tombstones because it feeds a screen;
the delta is `updated_at ASC`, keyset-cursored and must carry tombstones because
it feeds a replica. One route serving both means one path with two orderings,
two cursor styles and two response shapes, chosen by whether a parameter
happens to be present.

Its response:

```json
{
  "data": [ /* rows, tombstones included when asked for */ ],
  "next_cursor": { "updated_since": "…", "after_id": "…" },
  "server_time": "2026-08-17T10:00:00.000Z"
}
```

- The cursor is a **pair** — `updated_at` alone is not unique, and a page
  boundary inside a group of same-millisecond rows either skips them forever or
  repeats them every cycle.
- Send back **`server_time`**, never the device's own clock: a phone running two
  minutes fast skips every row written in those two minutes, permanently.
- The loop ends on **`next_cursor: null`**, not on an empty page.

**Writes carry `Idempotency-Key`.** A repeat replays the first attempt's
response verbatim with `Idempotent-Replay: true`; the same key with a different
body answers 422 rather than silently dropping the second write.
`SyncQueueJob.effectiveIdempotencyKey` already derives one and keeps it across
retries — a key regenerated per attempt protects nothing while looking like it
does.

**HTTP 409 body** (reaches the client as the error envelope's `data`):

```json
{
  "server_version": { "...": "full entity" },
  "client_version": { "...": "what the client tried to write" },
  "conflict_fields": ["field_a", "field_b"]
}
```

`conflict_fields` lists only what actually differs, so a client can merge the
rest automatically instead of escalating every edit to the user.

Every entity MUST have these fields:

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | UUID, client-generated for create |
| `created_at` | ISO timestamp | Immutable after creation |
| `updated_at` | ISO timestamp | Updated on every write |
| `is_deleted` | `boolean` | Soft delete — never hard-delete |
| `version` | `integer` | Incremented server-side on every write |

---

## Disabling sync for an entity

Simply **do not** register a `SyncFeatureContract` or `SyncExecutor` for it.  
Pass `enqueue: false` in every `SyncWriteCommand` — the data is cached locally,
never queued for push.

---

## Step 7 — Attachments (optional)

**◐ جزئي — اقرأ حدوده قبل أن تبني عليه.** المبنيّ: تنزيلٌ **مستأنَف** بـ`Range`
· تحقّق SHA-256 · نشرٌ بإعادة تسمية ذرّية · رفعٌ بمفتاح تعادُلٍ ثابت · تخزينٌ
**خاص** بمجلد المستندات (لا معرض ولا Downloads) · إخلاءٌ بثلاثة نواقض.
**غير المبنيّ:** طابور تنزيل وجلبٌ مسبق (`download_queue` جدولٌ بلا كود)،
وفحصُ المساحة، وإيقافٌ/استئنافٌ يدوي.

### 7a. الجانب الوحيد الخاص بالفيتشر: هدف الرفع

```dart
// lib/features/<name>/data/sync/<name>_attachment_target.dart
import 'package:app_template/modules/sync/sync_plugin.dart';

@LazySingleton(as: AttachmentUploadTarget)
class MosquesAttachmentUploadTarget implements AttachmentUploadTarget {
  const MosquesAttachmentUploadTarget(this._dio);
  final Dio _dio;

  @override String get entityName => 'mosques';

  @override
  Future<String> upload({
    required AttachmentRecord record,
    required File file,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<dynamic>(
      '${Env.baseUrl}/attachments',
      data: await attachmentFormData(record: record, file: file),
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    // **إعادة المعرِّف هي التأكيد.** لا شيء دونه يُحتسب رفعاً: العميل لا يفرّق
    // بين ردٍّ ضاع وكتابةٍ لم تقع، وارمِ إن غاب.
    return (response.data['data'] as Map<String, dynamic>)['id'] as String;
  }
}
```

هذا كل ما يكتبه الفيتشر. المرجع الحيّ:
`<feature>/data/sync/<feature>_attachment_target.dart` بمشروعك.

> `AttachmentUploadManager` **لا يُسجَّل** ما لم يُسجَّل هدفٌ واحد على الأقل، فمرحلة
> الملفات بدورة المزامنة تبقى فحص `isRegistered` واحداً بمشروعٍ بلا مرفقات.

### 7b. موضع الرفع من دورة المزامنة

```
runPendingJobs():  دفع الصفوف  →  سحب الصفوف  →  رفع الملفات
```

الملفات **آخراً وعن قصد**: هي أثقل مرحلة وأبطؤها، وتقديمها يجعل تنزيلاً واحداً
متعثّراً بـ٣٠٠ ميجابايت يحجب تعديلَ نصٍّ يُقاس بالبايتات. وفشلُ هذه المرحلة
**لا يُسقط الدورة** — إقرارات الصفوف التي نجحت قبلها لا تُفقد لاستثناءٍ رمته
صورة.

### 7c. الـPublic API الذي يحتاجه المستهلك

كلها من `sync_plugin.dart`:

| الرمز | لماذا |
|---|---|
| `AttachmentUploadTarget` · `attachmentFormData` | تعريف هدف الرفع (7a) |
| `AttachmentRecord` + `AttachmentOrigin` / `…DownloadStatus` / `…UploadStatus` | وصف مرفق وحالته |
| `AttachmentStore.findForEntity(...)` | ما يملكه صفٌّ من ملفات — **قراءةً فقط** |
| `AttachmentMetadataSync.refreshForEntity(...)` | تحديث تلك القائمة من السيرفر |
| `AttachmentCapture.capture(...)` | ابتلاعُ ملفٍ أنتجه الجهاز فور التقاطه |
| `AttachmentDownloadManager.access(id, isOnline:)` | جلبُ البايتات عند الحاجة |
| `AttachmentAccess` · `AttachmentReady` · `AttachmentUnavailable` · `AttachmentUnavailability` | جوابُ `access` بحالاته |

`AttachmentFileStore` و`SqlAttachmentStore` و`AttachmentCacheManager`
و`AttachmentUploadManager` **داخليّة** — لا تُستدعى من مستهلك ولا يصدّرها
الباريل.

### 7d. قراءة ملف — والمسار الكسول

```dart
final access = await getIt<AttachmentDownloadManager>().access(
  record.attachmentId,
  isOnline: await ConnectivityService.isOnline(),
);

switch (access) {
  case AttachmentReady(:final file):            // على القرص، وتمّ التحقق منه
  case AttachmentUnavailable(reason: AttachmentUnavailability.offline):
    // **ليست حالة خطأ**: ملفٌ اختياري أُخلي أمس على جهازٍ خارج التغطية اليوم
    // نظامٌ يعمل كما صُمّم. رسمُها فشلاً يُعلّم المستخدم أن التطبيق معطوب.
  case AttachmentUnavailable(:final reason):    // fetchFailed | corrupt
}
```

الترتيب داخلها: على القرص → يُخدَم ويُحدَّث زمن قراءته (LRU) · غير موجود
وأونلاين → تنزيل مستأنَف ثم تحقق ثم نشر · غير موجود وأوفلاين →
`AttachmentUnavailable(offline)` **دون أي محاولة شبكة**.

وبالواجهة، `AttachmentsSection` و`AttachmentView` يغلّفان هذا كلّه:

```dart
AttachmentsSection(entityName: 'mosques', entityLocalId: mosque.id)
```

### 7e. عقد السيرفر للمرفقات

مسارٌ **عام واحد** لكل الموارد — لا مسار لكل فيتشر:

```
GET  /attachments?entity_name=<name>&entity_id=<id>   ← القائمة (metadata فقط)
POST /attachments                                     ← رفع، بـ Idempotency-Key
```

وكل صفٍّ يحمل `checksum`. **مرفقٌ بلا checksum معلَن يُرفض نشره** بدل وضعه
بمرتبة ملفٍ متحقَّق منه.

---

## Debugging

### Force sync via code

```dart
context.read<SyncManagerCubit>().triggerSync();
// أو مباشرةً عبر السطح العام:
getIt<SyncController>().triggerManualSync();
```

### كم من العمل لم يصل السيرفر بعد؟

```dart
final pending = await getIt<SyncQueueRepository>().countPendingJobs();
```

> **استعلامات SQL الخام ومخطَّط الجداول انتقلت** إلى
> [`ARCHITECTURE.md`](ARCHITECTURE.md) §١٣ — تشخيصٌ داخليّ لا سطحُ استعمال.
> أسماء الجداول والأعمدة تفصيلُ تنفيذٍ حرٌّ في التغيّر، وكودُ مستهلكٍ بُني
> عليها يكسر بأول هجرة.

---

## Removing this module — عقد الحذف

**هذا مسار خروج مدعوم، لا حلٌّ أخير.** مشروعٌ لا يريد تخزيناً محلياً يشتقّ من
القالب ويحذف المجلد — والموديول مصمَّم ليبقى ذلك عمليةً واحدة **حتى بعد أن
يتضاعف حجمه** بمرحلة الملفات (P4.5).

### المنافذ الخمسة — ولا سادس

| المنفذ | ما فيه |
|---|---|
| `core/platform/features/app_features.dart` | `static const offlineSync` |
| `modules/modules_bootstrap.dart` | سطرٌ واحد يستدعي `SyncSDK.initialize` |
| `ui/state/sync/` | الـcubits والودجات (تعتمد Flutter فلا تسكن الموديول) |
| **`<feature>/data/sync/`** | عقد الفيتشر ومُنفِّذها وديكورها و`SyncAware…Repository` |
| **`modules/<name>/integration/`** | موديولٌ اختياريٌّ يشترك بالدورة — مستهلكُه اليوم `in_app_updates` يسجّل `SyncRefreshTask` لإعداداته |

> **والرابع والخامس قاعدةُ موضعٍ لا إذنَ استيراد.** عقدٌ ومُنفِّذ **يجب** أن يسمّيا الموديول —
> هذا معنى الاشتراك فيه. المهمّ أن تكون كلها في مكانٍ واحد متوقَّع، فيبقى الحذف
> نمطاً لا بحثاً. عقدٌ يُوضع في `data/repositories/` بجانب العادي **يعمل تماماً**،
> ويُكتشف بعد أشهر حين يحذف أحدهم الموديول فيقضي أصيلاً مع أخطاء الترجمة.
> الحارس يفرض الموضع.

### الخطوات

```bash
# 1. المجلد نفسه
rm -rf lib/modules/sync/

# 2. طبقة العرض التابعة له
rm -rf lib/ui/state/sync/

# 3. مُحوِّلات الفيتشرات — نمطٌ واحد، لأنها محصورة بمجلد متوقَّع
rm -rf lib/features/*/data/sync/

# 3‑ب. موديولٌ اختياريٌّ يشترك بالدورة — نمطٌ كذلك، ولنفس السبب
rm -rf lib/modules/*/integration/

# 4. اختباراته
rm -rf test/sync/

# 5. أسطر بالكود
#    - app_features.dart      → احذف سطر offlineSync
#    - modules_bootstrap.dart → احذف كتلة if (AppFeatures.offlineSync)
#    - أي شاشة تعرض PendingChangesChip → احذف السطر

# 5. تبعية اختيارية إن لم يستعملها شيء آخر
#    pubspec.yaml → sqflite

# 6. التحقق
dart run build_runner build --delete-conflicting-outputs
dart analyze lib test        # يجب أن يكون نظيفاً
flutter test
```

> **الحارس:** `test/sync/deletion_contract_test.dart` يمسح `lib/` كلّه على كل
> استيرادٍ لـ`modules/sync/` من خارج المنافذ الخمسة ويفشل على أي واحد. العدد
> اليوم صفر، والاختبار يبقيه صفراً بعد أن يكبر الموديول — فالحذف يظلّ ست خطوات
> لا مطاردةَ استيرادات.
>
> **وقاعدةٌ مقابلة على من يُضيف للموديول:** كودٌ جديد يحتاج أن يُستورَد من خارج
> المنافذ يعني أن التصميم خرج عن حدوده — يُعاد التفكير فيه، لا يُضاف منفذٌ رابع.

---

## Roadmap checklist for production readiness

**نصف السيرفر — ✅ منفَّذ على `notes` بـ`backend_template` (P1):**

- [x] `GET /:resource/delta` — مؤشر keyset مزدوج · `include_deleted` · `server_time`
- [x] `Idempotency-Key` — إعادة تشغيل الرد · و422 على مفتاحٍ بجسم مختلف
- [x] 409 بـ`{server_version, client_version, conflict_fields}`
- [x] كل كيان يحمل `id` (uuid) · `created_at` · `updated_at` · `is_deleted` · `version`
- [x] الحذف ناعم دائماً

**نصف العميل — الآليات المشحونة بالقالب (✅ لا تُبنى، تُستعمل):**

- [x] السطح العام بملف واحد: `sync_plugin.dart` — مفروضٌ بـ`deletion_contract_test.dart`
- [x] مسار الدفع · مسار السحب · القراءة التفاعلية (`watch`) · القراءة النوعية (`readTyped`)
- [x] خمس سياسات تعارض قابلة للاختيار لكل كيان · ترحيل نسخ الحمولة
- [x] مثالٌ مرجعيّ كامل يُنسخ منه: [`features/notes/data/sync/`](../../features/notes/data/sync/)
- [x] المرفقات: تنزيلٌ مستأنَف · تحقّق · رفع · تخزين خاص — **جزئي، راجع Step 7**

**نصف العميل — ما يكتبه مشروعك (لكل كيان):**

- [ ] `SyncFeatureContract` + `SyncExecutor` (+ `SyncPullExecutor` إن كان الكيان يُقرأ من أكثر من جهاز)
- [ ] `SyncRepositoryDecorator` + `SyncAware…Repository`
- [ ] `SyncWriteGateway.write()` في كل دالة كتابة بالـrepository
- [ ] `AttachmentUploadTarget` إن كان للكيان ملفات (Step 7)
- [ ] `SyncUiHost` + `PendingChangesChip` على شاشات الكيانات المتزامنة
- [ ] `dart run build_runner build` بعد كل تسجيل كيان جديد
- [ ] `AppFeatures.offlineSync = true` في إعداد التطبيق — **آخر خطوة لا أولها**

**قبل الشحن:**

- [ ] كل بند «سارٍ الآن» بـ[`RULES.md`](RULES.md) §ج و §و مطبَّق
- [ ] «الجولة الذهبية» (P6.7) خضراء

---

*خطوات التركيب هنا. القرارات المعمارية في [`ARCHITECTURE.md`](ARCHITECTURE.md)، والحالة والمراحل في [`PLAN.md`](PLAN.md).*
