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
  /// `padding.bottom` لا `viewPadding.bottom`: الأولى تعرف ما **يحجب** الجسد
  /// فعلاً. داخل تبويبٍ بالقشرة صفرٌ (الجسد ينتهي عند الشريط — R15)، وبشاشةٍ
  /// مدفوعةٍ فوقها شريطُ إيماءات النظام.
  ///
  /// ```dart
  /// ListView(
  ///   padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + context.bottomContentInset),
  /// )
  /// ```
  ///
  /// **لا يُحلّ بـ`SizedBox` في آخر القائمة**: رقمٌ مُخمَّن لا يعرف ما تحته،
  /// ويبقى فراغاً ميتاً حيث لا شيء يحجب. الحشوة تخصّ القائمة نفسها.
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
