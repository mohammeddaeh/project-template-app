# `readme/` — التوثيق التقني للقالب

> **ما لا يوجد هنا**: قواعد الكتابة اليومية (`../CLAUDE.md` وأبناؤه داخل `lib/`)
> · عقد الـREST بالباك (`../../backend_template/docs/`).
>
> هذا المجلد يشرح **البنية والأنظمة**؛ `CLAUDE.md` يشرح **ما تكتبه الآن**.

---

## أين تذهب

| تسأل عن | اقرأ |
|---|---|
| بنية `lib/` كاملة وحدود الطبقات | [`architecture.md`](architecture.md) |
| `core/` بالتفصيل — الطبقات الأربع، DI، الأخطاء | [`core_architecture.md`](core_architecture.md) |
| طبقة الشبكة (Dio/Retrofit → Failure → UiAction) | [`rest_api.md`](rest_api.md) |
| **ما يحدث بين «السيرفر رفض» و«المستخدم قرأ»** — العقد عبر النصفين | [`error_flow.md`](error_flow.md) |
| `PaginationCubit` و`PaginationBuilderWdg` | [`pagination.md`](pagination.md) |
| **أين** يوضع أي widget (feature أم `shared/`) | [`widgets.md`](widgets.md) |
| **كيف** يُستعمل كل widget بالمكتبة | [`widgets_usage.md`](widgets_usage.md) |
| الصلاحيات — `modules/access_control/` + `core/authz/` | [`permissions.md`](permissions.md) |
| الاستيراد/التصدير — `modules/data_transfer/` | [`data_transfer.md`](data_transfer.md) |
| السكربتات (`codegen`, `export`, `sync_*`) | [`scripts.md`](scripts.md) |
| الانضمام للقالب أول مرة | [`new_developer_guide.md`](new_developer_guide.md) |

## سجلّات ومواصفات — تُقرأ كـ«لماذا»، لا كـ«ما هو موجود»

| الملف | الحالة الحقيقية للكود |
|---|---|
| [`integration_audit.md`](integration_audit.md) | ✅ **سجلّ مغلق** — خمسة أعطال wire قاطعة، مُصلَحة ومثبَّتة بالطرفين. اقرأه قبل أي عمل يمسّ المصادقة أو شكل أي رد |
| [`template_enhancements.md`](template_enhancements.md) | **خارطة التطوير — المصدر الوحيد.** بعمودَي حالة (قرطاس / القالب)؛ `✅` بعمود القالب تعني **«له مستهلك هنا»** لا «الملف موجود» |
| [`test_scenarios_roadmap.md`](test_scenarios_roadmap.md) | خارطة `Features/test/` — لكل سيناريو حالته بالجدول |
| [`sync.md`](sync.md) | `modules/sync/` **مبنيّ ومطفأ** (`AppFeatures.offlineSync = false`) — وبلا endpoints بالباك |
| [`realtime_design.md`](realtime_design.md) | ❌ **غير مبنيّ** — لا `lib/modules/realtime/` أصلاً. ولا تخلطه بـ`modules/multi_device/` المبنيّ |

---

## قاعدة صارمة — لا يبقى ملف خارج جدول المزامنة

كل ملف هنا **يجب** أن يكون في جدول «Mandatory Documentation Sync» بـ
[`../CLAUDE.md`](../CLAUDE.md) مع عمود «متى يُحدَّث». الملف الذي لا يُذكر هناك لا
يُحدِّثه أحد — لأن لا شيء يذكّر به عند تغيير الكود الذي يصفه، **ولا شيء يفشل** حين
يتقادم: `dart analyze` نظيف، والاختبارات تمرّ، والوثيقة وحدها تكذب.

أربعة ملفات كانت خارج الجدول حتى 2026-08-17 — `sync.md` · `widgets_usage.md` ·
`test_scenarios_roadmap.md` · `realtime_design.md` — و**اثنان منها كانا قد انحرفا
فعلاً**: `realtime_design.md` كان عنوانه يصف `modules/multi_device/` المبنيّ ويقول
عنه «لم يُبنَ بعد»، و`sync.md` يصف موديولاً مطفأً بلا أن يقول ذلك.

**عند إضافة ملف هنا**: أضف سطره لهذا الفهرس **ولجدول `CLAUDE.md`** بنفس التغيير.

> ونفس الفجوة الأربعة وُجدت حرفياً بمشروع قرطاس المبنيّ على هذا القالب — وهو ما
> يجعلها عيب **قالب** لا سهو مشروع.
