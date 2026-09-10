import 'dart:async';

/// **أين وصل تنزيلُ الصور والملفّات** — لقطةٌ واحدة تُبَثّ.
///
/// نظيرةُ `SyncActivity` لطورِ الملفّات النازلة، وتفترق عنها بشيءٍ واحد يبرّر
/// وجودَها منفصلة: هذا الطور **يُؤجَّل** — يقف بانتظار Wi‑Fi ويبقى واقفاً بين
/// الدورات. فالسكونُ هنا حالةٌ تُعرض، لا فراغٌ يُخفى.
enum MediaPrefetchPhase {
  /// لا شيء ينتظر التنزيل، أو لم يُسأل بعد.
  idle,

  /// بايتاتٌ تتحرّك الآن.
  running,

  /// **مؤجَّل بقرار** — الجهاز على بيانات الجوّال والسياسةُ «Wi‑Fi وحده»، أو
  /// أجّله المستخدم بيده. يُستأنف بأوّل دورةٍ تجد Wi‑Fi.
  waitingForWifi,

  /// بقيت ملفّاتٌ ولا شبكةَ تحملها — يُستأنف بعودة التغطية.
  offline,

  /// **بقي ما ينزل، ولا مانعَ يُسمّى** — إخفاقٌ عابر بملفٍّ أو ملفّين.
  ///
  /// وهي غيرُ [idle]: تلك «لم يُسأل بعد»، وهذه «سُئل وبقي». والفرقُ يُقرأ
  /// بالشاشة: الأولى لا لافتةَ لها، والثانية تقول إن الدورة التالية تُعيد.
  incomplete,

  /// **كلُّ ما تشير إليه الصفوف على الجهاز.**
  complete,
}

/// ما يجري بطور التنزيل هذه اللحظة — راجع [MediaPrefetchPhase].
class MediaPrefetchSnapshot {
  const MediaPrefetchSnapshot({
    this.phase = MediaPrefetchPhase.idle,
    this.done = 0,
    this.total = 0,
    this.remaining = 0,
    this.failed = 0,
    this.onMobileData = false,
    this.groupNumber,
    this.itemNumber,
  });

  final MediaPrefetchPhase phase;

  /// كم ملفّاً نزل بهذه الجولة، و[total] كم كان ينقص حين بدأت.
  final int done;
  final int total;

  /// **كم ملفّاً ما زال ناقصاً على الجهاز** — الرقمُ الذي تعرضه الشاشة وهي
  /// واقفة. و[done]/[total] يخصّان الجولةَ الجارية وحدها، فيُصفَّران بكل بدء.
  final int remaining;

  /// كم أخفق بهذه الجولة — إخفاقٌ عابر يُعاد بالدورة التالية.
  final int failed;

  /// **هل القرارُ مفتوحٌ الآن؟** — أي: الجهاز على بيانات الجوّال، **ولم يُبتّ**.
  ///
  /// تقرؤها الشاشةُ لتعرض **سؤالاً بجوابين** («نزّل الآن» · «أجّل») بدل جملةٍ
  /// خبرية.
  ///
  /// و`false` مع `MediaPrefetchPhase.waitingForWifi` لها معنيان يشتركان بأن لا
  /// سؤالَ فيهما: **لا شبكةَ أصلاً** (زرٌّ لا يُنفَّذ أسوأ من غيابه)، أو
  /// **أجّله المستخدمُ بيده** — و`MediaPrefetchManager.postpone` تُنزلها لذلك
  /// بالضبط: بلاها يُعاد السؤالُ نفسُه بعد الجواب مباشرةً، فيضغط المستخدم
  /// «أجّل» ولا يتبدّل أمامه حرف.
  final bool onMobileData;

  /// الصفُّ الجاري بأرقامه — **قيمتا بيانٍ** يبني منهما العرضُ نصَّه.
  final String? groupNumber;
  final String? itemNumber;

  /// `null` حين لا شيء ليُقاس — فلا يُرسم شريطٌ محدَّد على صفر.
  double? get fraction => total <= 0 ? null : (done / total).clamp(0.0, 1.0);

  bool get isRunning => phase == MediaPrefetchPhase.running;

  /// هل ثمّة ما لم ينزل بعد؟ — حَكَمُ ظهور اللافتة.
  bool get hasRemaining => remaining > 0;
}

/// بثُّ [MediaPrefetchSnapshot] — **ذاكرةٌ لا قاعدة**، كـ`SyncActivity`.
///
/// اللقطةُ تصف لحظةً جارية، وكتابتُها بالقرص تعني صفّاً يقول «يُنزَّل الآن»
/// بعد أن قُتلت العملية بمنتصفه. **وما يُصان فعلاً هو الملفّات نفسُها**: ما نزل
/// بالقرص، والباقي يُحسب بطرحه من الجرد عند كل سؤال — فلا موضعَ لعدّادٍ يفترق
/// عمّا يملكه الجهاز.
class MediaPrefetchStatus {
  final _controller = StreamController<MediaPrefetchSnapshot>.broadcast();

  MediaPrefetchSnapshot _current = const MediaPrefetchSnapshot();

  /// تُقرأ بلا انتظار أوّل حدث — شاشةٌ تُركَّب بمنتصف جولةٍ جارية كانت ستبقى
  /// فارغةً حتى الملفّ التالي.
  MediaPrefetchSnapshot get current => _current;

  Stream<MediaPrefetchSnapshot> get stream => _controller.stream;

  void emit(MediaPrefetchSnapshot snapshot) {
    _current = snapshot;
    if (!_controller.isClosed) _controller.add(snapshot);
  }

  Future<void> dispose() => _controller.close();
}
