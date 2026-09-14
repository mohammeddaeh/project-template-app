// ignore_for_file: avoid_print
/// يفحص قواعد بنية الواجهة آلياً — `F04` · `F10` · `F13` · `F19`…`F23`.
///
/// وُجد لأن قاعدةً بلا فاحص اقتراحٌ لا قاعدة (R30). كل ما يفحصه هنا **لا يراه**
/// `dart analyze` ولا `flutter test`: صفحةٌ بألف سطر تُصرَّف، و`Color(0xFF...)`
/// يُرسم، ونصٌّ عربي مكتوبٌ بالكود يظهر — والعطل يصل المستخدم وحده.
///
/// تشغيل:
///   dart run scripts/check_structure.dart             — يفشل بمخالفة جديدة
///   dart run scripts/check_structure.dart --stats     — أرقام بلا فشل
///   dart run scripts/check_structure.dart --baseline  — يثبّت الدَّين القائم
///
/// ## الأساس (baseline)
///
/// أُدخل الفاحص على قالبٍ قائم فوجد ٧٢ مخالفة، كلها سابقة له. إصلاحها دفعةً
/// واحدة refactor واسع يخالف R31؛ وتجاهلها يجعل الفاحص عديم المعنى.
///
/// فـ`.structure_baseline.txt` **يُلتزَم بالمستودع** ويُسجّل ما كان يوم
/// الإدخال: المسجَّل يُعرَض ولا يُفشِل، وأي مخالفة **جديدة** تُفشِل. فلا يزيد
/// الدَّين، ويُحرَق حين يُلمَس الملف لسببٍ آخر.
///
/// والمفتاح بلا رقم سطر عمداً: إضافةُ سطرٍ فوق مخالفة قديمة لا تُفشِل بناءً
/// كان أخضر.
///
/// ### الأساس لا يُعاد توليده لإسكات مخالفة جديدة
///
/// ذلك يحوّله من سجلّ دَينٍ إلى زرّ تجاهل، ومن يفعلها مرّةً يفعلها دائماً.
/// والحارس العملي أن **تراجع الفرق**:
///
/// ```bash
/// dart run scripts/check_structure.dart --baseline
/// git diff .structure_baseline.txt        # يجب أن يكون حذفاً صرفاً
/// ```
///
/// سطرٌ **مضاف** يعني أنك أسكتّ مخالفةً جديدة لا أنك حرقتَ دَيناً. وقع هذا
/// فعلاً: أُصلحت `_buildIcon` بـ`main_shell_screen.dart` (حذفٌ سليم)، وبنفس
/// اللحظة أُضيف `DecoratedBox` بالصفحة نفسها — فأعاد التوليد حذفَ سطرٍ
/// **وإضافةَ آخر**، وبقي العدد ثابتاً وكأن شيئاً لم يحدث. الفرق وحده كشفه،
/// وأُصلحت المخالفة بـ`BrandNavBar` بدل تسجيلها.
library;

import 'dart:io';

// ── الحدود ────────────────────────────────────────────────────────────────────

/// أسطر **الكود** بملف صفحة — التعليقات والفراغات لا تُحسب، فالتوثيق لا يُعاقَب.
const _maxPageCodeLines = 200;

/// أسطر الكود داخل `build()` بأي ملف صفحة.
const _maxBuildCodeLines = 50;

const _generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.config.dart',
];
const _skipDirs = ['lib/resources/', 'lib/modules/', 'lib/routes/'];

const _baselineFile = '.structure_baseline.txt';

// ── نتيجة ─────────────────────────────────────────────────────────────────────

class _Violation {
  _Violation(this.rule, this.file, this.line, this.message);
  final String rule;
  final String file;
  final int line;
  final String message;
}

final List<_Violation> _violations = [];
int _filesScanned = 0;

void _flag(String rule, String file, int line, String message) =>
    _violations.add(_Violation(rule, file, line, message));

// ── نقطة الدخول ───────────────────────────────────────────────────────────────

