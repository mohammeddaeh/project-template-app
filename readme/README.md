# `readme/` — التوثيق التقني للقالب

> **ما لا يوجد هنا**: قواعد الكتابة اليومية (`../CLAUDE.md` وأبناؤه داخل `lib/`)
> · عقد الـREST بالباك (`../../backend_template/docs/`).
>
> هذا المجلد يشرح **البنية والأنظمة**؛ `CLAUDE.md` يشرح **ما تكتبه الآن**.

---

## أين تذهب

| تسأل عن | اقرأ |
|---|---|
| ★ **القواعد الصارمة** `R01…R37` — كل واحدة والعطل الذي وُلدت منه | [`03_RULES.md`](03_RULES.md) |
| تبني شريحة كاملة — خطوات مرقّمة من `ApiUrls` إلى شاشة تعمل | [`04_FIRST_FEATURE.md`](04_FIRST_FEATURE.md) |
| ★ **تبني صفحة من الفيغما** — `F01…F37` · تفكيك الصفحة · بطاقة التسليم | [`05_FIGMA_TO_PAGE.md`](05_FIGMA_TO_PAGE.md) |
| بنية `lib/` كاملة وحدود الطبقات | [`10_ARCHITECTURE.md`](10_ARCHITECTURE.md) |
| `core/` بالتفصيل — الطبقات الأربع، DI، الأخطاء | [`11_CORE.md`](11_CORE.md) |
| طبقة الشبكة (Dio/Retrofit → Failure → UiAction) | [`12_REST_API.md`](12_REST_API.md) |
| **ما يحدث بين «السيرفر رفض» و«المستخدم قرأ»** — العقد عبر النصفين | [`13_ERROR_FLOW.md`](13_ERROR_FLOW.md) |
| `PaginationCubit` و`PaginationBuilderWdg` | [`14_PAGINATION.md`](14_PAGINATION.md) |
| **أين** يوضع أي widget (feature أم `ui/widgets/`) | [`20_WIDGETS.md`](20_WIDGETS.md) |
| **كيف** يُستعمل كل widget بالمكتبة | [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md) |
| **مقاسُ شاشة · لوح · كيبورد · تكبير خط** | [`22_RESPONSIVE.md`](22_RESPONSIVE.md) — `context.screen`، ولا نسبةَ من ارتفاع الشاشة |
| **إقلاع التطبيق · شاشة البدء · شعارُها** | [`23_STARTUP_SPLASH.md`](23_STARTUP_SPLASH.md) — شاشةٌ واحدة لا شاشتان · ⛔ **و`android: false` بقرار** |
| **ما يخدمه الباك فعلاً** | [`17_SERVED_CONTRACT.md`](17_SERVED_CONTRACT.md) — جردُ النقاط وحالاتُها الأربع · ودَينُ الباك بلغة المستخدم |
| الصلاحيات — `modules/access_control/` + `core/authz/` | [`31_MODULE_PERMISSIONS.md`](31_MODULE_PERMISSIONS.md) |
| الاستيراد/التصدير — `modules/data_transfer/` | [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) |
| السكربتات (`codegen`, `export`, `sync_*`) | [`40_SCRIPTS.md`](40_SCRIPTS.md) |
| ★ **ماذا نضيف بعد ليسهل بناء أي تطبيق مستقبلي** — أدوات · قدرات ناقصة | [`41_ROADMAP.md`](41_ROADMAP.md) |
| **أول يوم بالقالب** | [`00_START_HERE.md`](00_START_HERE.md) — رود ماب بخمس مراحل، كلُّ مرحلةٍ بمعيار «تمّت» |
| تُجهّز جهازك · تجعل القالب مشروعك | [`01_SETUP.md`](01_SETUP.md) — البيئة والهوية والأيقونات والألوان، ومزالقُها |
| ★ **نسيتَ أمراً أو مساراً أو خطوة** | [`02_CHEATSHEET.md`](02_CHEATSHEET.md) — كلُّ شيءٍ بصفحة، ابحث بـCtrl+F |

## سجلّات ومواصفات — تُقرأ كـ«لماذا»، لا كـ«ما هو موجود»

