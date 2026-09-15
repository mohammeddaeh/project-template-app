import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/routes/deep_link_resolver.dart';

void main() {
  final startRoute = PageRouteInfo<void>('LoginRoute');

  group('resolveDeepLink', () {
    test('إقلاعٌ عاديّ (initial، بلا مسار) → وجهة الإقلاع المحسوبة', () {
      final result = resolveDeepLink(
        initial: true,
        path: '',
        startRoute: startRoute,
      ) as dynamic;
      expect(result.isValid, isTrue);
      // `DeepLink.single` يُبنى من `_RoutesDeepLink` الخاص بالحزمة — حقلها
      // العام `routes` يحمل وجهة الإقلاع المحسوبة بالضبط، لا مساراً مُحلَّلاً.
      expect(result.routes, [startRoute]);
    });

    test('إقلاعٌ عاديّ بمسار الجذر "/" → وجهة الإقلاع المحسوبة كذلك', () {
      final result = resolveDeepLink(
        initial: true,
        path: '/',
        startRoute: startRoute,
      );
      expect(result.isValid, isTrue);
    });

    test('رابطٌ حقيقيّ عند الإقلاع (initial + مسارٌ فعليّ) → يُحلّ بمساره', () {
      final result = resolveDeepLink(
        initial: true,
        path: '/reset-password',
        startRoute: startRoute,
      ) as dynamic;
      // `_PathDeepLink` خاصٌّ بالحزمة — نقرأ حقله العام `path` عبر dynamic
      // بدل استيراد نوعٍ داخليّ لا يُصدَّر.
      expect(result.path, '/reset-password');
    });

    test('رابطٌ حقيقيّ والتطبيق يعمل (initial=false) → يُحلّ بمساره أيضاً', () {
      final result = resolveDeepLink(
        initial: false,
        path: '/change-password',
        startRoute: startRoute,
      ) as dynamic;
      expect(result.path, '/change-password');
    });

    test(
      'رابطٌ فارغ والتطبيق يعمل أصلاً (initial=false) — نظرياً لا يقع، لكن '
      'الدالّة لا تفترض initial=false يعني إقلاعاً بالضرورة',
      () {
        final result = resolveDeepLink(
          initial: false,
          path: '',
          startRoute: startRoute,
        ) as dynamic;
        // بلا `initial` لا يُطبَّق استثناء الإقلاع العادي إطلاقاً — يُحلّ
        // المسارُ كما وصل، حتى لو فارغاً.
        expect(result.path, '');
      },
    );
  });
}