void main(List<String> args) {
  final statsOnly = args.contains('--stats');
  final writeBaseline = args.contains('--baseline');

  print('\n🏗   check_structure — قواعد بنية الواجهة\n');

  final files = _dartFilesUnder('lib');
  final barrelExports = _readBarrelExports();

  for (final file in files) {
    final path = _rel(file.path);
    if (_isGenerated(path) || _isSkipped(path)) continue;
    _filesScanned++;

    final raw = file.readAsLinesSync();
    final code = _stripComments(raw);

    _checkNoRawColors(path, code);
    _checkNoBuildMethods(path, code);
    _checkOneProgressWidget(path, code);
    _checkOneTextField(path, code);
    _checkDirectionality(path, code);
    _checkHardcodedArabic(path, code);
    _checkResponsiveNumbers(path, code);

    if (_isPage(path)) _checkPage(path, code);
    if (_isSharedWidget(path)) _checkSharedWidget(path, code, barrelExports);
  }

  if (writeBaseline) {
    _writeBaseline();
    return;
  }
  _report(statsOnly: statsOnly);
}

/// المفتاح **بلا أرقام** — لا رقم سطر، ولا الأعداد داخل الرسالة.
///
/// رقم السطر يُستبعَد وإلا أفشل كلُّ سطرٍ يُضاف فوق مخالفة قديمة بناءً أخضر.
///
/// والأعداد **داخل الرسالة** تُستبعَد لسببٍ اكتُشف بالاستعمال: رسالة F19 تحمل
/// عدد الأسطر («build() فيه 70 سطر»)، فحُذفت صفوفٌ من شاشة فصار العدد 61 —
/// **فبدا تحسينٌ مخالفةً جديدة وأفشل البناء**. وهذا يدفع بالضبط إلى ما تمنعه
/// R30: إعادةُ توليد الأساس لإسكات ما ليس جديداً.
String _key(_Violation v) {
  final shape = v.message.replaceAll(RegExp(r'\d+'), '#');
  return '${v.rule}|${v.file}|$shape';
}

Set<String> _readBaseline() {
  final file = File(_baselineFile);
  if (!file.existsSync()) return {};
  return file
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

void _writeBaseline() {
  final keys = _violations.map(_key).toSet().toList()..sort();
  final buf = StringBuffer()
    ..writeln('# مخالفات بنية مسجَّلة — دَينٌ سابقٌ للفاحص، لا إذنٌ بالمزيد.')
    ..writeln('# تُعرَض ولا تُفشِل. وأي مخالفة جديدة تُفشِل البناء.')
    ..writeln('# لا يُعاد توليده لإسكات مخالفة جديدة (R30).')
    ..writeln('# التوليد: dart run scripts/check_structure.dart --baseline')
    ..writeln('#');
  for (final k in keys) {
    buf.writeln(k);
  }
  File(_baselineFile).writeAsStringSync(buf.toString());
  print('OK  $_baselineFile  <-  ${keys.length} مخالفة مسجَّلة.');
  print('    كل مخالفة جديدة بعد الآن تُفشِل البناء.');
}

// ── الفحوص ────────────────────────────────────────────────────────────────────

/// F04 — لا hex خام، ولا `AppPalette` خارج `app_colors.dart`.
void _checkNoRawColors(String path, List<String?> code) {
  if (path.endsWith('lib/ui/theme/app_colors.dart') ||
      path.endsWith('lib/ui/theme/app_palette.dart')) {
    return;
  }
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    if (RegExp(r'Color\(0x').hasMatch(line)) {
      _flag('F04', path, i + 1, 'لون خام — مرّره عبر AppPalette ثم AppColors');
    }
    if (RegExp(r'\bAppPalette\.').hasMatch(line)) {
      _flag('F04', path, i + 1, 'AppPalette لا يُستورد خارج app_colors.dart');
    }
    if (RegExp(r'\bColors\.(?!transparent\b)[a-z]').hasMatch(line)) {
      _flag('F04', path, i + 1, 'لون Material جاهز — استعمل context.colors.X');
    }
  }
}

