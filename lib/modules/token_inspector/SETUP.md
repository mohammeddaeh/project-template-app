# `token_inspector` — SETUP

> أداةُ مطوّر: التوكن والتجديد وفحص Keycloak على الشاشة. الشرح الكامل:
> [`readme/33_MODULE_TOKEN_INSPECTOR.md`](../../../readme/33_MODULE_TOKEN_INSPECTOR.md).

## التشغيل

1. `AppFeatures.tokenInspector = true`
2. شغّل التطبيق — زرٌّ بأيقونة مفتاح يطفو فوق كل الشاشات. اسحبه، واضغطه.

لا خطوة ثالثة: `TokenInspectorPlugin` يعلّق مستمعه على `AuthSessionRelay`، ويسجّل
طبقته بـ`AppOverlays`.

**مع Keycloak** — ضع مفتاح الـrefresh بـ`token_inspector_config.dart`، ومرّر
`TokenGrant.fromOAuthJson(...)` كاملاً عند الدخول والتجديد (المرجع §٦). والقيم
المتوقّعة اختيارية بـ`.env.<flavor>.json`.

## القراءة

| القسم | ما فيه |
|---|---|
| Session now | ما بالتخزين الآن: حكمٌ واحد، وعدّادٌ لكل توكن |
| Keycloak checks | إعدادات الـrealm مما يُرى — يظهر مع Keycloak وحده |
| History | كلُّ حدث، الأحدث أوّلاً — يبقى بعد الإغلاق والخروج، وClear يمسحه |

ومن الكود: `TokenInspector.mark('…')` · `TokenInspector.snapshot('…')` ·
`const TokenInspectorPanel()`.

## الإزالة

- **قبل الإصدار**: `tokenInspector = false`، واحذف نداءاتك. `build_apk.dart` يعدّدها
  ببناء `prod`/`release` ويسأل. ونسخة `prod` release لا تعرض شيئاً منها على أي حال.
- **حذف الموديول**: المجلّد · سطره بـ`ModulesBootstrap` · علَمه · `test/token_inspector/`.
  النواة لا تعرفه (`C20`)، فلا شيء آخر.
