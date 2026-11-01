# Showcase Module — جولة المطوّر

جولةٌ بتبويب الرئيسية تعرض ما بناه القالب **بالودجات الحقيقية**: الأزرار والشارات ·
الإدخال (والهزّة عند خطأ التحقّق) · الحالات والتحميل · الحركة · التاريخ والأرقام من
الكتالوج · مبدّلَي المظهر واللغة. كل بطاقةٍ تتمدّد إلى صفحتها (`AppOpenContainer`)،
وفوق كل مثالٍ اسمُ ما يُكتب بالكود. **لا تحتاج خادماً.**

## الحالة الافتراضية — مُشعَل

```dart
// lib/core/platform/features/app_features.dart
static const showcase = true;
```

مشروعٌ جديد يفتح على الجولة، فيرى المطوّر ما هو مبنيٌّ قبل أن يكتبه ثانيةً.
والجولة تُرسم بدل جسد `HomeScreen` الافتراضيّ — لا مسار لها ولا تسجيل DI.

## الإطفاء — حين تصل رئيسية المشروع

1. `static const showcase = false;`
2. احذف `lib/modules/showcase/` و`test/modules/showcase_test.dart`.
3. بـ`lib/features/home/presentation/pages/home_screen.dart`: احذف سطرَي
   الاستيراد (`app_features` · `showcase_view`) والشرطَ بـ`body:` — أو استبدل الجسد
   كاملاً برئيسية المشروع.
4. بـ`lib/modules/modules_bootstrap.dart`: احذف الاستيراد والكتلة
   `if (AppFeatures.showcase)`.
5. احذف العلَم من `app_features.dart`، ومفاتيح `showcase*` من
   `assets/translations/*.json`، ثم `dart run scripts/gen_code.dart`.

`dart run scripts/prune_project.dart` يعرض الموديول حين يكون علَمه مطفأً.

## إضافة مثال

قسمٌ جديد = قيمةٌ بـ`ShowcaseSection` (`presentation/showcase_section.dart`) + ودجةٌ
بـ`presentation/sections/`، كلُّ مثالٍ فيها بـ`DemoBlock(code: …)`. واختبار الرسم
بـ`test/modules/showcase_test.dart` يمرّ على الأقسام وحده.