/// F35 — مؤشّر التقدّم واحدٌ: `AppProgress` وحده يلمس ويدجت الإطار.
///
/// بلا هذا الفاحص يعود التفاوت بأول شاشة جديدة: `strokeWidth` مختلف، ولون جذعٍ
/// خامس، وشريطٌ بلا تدرّج التصميم. ولا `dart analyze` يراه — كلّها استدعاءات
/// سليمة — ولا الاختبارات، فالفرق بالبكسل لا بالسلوك.
void _checkOneProgressWidget(String path, List<String?> code) {
  if (path.endsWith('lib/ui/widgets/indicators/app_progress.dart')) return;
  final banned = RegExp(
    r'\b(CircularProgressIndicator|LinearProgressIndicator'
    r'|RefreshProgressIndicator|CupertinoActivityIndicator)\b',
  );
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    if (banned.hasMatch(line)) {
      _flag(
        'F35',
        path,
        i + 1,
        'مؤشّر إطارٍ خام — استعمل AppProgress.circular/linear (21_WIDGETS_USAGE §33)',
      );
    }
  }
}

/// F36 — حقل الإدخال واحدٌ: `CustomTextField` وحده يلمس `TextField` الإطار.
///
/// **السبب سلوكٌ لا شكل.** Flutter لا يُلغي الفوكس عند لمسة إصبعٍ خارج الحقل
/// على أندرويد وiOS — يفعلها للفأرة والقلم وسطح المكتب فقط
/// (`_DefaultEditableTextTapOutsideAction`). فكل حقلٍ خام يعني كيبورداً يبقى
/// مفتوحاً فوق الشاشة، ولا `dart analyze` يراه: الاستدعاء سليم تماماً.
///
/// وقد وقع فعلاً: `onTapOutsideDismissTheKeyboard` كانت موجودة بـ
/// `CustomTextField` وافتراضها `false`، **ولم يمرّرها ولا موضع** من ٢٧ ملفاً
/// يحمل إدخالاً — فشُحنت القدرة مطفأة. الحلّ أن يقرّر الحقل، وأن يمنع الفاحص
/// وُلادة حقلٍ خارجه.
void _checkOneTextField(String path, List<String?> code) {
  // مكتبة الإدخال هي الموضع الوحيد الذي يلمس ويدجت الإطار.
  if (path.startsWith('lib/ui/widgets/inputs/')) return;
  final banned = RegExp(r'\b(TextField|TextFormField)\s*\(');
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    // `CustomTextField(` تنتهي بـ`TextField(` — لا تُحسب عليها.
    if (RegExp(r'\bCustomTextField\s*\(').hasMatch(line)) continue;
    if (banned.hasMatch(line)) {
      _flag(
        'F36',
        path,
        i + 1,
        'حقل إدخال خام — استعمل CustomTextField (21_WIDGETS_USAGE §5)',
      );
    }
  }
}

/// F20 — كل قسم بصري ودجةٌ باسمها، لا دالةٌ تُعيد `Widget`.
void _checkNoBuildMethods(String path, List<String?> code) {
  if (!path.startsWith('lib/features/') && !path.startsWith('lib/ui/')) return;
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    final m = RegExp(
      r'^\s*(?:static\s+)?Widget\s+(_?\w+)\s*\(',
    ).firstMatch(line);
    if (m == null) continue;
    final name = m.group(1)!;
    if (name == 'build') continue;
    _flag(
      'F20',
      path,
      i + 1,
      'دالة تُعيد Widget (`$name`) — اجعلها صنفاً يمتدّ StatelessWidget',
    );
  }
}

