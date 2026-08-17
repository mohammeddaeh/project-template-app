import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/placeholders/skeleton_templates.dart';
import 'package:app_template/shared/widgets/placeholders/skeleton_widget.dart';

/// أنماط مؤشر التحميل الأول لقائمة (قبل وصول أي بيانات) — استخدمه كـ
/// [PaginationBuilderWdg.loadingItemsWidget]. مقابل [PageLoadingStyle] الذي
/// يتحكم بمؤشر "تحميل المزيد" آخر القائمة.
enum InitialLoadingStyle {
  /// دائرة تحميل بسيطة وسط الشاشة (السلوك الافتراضي الحالي لـ[PaginationBuilderWdg]).
  spinner,

  /// هيكل مظلَّل (Shimmer) بشكل عناصر قائمة حقيقية — [SkeletonListTile] مكرّرة،
  /// موجة shimmer واحدة مُزامَنة على كل القائمة.
  shimmerList,

  /// هيكل مظلَّل بشكل بطاقات (لقوائم Card-based).
  shimmerCard,

  /// هيكل مظلَّل بشكل شبكة (لقوائم Grid-based).
  shimmerGrid,

  /// صفوف [SkeletonWidget] — كل عنصر (avatar + سطرا نص) يُومض بشكل مستقل عن
  /// غيره، بدل موجة shimmer واحدة مُزامَنة على القائمة كلها.
  skeletonRows,
}

/// مؤشر التحميل الأول — يظهر بدل القائمة بالكامل وقت أول فتح للشاشة (قبل
/// وصول أي صفحة بيانات). يدعم دائرة تحميل بسيطة أو هياكل Shimmer بأشكال
/// مختلفة حسب شكل عناصر القائمة الحقيقية.
class InitialLoadingIndicator extends StatelessWidget {
  const InitialLoadingIndicator({
    super.key,
    this.style = InitialLoadingStyle.spinner,
    this.itemCount = 6,
  });

  final InitialLoadingStyle style;

  /// عدد عناصر الهيكل المظلَّل المكرّرة (نمط shimmer* فقط — يُهمَل مع spinner).
  final int itemCount;

  @override
  Widget build(BuildContext context) => switch (style) {
    InitialLoadingStyle.spinner => const Center(
      child: CircularProgressIndicator.adaptive(),
    ),
    InitialLoadingStyle.shimmerList => _buildList(
      (_) => const SkeletonListTile(),
    ),
    InitialLoadingStyle.shimmerCard => _buildList((_) => const SkeletonCard()),
    InitialLoadingStyle.shimmerGrid => GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const SkeletonGridItem(),
    ),
    InitialLoadingStyle.skeletonRows => _buildList(
      (_) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SkeletonWidget(width: 44, height: 44, borderRadius: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonWidget(width: double.infinity, height: 14),
                  SizedBox(height: 6),
                  SkeletonWidget(width: 100, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  };

  Widget _buildList(Widget Function(int) itemBuilder) => ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    itemBuilder: (_, i) => itemBuilder(i),
  );
}
