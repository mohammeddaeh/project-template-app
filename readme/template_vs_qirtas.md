# القالب مقابل قرطاس — تدقيق الانحراف

> **التاريخ:** 2026-08-17 · **النطاق:** `project-template/{app_template,backend_template}` مقابل `Qirtas/{qirtas_app,qirtas_backend}`
> **قرطاس** هو أول مشروع مشتقّ من هذا القالب، وبنودَ 18–33 بـ[`template_enhancements.md`](template_enhancements.md) استُخرجت من تشغيله العملي. فالانحراف **ثنائي الاتجاه** بالضرورة، وهذا الملف يقيسه بالاتجاهين.
>
> **هذا الملف قراءة لحظية، لا يُصان.** لا تُحدِّثه — أعد التدقيق وأعد كتابته.

---

## الحجم

| | القالب | قرطاس |
|---|---|---|
| ملفات Dart | ~470 | 698 |
| ملفات TS | 130 | 161 |
| **اختبارات وحدة بالباك** | **173** (14 ملف vitest) | **صفر** — لا `vitest`، لا `npm test`، لا `__tests__/` |
| اختبارات بالفرونت | 13 ملف | 18 ملف |
| مفاتيح صلاحيات (`permissions.lock.json`) | 14 | 21 |

---

## ١) الأعطال المُصلَحة اليوم — هل هي بقرطاس؟

**ثمانية من تسعة: نعم، متطابقة حرفياً.** قرطاس نسخة أقدم من نفس الملفات، فورث كل عطل كان بها.

| # | العطل | بقرطاس؟ | الأثر هناك |
|---|---|---|---|
| 1 | الكاش يكتب ولا يقرأ (`readString` بلا `await` ← تحويل يرمي ← `catch (_)` صامت) | ✅ متطابق حرفياً | **كامن** — لا شيء بقرطاس يفعّل الكاش (`cacheKey` بلا مستهلك) |
| 2 | `invalidateAll() => _storage.clear()` يمحو الثيم واللغة والخط | ✅ متطابق | **كامن** — بلا مستدعٍ. الفخّ مسلَّح لأول من يمدّ يده |
| 3 | الكاش بعد حارس الاتصال بترتيب الـinterceptors | ✅ متطابق | كامن — تابع لـ1 |
| 4 | `Accept-language` داخل `if (token != null)` | ✅ متطابق | 🔴 **حيّ ويراه المستخدم** |
| 5 | خروج قسري صامت (`sessionExpired`/`sessionRevoked` بلا رسالة) | ✅ متطابق | 🔴 **حيّ ويراه المستخدم** |
| 6 | `resetForTest()` تصفّر عَلَماً من اثنين | ✅ متطابق | تلوّث بين الاختبارات |
| 7 | جسم طلب تالف/كبير ← 500 | ✅ متطابق | 🔴 **حيّ** |
| 8 | `requestContext` بعد `express.json()` | ✅ متطابق | 🔴 **حيّ** — تابع لـ7 |
| 9 | `check:messages` أحمر | ❌ **قرطاس أخضر** | القالب هو المتأخّر هنا |

### الأربعة الحيّة تستحق أولوية بقرطاس

**#4 و#5 أخطرهما، وقرطاس أشدّ تأثراً من القالب:**

- **#4 اللغة**: قرطاس يملك `modules/dynamic_localization` — أي أن اللغة ميزة معلنة فيه لا إعداداً جانبياً. ومع ذلك كل رفض قبل امتلاك جلسة (كلمة مرور خاطئة · حساب موقوف/مرفوض/بانتظار موافقة · تجاوز محاولات · بريد مكرَّر · مسار استعادة كلمة المرور كاملاً) يصل بلغة الخادم الافتراضية `ar`، لأن الرأس لا يُرسَل بلا توكن. **مستخدم إنجليزي بقرطاس يقرأ عربياً على شاشة الدخول وحدها.**
- **#5 الخروج الصامت**: `qirtas_app/lib/app.dart:106` ينقل لشاشة الدخول بلا كلمة. مستخدمٌ وسط مهمّة يُلقى على شاشة الدخول بلا تفسير يقرأها انهياراً وفقداناً لعمله — وهي الحالة التي **يعرف التطبيق سببها بالضبط**.

### والشيفرة الميتة المحذوفة اليوم — نصفها ما يزال بقرطاس

