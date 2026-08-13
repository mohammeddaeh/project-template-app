# الاستيراد والتصدير — `modules/data_transfer/`

> موديول اختياري عام. **صفر سطر Dart لكل feature جديدة.**
> النصف الآخر: `backend_template/src/core/data-transfer/` — راجع `backend_template/docs/rest_api.md` §data-transfer.

---

## ما يعطيه

سطر واحد، من أي شاشة، لأي مورد يعلنه السيرفر:

```dart
IconButton(
  icon: const Icon(Icons.import_export),
  onPressed: () => DataTransferSheet.show(context, resource: 'notes'),
)
```

وهذا **كل** ما يخصّ النقل في `Features/notes/`. لا repository، ولا cubit، ولا شاشة، ولا مفتاح ترجمة. الشاشتان تجلبان `GET /api/v1/data-transfer/resources` وتبنيان منه: منتقي الأعمدة، واختيار الصيغة، والفلاتر، وقالب الاستيراد، وجدول الأخطاء.

**النتيجة العملية**: تعلن feature جديدة قابليتها للنقل بملف `*.transfer.ts` واحد بالباك، فتظهر لها شاشتا تصدير واستيراد عاملتان **بنسخة Flutter مبنية قبل وجودها**.

---

## التفعيل

```dart
// lib/core/platform/features/app_features.dart
static const dataTransfer = true;   // ← خطوة واحدة
```

`ModulesBootstrap.initializeAll()` يستدعي `DataTransferPlugin.initialize()` تلقائياً. مع `false`: لا يُسجَّل شيء، و`DataTransferSheet.show` **يرفض ويشرح** بدل فتح شاشة تعتمد على حقن لم يحدث — فنقطة الدخول لا يمكن أن تظهر بلا الموديول خلفها.

---

## البنية

```
modules/data_transfer/
├── data_transfer_plugin.dart        ← barrel + التفعيل
├── domain/
│   ├── transfer_resource.dart       ← TransferResource · TransferColumn · TransferFormat
│   ├── import_report.dart           ← ImportReport · ImportRowError · ImportResult
│   └── data_transfer_repository.dart ← أربع دوال، بلا أي دالة خاصة بـfeature
├── data/
│   ├── data_transfer_api_service.dart  ← النصف JSON فقط
│   ├── transfer_file_downloader.dart   ← ★ النصف الثنائي (bytes)
│   ├── models/{transfer_resource,import_report}_model.dart
│   └── data_transfer_repository_impl.dart
├── presentation/
│   ├── cubits/{export,import}_{cubit,state}.dart
│   ├── pages/transfer_{export,import}_screen.dart
│   └── widgets/{data_transfer_sheet,import_error_table,transfer_failure_view}.dart
└── integration/data_transfer_bootstrap.dart
```

---

## ⚠️ القاعدة الحرجة — `/export` لا يمرّ على `HandleBodyResponse`

**هذا الاستثناء الوحيد عن مغلّف `{status, message, data}` في التطبيق كلّه.**

`GET /export` و`GET /template` يردّان **بايتات ملف**. وكل نداء آخر يمرّ على `BaseRepository.handle()` → `HandleBodyResponse` الذي يحلّل الجسم كـJSON. توجيهه إلى CSV يُنتج `FormatException`، يُلتقط، ويُحوَّل إلى `Failure`، فيرى المستخدم «حدث خطأ» — **على `200 OK` وملف سليم مرفق**، بلا شيء في اللوج ولا في المحلّل يقول غير ذلك.

وهذا ليس افتراضياً: إنه بالضبط شكل عطل `data.user` / `data.account` الذي أبقى الدخول مكسوراً أسابيع بـCI أخضر عند الطرفين ([`integration_audit.md`](integration_audit.md)).

لذلك المسار الثنائي **صنف مستقل باسم صريح** — `TransferFileDownloader` — لا علماً على الـrepository: لا سبيل للوصول إليه بالخطأ، ولا للوصول لمسار الـJSON بالخطأ.

| | المسار | الشرح |
|---|---|---|
| `resources` · `import` | `handle()` → `HandleBodyResponse` | مغلّف JSON عادي |
| `export` · `template` | `TransferFileDownloader` → `dio.get(ResponseType.bytes)` | بايتات |

**والأخطاء تظل JSON**: السيرفر يرفض (413 صفوف كثيرة، 422 عمود مجهول) **قبل أول بايت**. ومع `ResponseType.bytes` تصل تلك الردود بايتاتٍ أيضاً، فـ`_messageFromBytes` يفكّها لرسالة — وإلا وصل المستخدمَ «فشل التنزيل»، وهي لا تقول له شيئاً عن الفلتر الذي عليه تضييقه.

> `TransferFileDownloader` يستخدم `Dio` **المحقون** (حامل `AuthInterceptor`). و`FileService` بـ`core/platform/files/` لا يصلح هنا: يحمل Dio منفصلاً بلا مصادقة، عمداً، للتنزيلات العامة. وهذه المسارات خاصة.

---

## الاستيراد بمرحلتين — آلة الحالة هي العقد