/// F10 — لا `left`/`right`، والاتجاهيّ وحده. ولا `ltr:` مفروض بلا سبب.
void _checkDirectionality(String path, List<String?> code) {
  if (!path.startsWith('lib/features/') && !path.startsWith('lib/ui/')) return;
  const banned = {
    r'EdgeInsets\.only\([^)]*\b(left|right):':
        'EdgeInsetsDirectional.only(start/end:)',
    r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)':
        'AlignmentDirectional.*Start/End',
    r'BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight):':
        'BorderRadiusDirectional.only(topStart/…)',
  };
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    banned.forEach((pattern, fix) {
      if (RegExp(pattern).hasMatch(line)) {
        _flag('F10', path, i + 1, 'اتجاه ثابت — استعمل $fix');
      }
    });
    if (RegExp(r'\bltr:\s*true').hasMatch(line)) {
      _flag(
        'F10',
        path,
        i + 1,
        'ltr: true — الحقل يتبع اتجاه الصفحة إلا لقيمة يكسرها bidi فعلاً',
      );
    }
    // ❌ **لا فحص آلي لـ`CrossAxisAlignment.end`** — جُرِّب وأُزيل.
    //
    // معناها يعتمد على أب الودجة: بـ`Column` محورٌ أفقي (يمين/يسار)، وبـ`Row`
    // محورٌ رأسي (أعلى/أسفل). والفاحص يقرأ سطراً سطراً ولا يعرف الأب، فأبلغ
    // عن خمسة مواضع سليمة — أزرارِ حوارٍ تُحاذى للنهاية بحقّ، ولافتةِ حقلٍ
    // تُحاذى لأسفل الصفّ.
    //
    // وفاحصٌ لا يميّز الصواب من الخطأ **أسوأ من لا فاحص**: يُدرَّب عليه
    // الناس فيتجاهلونه، فيمرّ معه ما كان يمسكه. هذا الوجه من F10-م مراجعةٌ
    // بشرية (👁) لا قاعدةٌ مفروضة (🔒).
  }
}

/// F13 — كل نصّ ظاهر مفتاح ترجمة، لا سلسلة عربية بالكود.
void _checkHardcodedArabic(String path, List<String?> code) {
  if (!path.startsWith('lib/features/') && !path.startsWith('lib/ui/')) return;
  final arabicInString = RegExp('''["'][^"']*[؀-ۿ][^"']*["']''');
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    if (line.contains('ignore:') || line.contains('debugPrint')) continue;
    if (arabicInString.hasMatch(line)) {
      _flag('F13', path, i + 1, 'نصّ عربي بالكود — LocaleKeys.x.tr()');
    }
  }
}

/// F37 — لا نسبةَ من مقاس الشاشة كمسافة، ولا قفلَ اتجاهٍ خارج مكانه.
///
/// **فاحصان دقيقان لا فاحصٌ شامل** — وهذا قرار. الشكل العامّ للقاعدة هو «كل
/// رقمِ تخطيطٍ يمرّ بـ`context.screen`»، وفحصُه آلياً يعني الإبلاغ عن كل
/// `SizedBox(height: 16)` بالمستودع: مئاتُ الأسطر، أغلبُها سليمٌ بسياقه
/// (حشوةٌ داخل ودجةٍ صغيرة، فاصلٌ ثابت بالتصميم). وفاحصٌ يصرخ من كل مكان
/// يُدرَّب الناس على تجاهله، فيمرّ معه ما كان يمسكه — وهو ما يحذّر منه R30
/// نفسُه بشقّه الثاني.
///
/// فالمفحوصان هنا هما ما **لا سياقَ يجعله صحيحاً**:
///
/// **١ — `context.sh * ‹عدد›` مسافةً.** النسبةُ من ارتفاع الشاشة لا تتقلّص مع
/// الكيبورد، فتدفع أسفلَ المحتوى خارج الحدّ. وقع بشاشة الدخول فعلاً. ويبقى
/// `context.sh` مسموحاً **بلا ضرب** (قياسُ شاشةٍ حقيقيّ: سقفُ ورقةٍ سفلية).
///
/// **٢ — `setPreferredOrientations` خارج `OrientationPolicy`.** قرارُ الاتجاه
/// مركزيّ: قفلُ الجميع عمودياً يحبس اللوحَ بنافذةٍ بنسبة هاتف بشريطَين
/// أسودَين، ولا يُصلحه أيُّ تخطيطٍ بالداخل.
void _checkResponsiveNumbers(String path, List<String?> code) {
  if (!path.startsWith('lib/features/') && !path.startsWith('lib/ui/')) return;
  // الطبقة نفسها تشرح البديل بتوثيقها وتقيس به — فلا تُفحص بقاعدتها.
  if (path.startsWith('lib/ui/responsive/')) return;

  final screenRatio = RegExp(r'context\.s[hw]\s*\*');
  // **القيدُ ليس مسافة.** `maxHeight: context.sh * 0.85` سقفُ ورقةٍ سفلية —
  // قياسُ شاشةٍ حقيقيّ، وهو الاستعمال الذي تبقى `context.sh` من أجله. والقاعدة
  // تخصّ الفراغَ والمقاسَ وحدهما.
  final constraint = RegExp(r'Constraints|max(Height|Width)|min(Height|Width)');
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    if (line.contains('ignore:')) continue;
    if (constraint.hasMatch(line)) continue;
    if (screenRatio.hasMatch(line)) {
      _flag(
        'F37',
        path,
        i + 1,
        'نسبةٌ من مقاس الشاشة مسافةً — ResponsiveGap(24) أو context.screen.space(24)',
      );
    }
    if (line.contains('setPreferredOrientations')) {
      _flag(
        'F37',
        path,
        i + 1,
        'قفلُ اتجاهٍ خارج مكانه — القرار بـOrientationPolicy وحدها',
      );
    }
  }
}