| الملف | بقرطاس |
|---|---|
| `presentation/theme/app_text_styles.dart` | ✅ موجود · **ميت** (`context.ts` لا يُستدعى إلا بتعليق داخل `app_theme.dart`) |
| `foundation/domain/base_cancel_token.dart` + `infra/network/cancellation/` | ✅ موجود · **ميت** (`resetCancelToken` بلا مستدعٍ — و`safe_cubit.dart` بقرطاس يقول ذلك بنصّه) |
| `infra/errors/prefetch_stage_exception.dart` | ✅ موجود · ميت |
| `infra/network/rest/updated_at_filter.dart` | ✅ موجود · ميت |
| `platform/connectivity/network_stability_probe.dart` | ✅ موجود · ميت |
| `platform/features/feature_permission_map.dart` | ❌ **قرطاس نظّفه قبلنا** |
| `foundation/contracts/session_reader.dart` | ❌ نُظّف |
| `shared/widgets/images/default_svg_img.dart` | ❌ نُظّف |
| `lib/resources/translations/locale_keys.g.dart` (نسخة ثانية قديمة) | ❌ نُظّف |

---

## ٢) القالب متقدّم على قرطاس

### أ. الاختبارات — أكبر فجوة، وليست قريبة

`qirtas_backend/package.json` **بلا سكربت `test` إطلاقاً**. لا `vitest.config.ts`، ولا مجلد `__tests__/` واحد بين ١٦١ ملف TS. الموجود:

```
tests/auth-rotation.e2e.mjs · auth-security.e2e.mjs · auth-sessions.e2e.mjs
tests/auth-verification.e2e.mjs        ← أربعة سكربتات e2e تحتاج خادماً حيّاً
tests/email-recipient.test.ts · import-duplicate-detection.test.ts  ← يُشغَّلان يدوياً
```

مقابل **١٧٣ فحصاً** بالقالب تعمل بأمر واحد بلا خادم، ومنها ما يحرس قواعد قرطاس نفسها:
`route-coverage.test.ts` · `wire-contract.test.ts` (×3) · `password-policy` · `rate-limiter` · `inference` · `registry`.

وبالفرونت: القالب يملك [`wire_contract_test.dart`](../test/wire_contract_test.dart) بـ**١٠٣ تأكيدات** على مفاتيح JSON — و**قرطاس لا يملكه**. وهذا هو الاختبار الذي وُلد من عطل قرطاس نفسه: `LoginModel` قرأ `data.user` والخادم يرسل `data.account`، فـ«مسار الدخول لم يعمل ولا مرّة» بينما السيرفر يسجّل `200 OK`. **المشروع الذي وقع فيه العطل هو الوحيد بلا الحارس الذي وُلد منه.** ومثله `router_contract_test.dart`.

### ب. تحديد المعدّل — ذاكرة مقابل قاعدة بيانات

```ts
// qirtas_backend/src/core/security/rate-limiter.ts:15
private readonly attempts = new Map<string, Attempt>();
```

بينما القالب يملك `rate-limit-store.ts` (عقد) + `memory-rate-limit-store.ts` + `postgres-rate-limit-store.ts` + `schemas/rate-limits.schema.ts` + اختبار تكامل.

**الفارق أمني لا معماري:** عدّاد بالذاكرة **يُصفَّر بكل إعادة تشغيل ونشر**، ولا يُشارَك بين نسخ. مهاجم يقصف `/login` أثناء نشرٍ يبدأ من الصفر، وخلف موازن حِمل بنسختين يحصل على ضعف المحاولات. وتعليق قرطاس نفسه يعترف: «revisit with a shared store».

### ج. `authz` — القالب أعاد بناءه، وقرطاس على التصميم الأول

| | القالب | قرطاس |
|---|---|---|
| مصدر الكتالوج | يُلمّ من `requirePermission()` نفسه — `catalog.ts` + `registry.ts` + `inference.ts` | قائمة `PERMISSIONS` مبذورة بـ`seed-core.ts` |
| المسارات | `authz.routes.ts` عامّة — تخدم كل مورد | موزَّعة + `overrides.*` بخمسة ملفات |
| OpenAPI | `authz.openapi.ts` | — |
| الاختبارات | ٤١ فحصاً بأربعة ملفات | صفر |

القالب أحدث بنيوياً. لكن **قرطاس يملك فحصاً لا يملكه القالب** — راجع §3-ب.

### د. ما أُصلح اليوم
البنود ١–٨ أعلاه، ومعها [`readme/error_flow.md`](error_flow.md) — عقد مسار الخطأ عبر النصفين، ولا نظير له بقرطاس.

---

## ٣) قرطاس متقدّم على القالب

### أ. `securityEventSink` موصول بأثرٍ دائم

```ts
// qirtas_backend/src/app.ts:106
securityEventSink: auditLogSecurityEventSink,
```

القالب يشحن الافتراضي الذي يكتب للسجلّ فقط — وتوثيقه يحذّر بنصّه أن السجلّ «يدور ويختفي ولا يُستعلَم عنه بعد شهور». قرطاس فعل الشيء الصحيح. **يُنقل نمطه للقالب كمثال موصول، لا كتعليق يدعو لفعله.**

### ب. `check-permissions.ts` — أقوى من نظير القالب

