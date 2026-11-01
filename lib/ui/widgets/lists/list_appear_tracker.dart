import 'package:app_template/ui/theme/app_motion.dart';

/// **أيُّ صفٍّ يظهر بحركة، ومتى** — لقائمةٍ تتغذّى صفحةً صفحة.
///
/// يملكه صاحبُ القائمة (حالةُ الودجة)، ويسأله عن كل صفٍّ تبنيه:
/// - صفٌّ **لم يُرَ** بعد يظهر بحركة، ويُسجَّل؛ والرجوع إليه بالتمرير يرسمه ثابتاً.
/// - التأخيرُ **داخل الدفعة التي وصلت**، لا من أول القائمة: الصفحة الثالثة
///   تتتابع من صفّها الأول، ولا ينتظر الصفُّ الأربعون ثانيتين.
/// - ولا يتأخّر أكثر من [AppMotion.staggerCap] صفاً.
///
/// [reset] عند التحديث (السحب للأسفل): القائمة الجديدة تُعرض كأنها أول مرّة.
class ListAppearTracker {
  final _played = <int>{};
  int _known = 0;
  int _batchStart = 0;

  /// يُنادى بكل بناءٍ للقائمة بطولها الحالي — يعرف منه بداية الدفعة الجديدة.
  void observeLength(int length) {
    if (length < _known) reset();
    if (length > _known) {
      _batchStart = _known;
      _known = length;
    }
  }

  /// `null` ⇐ يُرسم ثابتاً؛ وإلا ترتيبُه داخل دفعته (للتأخير).
  int? staggerFor(int index) {
    if (!_played.add(index)) return null;
    final position = index - _batchStart;
    return position < 0 ? 0 : position.clamp(0, AppMotion.staggerCap - 1);
  }

  void reset() {
    _played.clear();
    _known = 0;
    _batchStart = 0;
  }
}
