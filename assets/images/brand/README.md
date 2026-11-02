# `assets/images/brand/` — هوية التطبيق

**ملفّان يُستبدلان، وكل شيءٍ آخر يتبعهما.** الشعار الحالي علامةٌ محايدة مؤقّتة.

| الملف | ما يُرسم منه | بعد استبداله |
|---|---|---|
| `app_logo.svg` | شاشة الإقلاع بأندرويد (متجهتان) · الشعار داخل التطبيق (شاشة الترحيب) | `dart run scripts/gen_splash_assets.dart` |
| `app_logo.png` | شاشة الإقلاع بـiOS | `dart run flutter_native_splash:create` |

ثم `dart run scripts/gen_code.dart`.

**شروط `app_logo.svg`** (يقرؤه `gen_splash_assets.dart` بنفسه):
- عناصر `<path d="…" fill="…">` وحدها، بأوامر مطلقة (`M L H V C Z`) — صدّره من
  الأداة بـ«تحويل الأشكال إلى مسارات»، وبلا `<style>` (`svg_inline_styles.dart`).
- ألوانه تُرسم كما هي **فوق `splash_background`** (`android/app/src/main/res/values/colors.xml`
  و`color` بـ`flutter_native_splash.yaml`) — فالشعار الفاتح يحتاج خلفيةً داكنة.

**و`app_logo.png`** بمقاس ١٣٢×١٣٢ بكسل (وهو مقاسه بالنقاط على iOS)، خلفيةٌ شفّافة.

**وأيقونة التطبيق** ليست هنا: `assets/app_icons/` لكل flavor — راجع `readme/start/01_SETUP.md`.