ثلاثة فحوص ثابتة، والثالث ليس بالقالب: **مفتاح مبذور لا يفرضه أي مسار**. وجد بتدقيق حقيقي **١٧ مفتاحاً** تظهر بشاشة الأدوار، تُؤشَّر، ولا تحرس شيئاً. والاتجاه الأخطر الذي يذكره الملف: مفتاح يفرضه مسار ولا يبذره أحد ⇒ **بابٌ مغلق للجميع بمن فيهم المدير الأعلى، ولا شيء يبلّغ**.

`route-coverage.test.ts` بالقالب يغطي التصنيف فقط. **الفحص الثالث يُنقل.**

### ج. `PermissionsPanel` — يُغلق البند #25

`qirtas_app/lib/shared/widgets/layout/permissions_panel.dart` موجود. وهو بالضبط النصف الناقص من البند #25 بـ[`template_enhancements.md`](template_enhancements.md)، والعذر الأصلي («القالب بلا مجال صلاحيات») سقط منذ بُني `modules/access_control/`. **جاهز للنقل كما هو تقريباً.**

### د. `modules/dynamic_localization/` — البند #30

موجود بقرطاس، ولا شيء منه بالقالب. الجدول يشير إليه كأنه بالقالب؛ صُحّح اليوم إلى «غير موجود».

### هـ. ودجات عامّة قابلة للنقل فوراً

| الودجة | لماذا عامّة |
|---|---|
| `states/failure_state_view.dart` | عرض `Failure` مباشرة — يكمل `AppStateWidget` |
| `inputs/phone_text_field.dart` | حقل هاتف بقواعد — والقالب يوثّق نمطه ولا يملكه |
| `misc/app_version_footer.dart` · `misc/shimmer_text.dart` | لا شيء فيهما خاص بقرطاس |
| `layout/card_loading_scope.dart` · `lists/list_item_appear.dart` · `indicators/initial_loading_indicator.dart` · `indicators/next_page_status.dart` | مفردات تحميل عامّة |

**وليست للنقل:** `org_matrix` · `magnitude_bar` · `signal_card` · `record_removal_section` — مجالها قرطاس.

### و. اختبارات قابلة للنقل

`offline_failure_test` · `business_failure_message_key_test` · `auth_user_verification_wire_test` · `phone_field_rule_test` · `remembered_accounts_test` — تحرس سلوكاً يملكه القالب أصلاً.

---

## ٤) متطابق تماماً (لا عمل مطلوب)

- **هرم `Failure` كاملاً** — `diff` لا يُخرج سطراً واحداً. الفصل بين 500 و502/503/504، و`ServerUnreachableFailure`، وحالات الرفض الأربع للدخول: كلها متطابقة.
- **`RetryInterceptor`** — نفس السياسة، ونفس احترام `Retry-After`.
- **توليد `PermKeys`** — `permissions.lock.json` + `sync_permission_keys.dart` بالطرفين.

---

## ٥) خلاصة

**نتيجة المقارنة الأهمّ: القالب صار مُختبَراً أكثر من المشروع الذي استُخرج منه** — ١٧٣ فحص باك مقابل صفر، و١٠٣ تأكيدات wire مقابل لا شيء. وهذا يقلب العلاقة: لم يعد القالب مستودعاً لدروس قرطاس، بل صار الطرف الذي تُثبَّت فيه الدروس أولاً.

**والدرس الثاني أثقل:** ثمانية من تسعة أعطال أُصلحت اليوم كانت **متطابقة حرفياً** بالمشروعين. النسخ الأول ينسخ الأعطال مع البنية، ولا آلية تُعيدها. فالسؤال «هل هذا العطل بقرطاس؟» جوابه الافتراضي **نعم** لكل ما يمسّ `core/` — ويجب أن يُطرح مع كل إصلاح لا بعد ثلاثة أشهر.

### الأولويات

| | العمل | الوجهة |
|---|---|---|
| 🔴 1 | نقل إصلاحَي **#4 اللغة** و**#5 الخروج الصامت** | قرطاس — حيّان ويراهما المستخدم |
| 🔴 2 | نقل إصلاح **#7/#8 جسم الطلب التالف** | قرطاس |
| 🔴 3 | نقل مخزن تحديد المعدّل لقاعدة البيانات | قرطاس — فجوة أمنية |
| 🟠 4 | نقل `wire_contract_test.dart` + إدخال vitest | قرطاس — بلا شبكة أمان اليوم |
| 🟠 5 | نقل الفحص الثالث من `check-permissions.ts` | القالب |
| 🟠 6 | نقل `securityEventSink` كمثال موصول | القالب |
| 🟡 7 | نقل `PermissionsPanel` ⇒ يُغلق #25 | القالب |
| 🟡 8 | إصلاح 1/2/3 (الكاش) + حذف الشيفرة الميتة الخمسة | قرطاس — كامنة |
| 🟢 9 | الودجات والاختبارات العامّة | القالب |