/// F19 — الصفحة تُنسّق ولا ترسم.
void _checkPage(String path, List<String?> code) {
  final codeLines = code.where((l) => l != null && l.trim().isNotEmpty).length;
  if (codeLines > _maxPageCodeLines) {
    _flag(
      'F19',
      path,
      1,
      'الملف $codeLines سطر كود (الحدّ $_maxPageCodeLines) — اقتطع أقساماً إلى presentation/widgets/',
    );
  }

  final buildLines = _buildBodyLineCount(code);
  if (buildLines != null && buildLines > _maxBuildCodeLines) {
    _flag(
      'F19',
      path,
      1,
      'build() فيه $buildLines سطر كود (الحدّ $_maxBuildCodeLines)',
    );
  }

  const drawing = {
    'BoxDecoration': 'انقله إلى ودجة مسمّاة',
    'BoxShadow': 'انقله إلى ودجة مسمّاة',
    'LinearGradient': 'انقله إلى ودجة مسمّاة',
    'RadialGradient': 'انقله إلى ودجة مسمّاة',
  };
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    drawing.forEach((token, fix) {
      if (line.contains(token)) {
        _flag('F19', path, i + 1, 'الصفحة ترسم ($token) — $fix');
      }
    });
  }
}

/// F21 — الودجة العامة لا تعرف feature، وتُصدَّر من الباريل.
void _checkSharedWidget(String path, List<String?> code, Set<String> barrel) {
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    if (RegExp(r"import\s+'package:app_template/features/").hasMatch(line)) {
      _flag(
        'F21',
        path,
        i + 1,
        'ودجة عامة تستورد feature — مرّر البيانات وسائطَ أو أبقها محلّية',
      );
    }
  }

  final relative = path.substring('lib/ui/widgets/'.length);
  if (!barrel.contains(relative)) {
    _flag(
      'F21',
      path,
      1,
      'غير مُصدَّرة من widgets.dart — أضف: export \'$relative\';',
    );
  }
}

// ── أدوات ─────────────────────────────────────────────────────────────────────

/// يُعيد أسطر الكود، و`null` لكل سطر تعليقٍ أو فراغ.
///
/// التعليقات تُستبعَد قبل كل فحص: توثيقٌ عربي غزير بهذا المستودع، وفحصُ
/// «نصّ عربي بالكود» عليه يجعل الفاحص يصرخ من كل ملف موثَّق جيداً.
List<String?> _stripComments(List<String> lines) {
  final out = <String?>[];
  var inBlock = false;
  for (final line in lines) {
    var l = line;
    if (inBlock) {
      final end = l.indexOf('*/');
      if (end == -1) {
        out.add(null);
        continue;
      }
      l = l.substring(end + 2);
      inBlock = false;
    }
    final blockStart = l.indexOf('/*');
    if (blockStart != -1) {
      inBlock = !l.substring(blockStart).contains('*/');
      l = l.substring(0, blockStart);
    }
    final trimmed = l.trimLeft();
    if (trimmed.startsWith('///') || trimmed.startsWith('//')) {
      out.add(null);
      continue;
    }
    final slash = _indexOfLineComment(l);
    if (slash != -1) l = l.substring(0, slash);
    out.add(l.trim().isEmpty ? null : l);
  }
  return out;
}

