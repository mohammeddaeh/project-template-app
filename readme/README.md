# `readme/` — التوثيق التقني للقالب

> **ما لا يوجد هنا**: قواعد الكتابة اليومية (`../CLAUDE.md` وأبناؤه داخل `lib/`)
> · عقد الـREST بالباك (`../../backend_template/docs/`).
>
> هذا المجلد يشرح **البنية والأنظمة**؛ `CLAUDE.md` يشرح **ما تكتبه الآن**.

---

## المجلدات

| المجلد | لمن | ما فيه |
|---|---|---|
| [`start/`](start/) | **أوّل يوم · كل يوم** | [`00_START_HERE.md`](start/00_START_HERE.md) رود ماب بخمس مراحل · [`01_SETUP.md`](start/01_SETUP.md) تجهيز الجهاز وجعلُ القالب مشروعك · [`02_CHEATSHEET.md`](start/02_CHEATSHEET.md) كلُّ أمرٍ ومسارٍ بصفحة · [`04_FIRST_FEATURE.md`](start/04_FIRST_FEATURE.md) شريحةٌ كاملة خطوةً خطوة |
| [`rules/`](rules/) | **قبل أي سطر** | [`03_RULES.md`](rules/03_RULES.md) القواعد الصارمة `R##` بأسبابها · [`06_CAPABILITIES.md`](rules/06_CAPABILITIES.md) ★ ابحث قبل أن تكتب أداة · [`05_FIGMA_TO_PAGE.md`](rules/05_FIGMA_TO_PAGE.md) صفحةٌ من الفيغما `F##` |
| [`architecture/`](architecture/) | **كيف يعمل** | [`10_ARCHITECTURE.md`](architecture/10_ARCHITECTURE.md) بنية `lib/` وحدودها · [`11_CORE.md`](architecture/11_CORE.md) `core/` والـDI · [`12_REST_API.md`](architecture/12_REST_API.md) الشبكة · [`13_ERROR_FLOW.md`](architecture/13_ERROR_FLOW.md) من «السيرفر رفض» إلى «المستخدم قرأ» · [`14_PAGINATION.md`](architecture/14_PAGINATION.md) القوائم بصفحات · [`17_SERVED_CONTRACT.md`](architecture/17_SERVED_CONTRACT.md) ما يخدمه الباك فعلاً · [`23_STARTUP_SPLASH.md`](architecture/23_STARTUP_SPLASH.md) الإقلاع وشاشة البدء |
| [`ui/`](ui/) | **الواجهة** | [`20_WIDGETS.md`](ui/20_WIDGETS.md) أين توضع الودجة · [`21_WIDGETS_USAGE.md`](ui/21_WIDGETS_USAGE.md) فهرسُ مكتبة الودجات، وشرحُها بـ[`widgets/`](ui/widgets/) بستّ فئات · [`22_RESPONSIVE.md`](ui/22_RESPONSIVE.md) المقاسات واللوح والكيبورد |
| [`modules/`](modules/) | **ما يُشعَل بعلَم أو يُركَّب بأمر** | [`30_MODULES.md`](modules/30_MODULES.md) ★ الجدول الواحد للموديولات · [`31_MODULE_PERMISSIONS.md`](modules/31_MODULE_PERMISSIONS.md) الصلاحيات · [`32_MODULE_DATA_TRANSFER.md`](modules/32_MODULE_DATA_TRANSFER.md) الاستيراد والتصدير · [`33_MODULE_TOKEN_INSPECTOR.md`](modules/33_MODULE_TOKEN_INSPECTOR.md) التوكن على الشاشة · [`24_DEVICE_KITS.md`](modules/24_DEVICE_KITS.md) حِزَم الأجهزة |
| [`scripts/`](scripts/) | **الأوامر** | [`40_SCRIPTS.md`](scripts/40_SCRIPTS.md) كل سكربت، مجمّعاً بمتى تحتاجه · [`41_UPGRADING.md`](scripts/41_UPGRADING.md) ترقيةُ مشروعٍ قائم إلى إصدارٍ أحدث، لكل إصدار |

**والأرقام ثابتة** — `03_RULES` يبقى `03_RULES` أينما ذُكر، والمجلد يجمع لا يُعيد الترقيم.

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

**عند إضافة ملف هنا**: ضعه بمجلد موضوعه، وأضف سطره لهذا الفهرس **ولجدول `CLAUDE.md`** بنفس التغيير.

