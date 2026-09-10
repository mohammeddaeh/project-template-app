import 'package:sqflite/sqflite.dart';

import 'sync_database.dart';

/// **متى نجحت آخر دورة مزامنة** — السطر الذي لم يكن أحدٌ يكتبه.
///
/// ## العَرَض الذي وُلد منه
///
/// بطاقة «المزامنة» تعرض «آخر مزامنة ناجحة: ٢٠٢٦/٠٨/١٦ — ٠٨:١٢» بالتصميم،
/// وكانت تعرض «لم تتم أي مزامنة بعد» **أبداً** بالمسار المحلي — بعد كل مزامنة
/// ناجحة، وبعد مئة منها. لأن `SyncOverview.lastSyncedAt` كانت تُملأ `null`
/// حرفياً: لا شيء بالموديول كلّه يسجّل انتهاء دورة.
///
/// و`synced_entities.last_synced_at` لا تجيب السؤال: تقول متى وصل **صفٌّ**
/// الخادمَ، فتُعطي أحدثَ صفٍّ لا أحدثَ دورة. وجهازٌ لم يكن لديه ما يرفع لكنه
/// اتّصل وسحب بنجاح لم يكن ليُسجّل شيئاً إطلاقاً — وهي الحالة الأكثر شيوعاً.
///
/// ## و«ناجحة» تعني بلا إخفاق واحد
///
/// لا «انتهت الدورة» ولا «وصل شيءٌ ما». دورةٌ دفعت تسعة صفوف وأخفقت بالعاشر
/// **ليست** مزامنةً ناجحة: المستخدم يقرأ الوقت المعروض إقراراً بأن عمله كلّه
/// هناك، ويحذف التطبيق بناءً عليه. راجع `SyncEngine._runCycle`.
///
/// ## ولماذا `sync_meta` لا `PersistenceKeys`
///
/// نفس سبب `SyncCursorStore` حرفياً — راجع رأسه: موديولٌ يكتب مفتاحاً بـ`core/`
/// هو اتجاه التبعية الذي يمنعه `CLAUDE.md`، وهو ما يترك يتيماً بقلب التطبيق
/// يوم يُحذف الموديول.
class SyncCycleStamp {
  const SyncCycleStamp(this._database);

  final SyncDatabase _database;

  static const _table = 'sync_meta';
  static const _key = 'last_successful_cycle_at_ms';

  /// `null` قبل أول دورةٍ نجحت على هذا الجهاز — وهي الحالة التي تُقرأ «لم تتم
  /// أي مزامنة بعد»، بحقٍّ هذه المرّة.
  Future<DateTime?> read() async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      where: 'meta_key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final millis = int.tryParse('${rows.first['meta_value']}');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// يُختم **بعد** انتهاء الدورة، لا عند بدئها.
  Future<void> markSuccess() async {
    final db = await _database.database;
    await db.insert(_table, {
      'meta_key': _key,
      'meta_value': '${DateTime.now().millisecondsSinceEpoch}',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// يُنسى الختم — لتبديل الحساب و«مسح البيانات المحلية»، مع
  /// `SyncCursorStore.clearAll`. وقتُ مزامنةٍ لحسابٍ آخر أسوأ من لا وقت.
  Future<void> clear() async {
    final db = await _database.database;
    await db.delete(_table, where: 'meta_key = ?', whereArgs: [_key]);
  }
}