```
ImportReady ──اختر ملفاً + validate──▶ ImportReviewing ──confirm──▶ ImportCommitted
     ▲                                        │
     └──────────────── startOver ─────────────┘
```

**لا يوجد مسار من `ImportReady` مباشرةً إلى commit.** الـtoken المخوِّل للكتابة يعيش داخل `ImportReviewing` **فقط**، فـ«ارفع واكتب بخطوة» ليست شيئاً يستطيع المستدعي التعبير عنه — والمراجعةُ التي أعطى المستخدم موافقته عليها لا يمكن تخطّيها بنداء شارد من widget.

| نقطة | القرار |
|---|---|
| `token == null` | السيرفر يحجبه حين لا يصلح أي صفّ. الشاشة **لا تعرض زرّ تأكيد** أصلاً — زرٌّ مفعّل هنا يُنتج «inserted: 0» كنجاح |
| `truncated_errors` | السقف 200. الواجهة تقول «أول 200 مشكلة»، لا «200 مشكلة» — المستخدم يتصرّف بناءً على هذا الرقم |
| `row` → `spreadsheetLine` | السيرفر يعدّ صفوف البيانات من 1؛ عدّاد Excel يعدّ الرأس سطراً 1. `ImportRowError.spreadsheetLine` يضيف الإزاحة. بدونه كل إشارة تذهب للسطر الخطأ، وبصمت |
| فشل الـcommit | لا شيء كُتب (transaction بالسيرفر). لكن الـtoken **استُهلك**، فطريق العودة هو `startOver` (رفع جديد) لا إعادة `confirm` |

---

## التصريح — `authorize` بالطرف الخادم

مسارات النقل عامّة وتحمل `requireAuth` فقط. مورد **لا تُحصر صفوفه بالمستدعي** يجب أن يُعلن `authorize` يعكس حرّاس مساراته، وإلا صار الاستيراد **تجاوزاً كاملاً لـRBAC عبر رابط آخر**.

أثره على هذه الشاشات:

| الحالة | ما يراه المستخدم |
|---|---|
| ممنوع من التصدير والاستيراد | المورد **غائب** من `GET /resources` — لا تظهر له بطاقة أصلاً |
| يصدّر ولا يستورد | `supports_import: false` → شاشة الاستيراد ترفض بـ`import_unsupported` قبل أي نداء |
| مصرَّح له | كل شيء عادي |

فالواجهة لا تعرض زرّاً يردّ 403. والترشيح ليس تجميلاً: استجابة الوصف تحمل أسماء أعمدة كل مورد.

---

## الأعمدة القابلة للاستيراد مقابل القابلة للتصدير

`id` و`created_at` و`updated_at` **تُصدَّر ولا تُستورَد**. والسيرفر **يتجاهلها بصمت** عند الاستيراد بدل رفضها — وهذا بالضبط سبب عمل السيناريو الأساسي:

```
صدِّر كل الأعمدة → عدِّل خليتين بـExcel → استورد الملف نفسه
```

الملف المُصدَّر يحمل تلك الأعمدة لأننا نحن كتبناها. رفضها يجعل مخرجات التطبيق غير قابلة للاستيراد بالتطبيق ذاته. أما عمودٌ **مجهول تماماً** فيُرفض بـ422 — لأنه يعني غالباً الملف الخطأ أو المورد الخطأ، والمتابعة تُسقط عموداً يظنّ المستخدم أنه يستورده.

---

## العقد — لا تغيّر مفتاحاً بلا الطرف الآخر

| الملف | يقابله |
|---|---|
| `test/fixtures/wire/transfer_resources.json` | `backend_template/src/core/data-transfer/descriptor.ts` |
| `test/fixtures/wire/import_report.json` | `services/import.service.ts` → `ImportValidateReport` |
| `test/fixtures/wire/import_result.json` | `services/import.service.ts` → `ImportCommitReport` |

يفرضها `test/wire_contract_test.dart` هنا و`src/core/data-transfer/__tests__/wire-contract.test.ts` هناك. **بنفس الـcommit، ويجب أن يحمرّ الطرفان ثم يخضرّا.**

---

## الشاشة التفاعلية

`Features/test/` → **«الاستيراد والتصدير (حيّ)»**. قائمة الموارد فيها **غير مكتوبة في الملف** — تُجلب من السيرفر وتُعرض كما تصل، وهذا الإثبات الوحيد الصادق لادّعاء «صفر Dart لكل feature».

---

## ما لم يُبنَ (بقصد)

- **تصدير غير متزامن (job + polling)**: التصدير مباشر بسقف صريح 50٬000 صف يُفحص **قبل قراءة أي صف** (413 مع `row_count` و`max_rows`). الـjob يُضاف خلف نفس `DataTransferRepository` بلا كسر متى احتاجه مشروع.
- **PDF**: تقرير مطبوع لا تبادل بيانات. مكانه موديول `reporting` منفصل.
- **فلاتر مكتوبة النوع (typed filters)**: الوصف يحمل الآن فلاتر نصّية حرّة (`?q=`). مورد بفلاتر تواريخ/قوائم يوسّع `descriptor.ts` وشاشة التصدير — لا مستدعيها.
