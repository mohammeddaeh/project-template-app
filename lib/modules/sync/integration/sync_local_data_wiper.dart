import 'package:app_template/core/foundation/contracts/local_data_wiper.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

import '../data/attachment_file_store.dart';
import '../background/sync_background_worker.dart';
import '../data/sync_database.dart';

/// [LocalDataWiper] الذي يمحو ما يملكه الموديول فعلاً.
///
/// يُسجَّل بـ`registerSyncCore` **فوق** `NoLocalDataWiper` الافتراضي، تماماً
/// كـ`SyncUnsyncedWorkProbe`.
///
/// ## ما يُمحى، وكلُّ صفٍّ منه بسبب
///
/// | المحلّ | لماذا يُمحى |
/// |---|---|
/// | `synced_entities` | مقاسمُ الأول ومحاضره — يقرؤها `readTyped` بلا سؤالٍ عن المالك |
/// | `sync_queue` | **الأخطر**: الطابور يُدفع بتوكن من يدخل بعده، فيصل الخادمَ عملُ زميلٍ باسمه |
/// | `attachments` + `download_queue` | صفوفُ ملفّاته |
/// | `sync_meta` | المؤشّرات وختمُ الدورة وأختامُ الجرد — مؤشّرٌ متقدّمٌ لحسابٍ آخر يجعل الجهاز يتخطّى كل ما كُتب قبله |
/// | `sync_operations_log` | سجلُّ عملياته |
/// | بايتاتُ `sync_files/` | التخزين معنونٌ بالمحتوى لا بالمالك، فلا سبيل لترشيحه |
/// | `sync_lock_acquired_at_ms` | مفتاحُ القفل بـ`StorageService` — الوحيد للموديول خارج قاعدته |
///
/// ## ولا يُمحى شيءٌ يخصّ الجهاز
///
/// الثيم واللغة والخط ومعرّف الجهاز تخصّ **الجهاز**. ولذلك تُمحى المفاتيح
/// واحداً واحداً ولا تُستدعى `StorageService.clear()` — وهي ممنوعة بهذا
/// المستودع لأنها فعلت ذلك مرّةً فمحت الثيم واللغة مع ما قصدته.
///
/// ## ولا يرمي
///
/// يقع بين مستخدمٍ خرج وآخر يدخل، ورميةٌ هنا تُبقي الجهاز نصفَ ممحوّ بلا أن
/// يعرف أحد. كلُّ خطوةٍ محروسة وحدها، فتعثُّرُ واحدةٍ لا يمنع البقيّة —
/// **والطابور أوّلُها عمداً**: إن لم يُمحَ غيره فليُمحَ هو.
class SyncLocalDataWiper implements LocalDataWiper {
  const SyncLocalDataWiper(this._database, this._files, this._storage);

  final SyncDatabase _database;
  final AttachmentFileStore _files;
  final StorageService _storage;

  static const _tag = 'SYNC';

  /// بالترتيب: الأخطرُ أولاً.
  static const _tables = [
    'sync_queue',
    'synced_entities',
    'attachments',
    'download_queue',
    'sync_meta',
    'sync_operations_log',
  ];

  @override
  Future<void> wipeAll() async {
    // **مهمّاتُ الخلفية تُلغى قبل أي حذف** — وهي الشيء الوحيد هنا الذي يعيش
    // **خارج العملية**.
    //
    // مهمّةٌ مجدولة تستيقظ بعد ربع ساعةٍ من الخروج فتبني حاويةً نظيفة وتقرأ
    // طابوراً مُسح للتوّ: بأحسن الأحوال عملٌ ضائع، وبأسوئها — لو استيقظت
    // **قبل** أن تكتمل هذه الدالّة — رفعُ صفوفِ حسابٍ خرج بتوكن من دخل بعده.
    // وهو بعينه الخطر الذي يجعل `sync_queue` أوّلَ ما يُمحى بالجدول أدناه.
    //
    // ولذلك تُلغى **أولاً لا آخراً**: بينهما نافذةٌ تستيقظ فيها.
    //
    // وموضعُها هنا لا بـ`AccountDataCleaner`: ذاك يسكن `core/`، و
    // `core → modules ❌`. والمنظِّف يعرف **أن ثمّة ما يُمحى** ولا يعرف ما هو —
    // وهذا هو نصفُ الموديول من ذلك العقد.
    // **يُلغى قبل المسح** — وإلا استيقظ بعد الخروج ودفع طابوراً محذوفاً،
    // أو أحياه بمَعزلٍ يبني كلَّ شيءٍ من جديد فلا يعرف أن الحساب تبدّل.
    await SyncBackgroundWorker.cancelAll();

    for (final table in _tables) {
      try {
        final db = await _database.database;
        await db.delete(table);
      } catch (e) {
        LogService.error(
          'Could not clear "$table" while wiping local account data — the '
          'remaining steps still run.',
          tag: _tag,
          error: e,
        );
      }
    }

    try {
      await _files.deleteAll();
    } catch (e) {
      // بايتاتٌ متروكة تكلّف مساحة، ولا تُعرض: صفوفُها مُحيت أعلاه فلا شيء
      // يشير إليها. تُسجَّل ولا تُفشل المسح.
      LogService.error(
        'Could not delete attachment bytes — the rows are gone, so nothing '
        'references them; they cost space only.',
        tag: _tag,
        error: e,
      );
    }

    try {
      await _storage.delete(PersistenceKeys.syncLockAcquiredAt);
    } catch (e) {
      LogService.warning('Could not clear the sync lock key: $e', tag: _tag);
    }

    LogService.info('Local sync data wiped for account switch.', tag: _tag);
  }
}
