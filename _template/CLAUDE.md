# CLAUDE.md — صيانة القالب نفسه (`_template/`)

> **يُقرأ مع [`../CLAUDE.md`](../CLAUDE.md) لا بدلاً منه.** `_template/` لا يُنسخ إلى أي مشروع
> (`new_project.ps1` يستثنيه)، والقاعدة R38 لا تسري عليه: التاريخ مكانه هنا. فيه ما يخصّ
> القالبَ كمنتج: خطّته وأرشيفه وما تعلّمناه من المشاريع. ولذلك **كلُّ رابط Markdown
> إليه من خارجه رابطُ GitHub كامل** (`github.com/mohammeddaeh/project-template-app/blob/master/_template/…`)
> لا مسارٌ نسبيّ، فيعمل من أي مشروع. والإشارةُ النصّية بتعليقات الكود (`_template/roadmap.md` بند #08) تبقى نصّاً.

## Mandatory Documentation Sync

| الملف | متى يُحدَّث |
|---|---|
| **`_template/CHANGELOG.md`** + `TEMPLATE_VERSION` | **أي تغييرٍ يمسّ مشروعاً مبنيّاً** — بندٌ تحت «غير مُصدَر»؛ والإصدار يرفع الرقم ويضع وسم `v<الرقم>` |
| `_template/README.md` | فهرس المجلد — يُحدَّث عند إضافة/حذف/نقل أي ملف فيه، بنفس التغيير |
| **`_template/roadmap.md`** | **إضافة اقتراح تطويري جديد أو تغيير حالة اقتراح موجود** — حلّ محلّ `_template/archive/template_enhancements.md` المؤرشَف (2026-09-13) لهذا الغرض |
| `_template/archive/integration_audit.md` | أي تغيير في عقد الـwire بين الفرونت والباك |
| `_template/archive/sync_design_spec.md` | ⛔ **لا يُصان** — أرشيف. حالةُ الموديول بـ`lib/modules/sync/STATUS.md` |
| `_template/archive/**` | ⛔ **لا يُصان** — سجلّات مؤرَّخة. الانحراف يُعلَّق عليه بلافتة، لا يُمحى |
| `_template/archive/realtime_design.md` | أي خطوة نحو بناء `modules/realtime/` (غير موجود اليوم) |
| `_template/sync/PLAN.md` | **إنهاء أي مرحلة P0–P9** — المرحلة والتاريخ ومعيار القبول، **ومعه `lib/modules/sync/STATUS.md`**. ويُحدَّث معه سجلّ النقل بـ`Qirtas/qirtas_app/lib/modules/sync/PORT_STATUS.md` |
| **`_template/feedback/<مشروع>.md`** | **تطبيق بندٍ من ملاحظات مشروعٍ على القالب** — حالة البند (✅ بالتاريخ والـcommit، أو ✖️ بالسبب)، وملفُّ المشروع الجديد يُضاف لجدول [`_template/feedback/README.md`](feedback/README.md) |
