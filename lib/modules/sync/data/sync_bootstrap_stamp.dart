import 'package:sqflite/sqflite.dart';

import 'sync_database.dart';

/// **هل جُرد هذا الحساب على هذا الجهاز؟** — الختمُ الذي يفصل «أوّل دخول» عن
/// «إقلاعٌ عاديّ».
///
/// ## السؤال الذي لم يكن لأحدٍ جوابه
///
/// التطبيق يعمل بلا شبكة بحكم تصميمه، **إلا لحظةً واحدة**: الجرد الأوّل. وقبل
/// هذا الختم لم يكن بالجهاز ما يميّز الحالتين:
///
/// - جهازٌ سجّل الدخول وجُرد ⇒ يدخل مباشرةً، بلا شبكة، إلى بياناته.
/// - جهازٌ سجّل الدخول ولم يُجرد بعد ⇒ **يجب أن يُجرد قبل أن يُترك يعمل**، وإلا
///   خرج الموظّف إلى الميدان بجهازٍ فارغ يقول له كل تبويبٍ «لا يوجد اتصال».
///
/// و«سجّل الدخول» وحدها لا تجيب: التوكن يبقى صالحاً بعد إعادة التثبيت وبعد مسح
/// البيانات، وكلاهما يترك جهازاً بلا صفٍّ واحد.
///
/// ## ولماذا الختمُ **لكل حساب**
///
/// جهازٌ يتناوب عليه اثنان أمرٌ واقع بالميدان. وختمٌ عامّ يجعل الثاني يدخل على
/// «تمّ الجرد» — بينما ما بالجهاز مقاسمُ الأول. ومفتاحٌ لكل حساب يجعل الجواب
/// صادقاً بلا اعتمادٍ على مسحٍ قد يُنسى.
///
/// ⚠️ **وهذا ليس بديلاً عن مسح بيانات الحساب السابق.** الختم يمنع «دخولٌ ببيانات
/// الغير تبدو بياناتك»؛ ولا يمنع بقاءَ صفوف الأول بالقاعدة. ذاك مسارٌ مستقلّ
/// (مسحُ الخروج) لم يُبنَ بعد.
///
/// ## ولماذا `sync_meta` لا `PersistenceKeys`
///
/// نفس سبب `SyncCursorStore` و`SyncCycleStamp` حرفياً: موديولٌ يكتب مفتاحاً
/// بـ`core/` هو اتجاه التبعية الذي يمنعه `CLAUDE.md` — وهو ما يترك يتيماً بقلب
/// التطبيق يوم يُحذف الموديول. **وهنا أوثقُ منهما**: الختم يفقد معناه تماماً
/// بلا الجداول التي يصفها، فبقاؤه بعدها كذبٌ لا أثرٌ مهجور.
class SyncBootstrapStamp {
  const SyncBootstrapStamp(this._database);

  final SyncDatabase _database;

  static const _table = 'sync_meta';
  static const _prefix = 'bootstrap:';

  /// `null` لحسابٍ لم يُجرد على هذا الجهاز بعد.
  Future<DateTime?> read(String accountKey) async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      where: 'meta_key = ?',
      whereArgs: ['$_prefix$accountKey'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final millis = int.tryParse('${rows.first['meta_value']}');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// يُختم **بعد** أن يفرغ الجرد بلا كيانٍ مُخفق — لا عند بدئه.
  ///
  /// والفرق ليس تفصيلاً: ختمٌ يُكتب عند البدء يعني أن انقطاعاً بمنتصف التنزيل
  /// يُنتج جهازاً «مجروداً» بنصف بياناته، لا يعود إلى شاشة الجرد أبداً.
  Future<void> mark(String accountKey) async {
    final db = await _database.database;
    await db.insert(_table, {
      'meta_key': '$_prefix$accountKey',
      'meta_value': '${DateTime.now().millisecondsSinceEpoch}',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// يُنسى ختمُ حسابٍ بعينه — لـ«إعادة تنزيل بياناتي» ولمسح بيانات الحساب.
  Future<void> clear(String accountKey) async {
    final db = await _database.database;
    await db.delete(
      _table,
      where: 'meta_key = ?',
      whereArgs: ['$_prefix$accountKey'],
    );
  }

  /// يُنسى كلُّ ختم — لمسحٍ شامل للجهاز.
  Future<void> clearAll() async {
    final db = await _database.database;
    await db.delete(_table, where: 'meta_key LIKE ?', whereArgs: ['$_prefix%']);
  }
}
