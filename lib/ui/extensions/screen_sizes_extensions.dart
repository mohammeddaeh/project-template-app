import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get sw => MediaQuery.of(this).size.width;

  double get sh => MediaQuery.of(this).size.height;

  EdgeInsets get screenPadding => MediaQuery.of(this).padding;

  /// ارتفاع الكيبورد الظاهر الآن — صفر حين يكون مغلقاً.
  ///
  /// **اسمٌ واحد لقيمة واحدة**: كانت لها ثلاث تسميات (`keyboardHeight` ·
  /// `bottomInsetsPadding` · قراءة `viewInsets` مباشرة)، واثنتان منها **بلا أي
  /// مستدعٍ** — وهكذا بقيت الصحيحة غير مستعملة بينما كانت الأوراق السفلية تحشو
  /// بـ[bottomPadding] (شريط الإيماءات) وتُخفي آخر حقل خلف الكيبورد.
  ///
  /// يُقرأ **داخل `build`** لا عند فتح الورقة: القيمة تتغيّر مع كل إطار من
  /// ظهور الكيبورد، فقراءتها مرة واحدة تُجمّدها على صفر.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  /// شريط الإيماءات/الأزرار الخاص بالنظام فقط.
  ///
  /// **ليس** ما تحتاجه قائمة قابلة للتمرير داخل تبويب — راجع [bottomContentInset].
  double get bottomPadding => MediaQuery.of(this).viewPadding.bottom;

  /// المسافة التي يجب أن ينتهي عندها **محتوى قابل للتمرير** حتى يُرى آخره كاملاً.
  ///
  /// يشمل شريط النظام **وأي شريط تنقّل سفلي** فوقه. الفرق جوهري:
  ///
  /// | | يقيس | داخل تبويب |
  /// |---|---|---|
  /// | `viewPadding.bottom` ([bottomPadding]) | شريط النظام وحده | ~٢٤ بكسل |
  /// | `padding.bottom` (هنا) | + `NavigationBar` | ~١٠٠ بكسل |
  ///
  /// السبب: `MainShellScreen` يستخدم `extendBody: true`، فيمتدّ الـbody **خلف**
  /// شريط التنقّل. وFlutter يعوّض ذلك بحقن ارتفاع الشريط في `padding.bottom`
  /// الخاص بالـbody — وهي القيمة الوحيدة التي تعرف أن الشريط هناك.
  ///
  /// ```dart
  /// ListView(
  ///   padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + context.bottomContentInset),
  /// )
  /// ```
  ///
  /// **لا يُحلّ بـ`SizedBox` في آخر القائمة**: ذلك يحشو مسافة برقم مُخمَّن لا
  /// يعرف ارتفاع الشريط الفعلي، ويبقى ظاهراً كفراغ ميت بالشاشات التي لا شريط
  /// تحتها. الحشوة تخصّ القائمة نفسها، لا عنصراً زائداً بداخلها.
  ///
  /// **ولا بـ`SafeArea`**: الشِّل كان يحمل تعليقاً يقول إن الشاشات الفرعية
  /// «محميّة بـ`SafeArea`» — وهو ادّعاء لم يكن صحيحاً لأيٍّ منها بمشروع حقيقي
  /// بُني على هذا القالب، فكان آخر عنصر بكل تبويب يقع خلف الشريط نهائياً. والعطل
  /// صامت تماماً: الشاشة تُبنى وتُمرَّر ولا يُرمى شيء — تكتفي بألّا تُظهر آخرها.
  /// لذلك السلوك مثبَّت بـ`test/bottom_content_inset_test.dart` لا بالمراجعة.
  double get bottomContentInset => MediaQuery.of(this).padding.bottom;

  double get topPadding => MediaQuery.of(this).viewPadding.top;

  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  EdgeInsets get topEdgeInsetsPaddings =>
      EdgeInsets.only(top: MediaQuery.of(this).viewPadding.top);

  EdgeInsets get bottomEdgeInsetsPaddings =>
      EdgeInsets.only(bottom: MediaQuery.of(this).viewPadding.bottom);

  EdgeInsets get safeAreaEdgeInsetsPaddings => EdgeInsets.only(
    top: MediaQuery.of(this).viewPadding.top,
    bottom: MediaQuery.of(this).viewPadding.bottom,
  );
}
