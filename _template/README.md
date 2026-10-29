# `_template/` — صيانة القالب نفسه

> **لا يُنسخ إلى أي مشروع.** `scripts/new_project.ps1` يستثنيه عند الإنشاء. فيه ما
> يخصّ القالبَ كمنتج، لا ما يحتاجه مشروعٌ مبنيّ عليه. ما يحتاجه المشروع بـ
> [`../readme/`](../readme/README.md).

| تحتاج | افتح |
|---|---|
| سجلّ الإصدارات — ما تغيّر بكل رقمٍ بـ`TEMPLATE_VERSION` | [`CHANGELOG.md`](CHANGELOG.md) |
| قواعد صيانة هذا المجلد — جدول التزامن الخاص به، يُقرأ مع `CLAUDE.md` الجذري | [`CLAUDE.md`](CLAUDE.md) |
| ★ **ماذا نضيف بعد ليسهل بناء أي تطبيق مستقبلي** — أدوات · قدرات ناقصة | [`_template/roadmap.md`](roadmap.md) |
| ★ **ما تعلّمناه من مشروعٍ حقيقي على القالب** — اقتراحاتٌ من كل مشروع بدليلها، تُطبَّق على القالب لاحقاً | [`_template/feedback/`](feedback/README.md) |
| مراحل بناء موديول المزامنة P0–P9 وسجلُّ أعطاله المُصلَحة — حالتُه اليوم بـ`lib/modules/sync/STATUS.md` | [`sync/PLAN.md`](sync/PLAN.md) |
| أسماءُ المشاريع والجهات الممنوعة بما يصل المشاريع — يقرؤها `audit_template.dart` §٥ | [`project_names.txt`](project_names.txt) |

## الأرشيف — تُقرأ كـ«لماذا»، لا كـ«ما هو موجود»

| الملف | الحالة الحقيقية للكود |
|---|---|
| [`_template/archive/README.md`](archive/README.md) | **فهرسُ الأرشيف** — ما فيه ولماذا أُرشف، **وما حُذف ولم يُؤرشَف**، وسجلُّ تنظيف القالب (2026-08-19) بآثاره المفتوحة |
| [`_template/archive/integration_audit.md`](archive/integration_audit.md) | ✅ **سجلّ مغلق** — خمسة أعطال wire قاطعة، مُصلَحة ومثبَّتة بالطرفين. اقرأه قبل أي عمل يمسّ المصادقة أو شكل أي رد |
| [`_template/archive/template_backport.md`](archive/template_backport.md) | ✅ **سجلّ مغلق (2026-09-09)** — خطة نقل ما تعلَّمه مشروع «الأوقاف»، سبع موجات، ٥١ بنداً. كلّها ✅ إلا S01 (قاعدةً لا كوداً بقصد) |
| [`_template/archive/template_enhancements.md`](archive/template_enhancements.md) | ⛔ **أرشيفٌ مقفَل — لا مصدر اقتراحات جديدة بعد الآن.** بعمودَي حالة (قرطاس / القالب)؛ `✅` بعمود القالب كانت تعني **«له مستهلك هنا»** لا «الملف موجود». **الاقتراحات الجديدة اليوم بـ[`_template/roadmap.md`](roadmap.md)** |
| [`_template/archive/sync_design_spec.md`](archive/sync_design_spec.md) | ◐ **يصف التصميم لا الكود.** `modules/sync/` صار **يدفع ويسحب** على مثال `notes` حيّ (P0→P3)، والناقص: الملفات · Manifest · الخلفية. الحالة والمراحل: [`_template/sync/PLAN.md`](sync/PLAN.md) |
| [`_template/archive/realtime_design.md`](archive/realtime_design.md) | ❌ **غير مبنيّ** — لا `lib/modules/realtime/` أصلاً. ولا تخلطه بـ`modules/multi_device/` المبنيّ |
| [`_template/archive/sync_system_guide.md`](archive/sync_system_guide.md) | جولة تعريفية بالإنجليزية على موديول المزامنة — كانت بجوار الكود (`lib/modules/sync/`) |

> ⛔ **وما تحت `_template/archive/` لا يُصان.** صحيحٌ **عن تاريخه** وقد لا يصف الكود اليوم،
> ولا يُصحَّح بتعديل صفوفه: سجلٌّ يُعاد كتابته يفقد قيمته الوحيدة — أنه يقول ما كان
> صحيحاً حين كُتب. الانحراف يُعلَّق عليه بلافتة، لا يُمحى.