/// موضع `//` خارج السلاسل النصية — وإلا قُصّ `'https://…'` نصفين.
int _indexOfLineComment(String line) {
  var inSingle = false;
  var inDouble = false;
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (c == "'" && !inDouble) inSingle = !inSingle;
    if (c == '"' && !inSingle) inDouble = !inDouble;
    if (!inSingle && !inDouble && c == '/' && line[i + 1] == '/') return i;
  }
  return -1;
}

/// أسطر الكود داخل جسد `build()` — بعدّ الأقواس لا بالتقدير.
int? _buildBodyLineCount(List<String?> code) {
  var start = -1;
  for (var i = 0; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    if (RegExp(r'Widget\s+build\s*\(\s*BuildContext').hasMatch(line)) {
      start = i;
      break;
    }
  }
  if (start == -1) return null;

  var depth = 0;
  var started = false;
  var count = 0;
  for (var i = start; i < code.length; i++) {
    final line = code[i];
    if (line == null) continue;
    for (final c in line.split('')) {
      if (c == '{') {
        depth++;
        started = true;
      } else if (c == '}') {
        depth--;
      }
    }
    if (started) count++;
    if (started && depth == 0) return count;
  }
  return count;
}

Set<String> _readBarrelExports() {
  final file = File('lib/ui/widgets/widgets.dart');
  if (!file.existsSync()) return {};
  final out = <String>{};
  for (final line in file.readAsLinesSync()) {
    final m = RegExp(r"^\s*export\s+'([^']+)'").firstMatch(line);
    if (m != null) out.add(m.group(1)!);
  }
  return out;
}

bool _isPage(String path) =>
    path.startsWith('lib/features/') &&
    path.contains('/presentation/pages/') &&
    path.endsWith('.dart');

bool _isSharedWidget(String path) =>
    path.startsWith('lib/ui/widgets/') && !path.endsWith('widgets.dart');

bool _isGenerated(String path) =>
    _generatedSuffixes.any((s) => path.endsWith(s));

bool _isSkipped(String path) => _skipDirs.any(path.startsWith);

List<File> _dartFilesUnder(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) {
    print('❌  $dir/ غير موجود — شغّل من جذر المشروع.');
    exit(1);
  }
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _rel(String p) => p.replaceAll('\\', '/');

// ── التقرير ───────────────────────────────────────────────────────────────────

void _report({required bool statsOnly}) {
  print('   فُحص $_filesScanned ملفاً.\n');

  final baseline = _readBaseline();
  final fresh = _violations.where((v) => !baseline.contains(_key(v))).toList();
  if (baseline.isNotEmpty) {
    final known = _violations.length - fresh.length;
    print('   دَينٌ مسجَّل: $known مخالفة ($_baselineFile).');
  }

  if (fresh.isEmpty) {
    print('✅  لا مخالفات جديدة.\n');
    return;
  }

  final byRule = <String, List<_Violation>>{};
  for (final v in fresh) {
    byRule.putIfAbsent(v.rule, () => []).add(v);
  }

  final rules = byRule.keys.toList()..sort();
  for (final rule in rules) {
    final list = byRule[rule]!;
    print('── $rule  (${list.length}) ${'─' * 50}');
    for (final v in list) {
      print('   ${v.file}:${v.line}');
      print('      ${v.message}');
    }
    print('');
  }

  print('   جديدة: ${fresh.length} مخالفة.');
  print('   القواعد: readme/05_FIGMA_TO_PAGE.md\n');

  if (!statsOnly) exit(1);
}
