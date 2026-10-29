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
| **أول يوم بالقالب** | [`00_START_HERE.md`](00_START_HERE.md) — رود ماب بخمس مراحل، كلُّ مرحلةٍ بمعيار «تمّت» |
| تُجهّز جهازك · تجعل القالب مشروعك | [`01_SETUP.md`](01_SETUP.md) — البيئة والهوية والأيقونات والألوان، ومزالقُها |
| ★ **نسيتَ أمراً أو مساراً أو خطوة** | [`02_CHEATSHEET.md`](02_CHEATSHEET.md) — كلُّ شيءٍ بصفحة، ابحث بـCtrl+F |

## صيانة القالب — `_template/`

> خطّة القالب وأرشيفه وما تعلّمناه من المشاريع **في مستودع القالب وحده**:
> [`_template/README.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/README.md). `new_project.ps1` لا ينسخه إلى
> المشاريع، فكلُّ رابطٍ إليه رابطُ GitHub كامل يعمل من أي مشروع.

---

## قاعدة صارمة — لا يبقى ملف خارج جدول المزامنة

كل ملف هنا **يجب** أن يكون في جدول «Mandatory Documentation Sync» بـ
[`../CLAUDE.md`](../CLAUDE.md) مع عمود «متى يُحدَّث». الملف الذي لا يُذكر هناك لا
يُحدِّثه أحد — لأن لا شيء يذكّر به عند تغيير الكود الذي يصفه، **ولا شيء يفشل** حين
يتقادم: `dart analyze` نظيف، والاختبارات تمرّ، والوثيقة وحدها تكذب.

**عند إضافة ملف هنا**: أضف سطره لهذا الفهرس **ولجدول `CLAUDE.md`** بنفس التغيير.