| الملف | الحالة الحقيقية للكود |
|---|---|
| [`90_archive/README.md`](90_archive/README.md) | **فهرسُ الأرشيف** — ما فيه ولماذا أُرشف، **وما حُذف ولم يُؤرشَف**، وسجلُّ تنظيف القالب (2026-08-19) بآثاره المفتوحة |
| [`90_archive/integration_audit.md`](90_archive/integration_audit.md) | ✅ **سجلّ مغلق** — خمسة أعطال wire قاطعة، مُصلَحة ومثبَّتة بالطرفين. اقرأه قبل أي عمل يمسّ المصادقة أو شكل أي رد |
| [`90_archive/template_backport.md`](90_archive/template_backport.md) | ✅ **سجلّ مغلق (2026-09-09)** — خطة نقل ما تعلَّمه مشروع «الأوقاف»، سبع موجات، ٥١ بنداً. كلّها ✅ إلا S01 (قاعدةً لا كوداً بقصد) |
| [`90_archive/template_enhancements.md`](90_archive/template_enhancements.md) | ⛔ **أرشيفٌ مقفَل — لا مصدر اقتراحات جديدة بعد الآن.** بعمودَي حالة (قرطاس / القالب)؛ `✅` بعمود القالب كانت تعني **«له مستهلك هنا»** لا «الملف موجود». **الاقتراحات الجديدة اليوم بـ[`41_ROADMAP.md`](41_ROADMAP.md)** |
| [`90_archive/sync_design_spec.md`](90_archive/sync_design_spec.md) | ◐ **يصف التصميم لا الكود.** `modules/sync/` صار **يدفع ويسحب** على مثال `notes` حيّ (P0→P3)، والناقص: الملفات · Manifest · الخلفية. الحالة والمراحل: [`lib/modules/sync/PLAN.md`](../lib/modules/sync/PLAN.md) |
| [`90_archive/realtime_design.md`](90_archive/realtime_design.md) | ❌ **غير مبنيّ** — لا `lib/modules/realtime/` أصلاً. ولا تخلطه بـ`modules/multi_device/` المبنيّ |
| [`90_archive/sync_system_guide.md`](90_archive/sync_system_guide.md) | جولة تعريفية بالإنجليزية على موديول المزامنة — كانت بجوار الكود (`lib/modules/sync/`) |

> ⛔ **وما تحت `90_archive/` لا يُصان.** صحيحٌ **عن تاريخه** وقد لا يصف الكود اليوم،
> ولا يُصحَّح بتعديل صفوفه: سجلٌّ يُعاد كتابته يفقد قيمته الوحيدة — أنه يقول ما كان
> صحيحاً حين كُتب. الانحراف يُعلَّق عليه بلافتة، لا يُمحى.

---

## قاعدة صارمة — لا يبقى ملف خارج جدول المزامنة

كل ملف هنا **يجب** أن يكون في جدول «Mandatory Documentation Sync» بـ
[`../CLAUDE.md`](../CLAUDE.md) مع عمود «متى يُحدَّث». الملف الذي لا يُذكر هناك لا
يُحدِّثه أحد — لأن لا شيء يذكّر به عند تغيير الكود الذي يصفه، **ولا شيء يفشل** حين
يتقادم: `dart analyze` نظيف، والاختبارات تمرّ، والوثيقة وحدها تكذب.

أربعة ملفات كانت خارج الجدول حتى 2026-08-17 — `sync.md` · `21_WIDGETS_USAGE.md` ·
`00_START_HERE.md` · `90_archive/realtime_design.md` — و**اثنان منها كانا قد انحرفا
فعلاً**: `90_archive/realtime_design.md` كان عنوانه يصف `modules/multi_device/` المبنيّ ويقول
عنه «لم يُبنَ بعد»، و`sync.md` يصف موديولاً مطفأً بلا أن يقول ذلك.

**عند إضافة ملف هنا**: أضف سطره لهذا الفهرس **ولجدول `CLAUDE.md`** بنفس التغيير.

> ونفس الفجوة الأربعة وُجدت حرفياً بمشروع قرطاس المبنيّ على هذا القالب — وهو ما
> يجعلها عيب **قالب** لا سهو مشروع.
