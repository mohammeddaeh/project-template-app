import 'dart:async';

/// **ما يجري الآن بطور الدفع** — لقطةٌ واحدة تُبَثّ.
///
/// [total] كم صفّاً استحقّ الرفع حين بدأت الدورة، و[done] كم انتهى منها —
/// نجاحاً أو إخفاقاً. و[entityId] الصفُّ الذي بين يدي المحرّك هذه اللحظة.
class SyncActivitySnapshot {
  const SyncActivitySnapshot({
    this.isPushing = false,
    this.entityName,
    this.entityId,
    this.done = 0,
    this.total = 0,
  });

  /// دورةُ دفعٍ جارية — **لا «دورة مزامنة»**: السحب طورٌ آخر لا يمرّ من هنا.
  final bool isPushing;

  /// الصفُّ الجاري — `null` بين صفٍّ وآخر وحين لا دورة.
  final String? entityName;
  final String? entityId;

  /// **يتقدّم بالإخفاق كما يتقدّم بالنجاح.**
  ///
  /// وهذا مقصود: شريطُ تقدّمٍ يقف عند صفٍّ أخفق يُقرأ «تعلّق التطبيق»، والحقيقة
  /// أن المحرّك مضى إلى الذي بعده. والإخفاقُ يُقال بعدّاده الخاص لا بتجميد
  /// الشريط.
  final int done;
  final int total;

  /// `null` حين لا شيء ليُقاس — فلا يُرسم شريطٌ محدَّد على صفر.
  double? get fraction => total <= 0 ? null : (done / total).clamp(0.0, 1.0);

  bool get isIdle => !isPushing;
}

/// **بثُّ تقدّم الرفع — الشيء الوحيد الذي كان ينقص الشاشة لتقول ما يحدث.**
///
/// ## العطل الذي وُجد له
///
/// `SyncQueueRepository.countPendingJobs()` تقول **كم بقي**، ولا تقول شيئاً عن
/// الحركة. فشاشةٌ تعرضها وحدها تُري الموظّف رقماً جامداً — «٧ بانتظار الرفع» —
/// ولا تفرّق بين ثلاث حالاتٍ يفرّق بينها كلُّ شيء:
///
/// | الحال | ما يراه بلا هذا البثّ |
/// |---|---|
/// | الرفع يجري الآن | «٧» ثابتة، ثم تصير «٦» فجأة |
/// | البوّابة رافضة (بلا شبكة · بانتظار Wi‑Fi) | «٧» ثابتة **إلى الأبد** |
/// | صفٌّ يُعاد تجريبه بتراجعٍ أسّي | «٧» ثابتة، والحركة بعد دقائق |
///
/// **والثلاثة تبدو واحدة**: رقمٌ لا يتحرّك. فيُقرأ التطبيقُ معطوباً وهو يعمل،
/// أو سليماً وهو موقوف. وهذا بعينه ما يجعل موظّفاً يُغلق التطبيق ظانّاً أن
/// شغله ارتفع.
///
/// ## ولا حالةَ مخزَّنة — بثٌّ وذاكرةٌ فقط
///
/// اللقطة تصف **لحظةً جارية**، لا حقيقةً تُصان. وكتابتُها بالقاعدة كانت تعني
/// صفّاً يقول «يجري الرفع» بعد أن قُتلت العملية بمنتصفه — وهو كذبٌ يدوم إلى
/// أن يُصحَّح بكتابةٍ لن تأتي. والذاكرةُ تنسى بالإقلاع، وهو الصواب هنا.
///
/// و[current] تُقرأ بلا انتظار أول حدث: شاشةٌ تُركَّب بمنتصف دورةٍ جارية كانت
/// ستبقى فارغةً حتى الصفّ التالي.
class SyncActivity {
  final _controller = StreamController<SyncActivitySnapshot>.broadcast();

  SyncActivitySnapshot _current = const SyncActivitySnapshot();

  SyncActivitySnapshot get current => _current;

  Stream<SyncActivitySnapshot> get stream => _controller.stream;

  /// بدأ طورُ الدفع بـ[total] صفّاً مستحقاً.
  void beginPush({required int total}) =>
      _emit(SyncActivitySnapshot(isPushing: true, total: total));

  /// المحرّك أخذ هذا الصفّ.
  void startJob({required String entityName, required String entityId}) =>
      _emit(
        SyncActivitySnapshot(
          isPushing: true,
          entityName: entityName,
          entityId: entityId,
          done: _current.done,
          total: _current.total,
        ),
      );

  /// انتهى الصفُّ الجاري — **نجح أو أخفق**، راجع [SyncActivitySnapshot.done].
  void finishJob() => _emit(
    SyncActivitySnapshot(
      isPushing: true,
      done: _current.done + 1,
      // **والمجموع يتّسع إن لزم**: البوّابة تسحب دفعاتٍ متتالية، فقد يتجاوز
      // المنتهي ما أُعلن أوّلاً. وكسرٌ أكبر من واحد يرسم شريطاً يفيض.
      total: _current.total < _current.done + 1
          ? _current.done + 1
          : _current.total,
    ),
  );

  /// **صفٌّ غادر الجهاز بنجاح** — يُنادى من فرع النجاح وحده.
  ///
  /// ولا يُدمج بـ[finishJob]: تلك تُنادى بـ`finally` فتشمل الإخفاق، وعدّادُ
  /// التقدّم يجب أن يشملهما معاً بينما هذه القائمة لا تقبل إلا ما وصل.
  void jobSucceeded({required String entityName, required String entityId}) {
    _uploaded.remove('$entityName/$entityId');
    _uploaded['$entityName/$entityId'] = DateTime.now();
    // **سقفٌ يُقصّ من الأقدم** — القائمة تُقرأ «آخر ما ارتفع»، لا سجلَّ عمليات.
    // وذاك موجودٌ بمكانه (`SyncOperationsLog`) ويعيش بالقاعدة، وهذه بالذاكرة.
    while (_uploaded.length > _maxUploaded) {
      _uploaded.remove(_uploaded.keys.first);
    }
  }

  /// **ما ارتفع بهذه الجلسة** — `entityName/entityId` ⇐ لحظةُ الوصول.
  ///
  /// ## ولماذا تُحفظ أصلاً
  ///
  /// الصفُّ يخرج من `sync_queue` لحظةَ نجاحه، فيختفي من القائمة **فجأة**. وهذا
  /// يُقرأ «ضاع» لا «وصل»: الموظّف يرى سبعةً، يبدأ الرفع، ثم يجد ستّة — ولا
  /// شيء يقول إن السابع سلِم.
  ///
  /// فيبقى معروضاً أخضرَ حتى يُغلق التطبيق. **وبالذاكرة عمداً**: هذا تأكيدٌ
  /// للحظة، لا حقيقةٌ تُصان — وجدولٌ لها كان يعني صفوفاً تُنظَّف بمهمّةٍ ثانية.
  Map<String, DateTime> get uploaded => Map.unmodifiable(_uploaded);

  /// **يُنسي صفّاً ارتفع** — بطلبٍ من المستخدم، لا تلقائياً.
  ///
  /// [key] بصيغة `entityName/entityId` كما تُعيدها [uploaded].
  ///
  /// وهو إخفاءٌ من الشاشة لا حذفٌ لشيء: الصفُّ عند الخادم، وصفُّه بالقاعدة
  /// يملكه السحب. **ولا تُحرَّر به مساحةٌ تُذكر** — هذه الخريطة بالذاكرة
  /// وسقفُها ثلاثون مدخلاً، أي بضعُ مئاتٍ من البايتات تزول بإغلاق التطبيق.
  /// وُجد لأن قائمةً تطول تُخفي ما ينتظر تحت ما انتهى، لا لأنها تكلّف تخزيناً.
  void forget(String key) => _uploaded.remove(key);

  /// يُنسي ما ارتفع كلَّه — «إخفاء المكتمل».
  void forgetUploaded() => _uploaded.clear();

  final Map<String, DateTime> _uploaded = {};
  static const int _maxUploaded = 30;

  /// انتهى طورُ الدفع — **ويُنادى بـ`finally`**، فرميةٌ بمنتصف الدورة لا تترك
  /// الشاشة تقول «يجري الرفع» إلى الأبد.
  ///
  /// ⚠️ **ولا تُمحى [uploaded] هنا**: نهايةُ الدورة ليست نهايةَ اهتمام
  /// الموظّف بما وصل. تبقى حتى يُغلق التطبيق.
  void endPush() => _emit(const SyncActivitySnapshot());

  void _emit(SyncActivitySnapshot snapshot) {
    _current = snapshot;
    if (!_controller.isClosed) _controller.add(snapshot);
  }

  Future<void> dispose() => _controller.close();
}
