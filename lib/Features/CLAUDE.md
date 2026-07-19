# lib/Features/CLAUDE.md — Feature Patterns

> يُحمَّل عند العمل في lib/Features/**
> لا يوجد feature عمل مبني بعد بهذا التيمبليت — اتبع البنية والقواعد أدناه حرفياً عند بناء أول واحدة.

---

## Feature Structure (Clean Architecture)

```
lib/Features/{feature}/
  ├── data/
  │   ├── dtos/             ← Request bodies (@Body()) — لكل POST/PUT
  │   ├── models/           ← fromJson/toEntity (no freezed)
  │   ├── datasources/      ← ApiService (@RestApi) + RemoteDataSource
  │   └── repositories/     ← Repository impl (extends BaseRepository)
  ├── domain/
  │   ├── entities/         ← Pure Dart + Equatable (no fromJson)
  │   ├── params/           ← UseCaseParams subclasses
  │   ├── repositories/     ← Abstract repository interface
  │   └── usecases/         ← Use cases (business logic)
  └── presentation/
      ├── cubits/           ← Cubit + @freezed state
      ├── widgets/          ← Feature-specific widgets
      └── pages/            ← Screen widgets (@RoutePage)
```

### Layer Rules

| Layer | Rule |
|---|---|
| DataSource | Uses `*ApiService`, returns raw data, no try-catch |
| Repository Impl | extends `BaseRepository`, uses `handle()`, maps models → entities |
| Domain Entities | Pure Dart, no fromJson, no imports from data layer |
| Use Case | `@injectable`, wraps a single repository call |
| Cubit | Depends on Use Case (NOT repository directly) |
| State | `@freezed` mandatory — لا استثناءات |

### Auth — بنية تحتية جاهزة، لا feature بعد

`core/infra/session/session_repository.dart` (تخزين التوكن) و`core/foundation/contracts/auth_network_gateway.dart` (العقد الذي يقرأه `AuthInterceptor`) جاهزان بالـ`core/` — لا يعتمدان على أي feature. عند بناء أول auth slice (`login/`, `register/`...):

- اجعل الـentity الخاصة بالمستخدم (`AuthUser` أو مكافئها) تعيش داخل `auth/shared/` إن احتجت مشاركتها بين أكثر من slice.
- بعد نجاح تسجيل الدخول: `getIt<SessionRepository>().saveToken(token)`.
- عند تسجيل الخروج / انتهاء الجلسة: `getIt<SessionRepository>().clearSession()` (أو استمع لـ`AuthEventBus.instance.stream` — يُطلَق تلقائياً من `AuthInterceptor` عند 401).

### استثناءات Features → Features (حصرية — لا تُوسَّع)

لا يوجد استثناء مُفعَّل حالياً (كان مخصصاً لـ`auth/shared/` قبل تجريد التيمبليت). إن احتجت تركيب UI عابر للـfeatures مستقبلاً، صدّر widget عاماً self-contained يملك الـcubit داخلياً بدل استيراد cubits/states/usecases من feature أخرى مباشرة.

---

## ❄️ FREEZED — مطلوب لجميع الـ States

```dart
// {name}_cubit.dart
part '{name}_cubit.freezed.dart';
part '{name}_state.dart';

@injectable
class {Name}Cubit extends Cubit<{Name}State> {
  {Name}Cubit(this._{useCase}) : super(const {Name}State.initial());
  final {UseCaseName} _{useCase};
}
```

```dart
// {name}_state.dart
part of '{name}_cubit.dart';

@freezed
abstract class {Name}State with _${Name}State {
  const factory {Name}State.initial()                             = {Name}Initial;
  const factory {Name}State.loading()                             = {Name}Loading;
  const factory {Name}State.loaded()                              = {Name}Loaded;
  const factory {Name}State.error({required String errorMessage}) = {Name}Error;
}
```

```dart
// Consuming in Screen
BlocConsumer<{Name}Cubit, {Name}State>(
  listener: (context, state) {
    state.maybeWhen(
      error: (msg) => context.feedback.error(msg),
      orElse: () {},
    );
  },
  builder: (context, state) => state.when(
    initial: () => const SizedBox.shrink(),
    loading: () => const LoadingWidget(),
    loaded: () => const {Name}Body(),
    error: (_) => const SizedBox.shrink(),
  ),
)
```

## Cubit Error Pattern

```dart
res.fold((failure) {
  switch (FailureUiMapper.toAction(failure)) {
    case ShowError(:final message): emit({Name}State.error(errorMessage: message));
    case NavigateToLogin(): AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    case Silent(): break;
  }
}, (data) => emit({Name}State.loaded(data: data)));
```

---

# §CRUD-PATTERNS

**القاعدة:** شاشة الإضافة = شاشة التعديل. `id == null` → إضافة · `id != null` → تعديل.

## هيكل CRUD كاملة

```
lib/Features/{feature}/
  ├── domain/usecases/
  │   ├── get_{feature}_list.dart
  │   ├── create_{feature}.dart
  │   ├── update_{feature}.dart
  │   └── delete_{feature}.dart
  └── presentation/
      ├── cubits/
      │   ├── {feature}_list_cubit.dart   ← extends PaginationCubit
      │   ├── {feature}_form_cubit.dart
      │   └── {feature}_form_state.dart
      └── pages/
          ├── {feature}_list_screen.dart
          └── {feature}_form_screen.dart  ← إضافة + تعديل في ملف واحد
```

## FormCubit

```dart
@injectable
class {Feature}FormCubit extends Cubit<{Feature}FormState> {
  void submit({required String? id, required String field1}) async {
    emit(const {Feature}FormState.loading());
    final res = id == null
        ? await _create(Create{Feature}Params(field1: field1))
        : await _update(Update{Feature}Params(id: id, field1: field1));
    res.fold(
      (failure) { switch (FailureUiMapper.toAction(failure)) { ... } },
      (entity) => emit({Feature}FormState.success(entity: entity)),
    );
  }
}
```

## Delete Flow

```dart
// إلزامي: AppConfirmDialog قبل أي حذف
AppConfirmDialog.show(context,
  titleKey: LocaleKeys.deleteConfirmTitle,
  messageKey: LocaleKeys.deleteConfirmMessage,
  isDestructive: true,
  onConfirm: () => context.read<{Feature}ListCubit>().delete{Feature}(id),
);
```

## Optimistic Update

```dart
// Delete
final backup = List<{Entity}>.from(data);
removeItemWhere((e) => e.id == id);          // ← قبل await
final res = await _delete(...);
res.fold((f) { restoreItems(backup); _handleFailure(f); }, (_) {});

// Update
final old = data.firstWhere((e) => e.id == id);
replaceEntityItem(old.copyWith(field1: newValue));  // ← قبل await
final res = await _update(...);
res.fold((f) { replaceEntityItem(old); _handleFailure(f); }, (u) => replaceEntityItem(u));
```

## List Refresh Strategies

| الموقف | الاستراتيجية |
|---|---|
| بعد إضافة + server يُرجع entity | `prependItem(newEntity)` |
| بعد إضافة + بيانات ناقصة | `refresh()` |
| بعد تعديل | `replaceEntityItem(updated)` |
| بعد حذف | `removeItemWhere((e) => e.id == id)` |
| عملية فاشلة | `restoreItems(backup)` |

## Navigation بعد CRUD

```dart
context.router.pop(newEntity);          // FormScreen — الرجوع مع entity
// ListScreen
final e = await context.router.push<{Entity}?>({Feature}FormRoute());
if (e != null && context.mounted) context.read<{Feature}ListCubit>().prependItem(e);
```

## ✅ Checklist CRUD

- [ ] FormCubit يقبل `id?` ويقرر create/update داخلياً
- [ ] `{Feature}FormState.success` يحمل الـ `entity`
- [ ] حذف يسبقه `AppConfirmDialog.show(..., isDestructive: true)`
- [ ] Optimistic: `removeItemWhere`/`replaceEntityItem` قبل `await`
- [ ] Rollback: `restoreItems(backup)` عند الفشل
- [ ] `context.router.pop(entity)` — ليس `pop(true)`

---

# §FORMS-GUIDE

**القاعدة:** كل حقل يحتاج تحقق → `Form` + `GlobalKey<FormState>`.

## Imports إلزامية في Form Screen

```dart
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart'; // ⚠️ منفصل
```

## متى Form ومتى Controller مباشرة

| الحالة | الأسلوب |
|---|---|
| 2+ حقول مع validation | `Form` + `GlobalKey<FormState>` |
| حقل واحد + validation | `Form` + `GlobalKey<FormState>` |
| بحث بدون validation | `TextEditingController` فقط |
| تفعيل/تعطيل زر real-time | `TextEditingController` + `addListener` + `RefreshCubit` |

## هيكل Scaffold إلزامي

```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: KeyboardDismissWidget(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(key: _formKey, child: Column(children: [...])),
    ),
  ),
)
```

## Validators

```dart
String? _validateRequired(String? v) =>
    (v == null || v.trim().isEmpty) ? LocaleKeys.fieldRequired.tr() : null;

String? _validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return LocaleKeys.fieldRequired.tr();
  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v.trim()))
    return LocaleKeys.invalidEmail.tr();
  return null;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return LocaleKeys.fieldRequired.tr();
  if (v.length < 8 || v.length > 30) return LocaleKeys.passwordLength.tr();
  if (!CustomRegex.passwordRegex.hasMatch(v)) return LocaleKeys.passwordWeak.tr();
  return null;
}
```

## _submit — دائماً

```dart
void _submit(BuildContext context) {
  if (!_formKey.currentState!.validate()) return;
  context.unfocus();
  context.read<MyCubit>().submit(...);
}
```

## Double Submit Prevention (صارمة)

```dart
bool _isLoading = false;
bool _submitted = false; // ← يفعّل autovalidate بعد أول محاولة إرسال

// في Form widget:
Form(
  key: _formKey,
  autovalidateMode: _submitted
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled,
  child: ...,
)

// في _submit():
void _submit(BuildContext context) {
  setState(() => _submitted = true);  // ← يُفعّل validation المرئي
  if (!_formKey.currentState!.validate()) return;
  if (_isLoading) return;             // ← يمنع Double Submit
  context.unfocus();
  setState(() => _isLoading = true);
  // ... await call ...
  if (mounted) setState(() => _isLoading = false);
}

// في PrimaryButton:
PrimaryButton(
  isEnabled: !_isLoading,
  onTap: _isLoading ? null : () => _submit(context),
)
```

**لماذا؟** بدون `_submitted` → الـ validation تظهر بعد أول إرسال فقط. بدون `_isLoading` guard → الضغط السريع يُرسل طلبين.

## ✅ Checklist Form

- [ ] `resizeToAvoidBottomInset: true`
- [ ] `KeyboardDismissWidget` + `SingleChildScrollView`
- [ ] `_isLoading` + `_submitted` مُعرَّفان في الـ state
- [ ] `Form.autovalidateMode` يعتمد على `_submitted`
- [ ] `_submit()` تستدعي `validate()` ثم `unfocus()` ثم تتحقق `_isLoading`
- [ ] كل Controller: `initState` + `dispose`
- [ ] الزر: `isEnabled: !_isLoading` + `onTap: null` أثناء الطلب
- [ ] أخطاء API: `context.feedback.error(msg)` لا في validator
- [ ] `if (!context.mounted) return;` بعد كل `await`

---

# §NAVIGATION-PATTERNS

> Router: **AutoRoute** — كل navigation عبر `context.router`.

## متى تستخدم كل دالة

| الدالة | متى |
|---|---|
| `context.router.push(Route())` | شاشة جديدة فوق الحالية |
| `context.router.replace(Route())` | استبدال الشاشة الحالية |
| `context.router.replaceAll([Route()])` | مسح كل الـ stack |
| `context.router.pop()` / `pop(value)` | الرجوع / الرجوع مع نتيجة |

```dart
context.router.replaceAll([const HomeRoute()]);       // بعد Login
getIt<AppRouter>().replaceAll([const LoginRoute()]);  // Session Expired
// ❌ لا تستخدم Navigator.of(context)
```

## إضافة Route جديد

```dart
// 1. @RoutePage() على الشاشة
// 2. router.dart: customRouteWithAnimation(page: {Name}Route.page)
// 3. dart run build_runner build --delete-conflicting-outputs
```

## Session Expired

```dart
// app.dart: _authEventBus.sessionExpired.listen((_) { getIt<AppRouter>().replaceAll([const LoginRoute()]); });
// Cubit: case NavigateToLogin(): AuthEventBus.instance.emit(AuthEvent.sessionExpired);
// ❌ الـ Cubit لا يتعامل مع Router مباشرة
```

---

# §WIDGETS-GUIDE

> **Import الوحيد:** `package:app_template/shared/widgets/widgets.dart`
> **لا تستخدم:** `ElevatedButton` أو `TextButton` مباشرة في الـ Features.

## PrimaryButton

```dart
PrimaryButton(text: LocaleKeys.submit.tr(), onTap: _handleSubmit,
  isLoading: state is LoadingState, isEnabled: formIsValid,
  colorButton: context.colors.error)
```

## AppCard

```dart
AppCard(child: MyContent(), margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: EdgeInsets.all(16), elevation: 2, onTap: () => navigateToDetail())
```

## CustomTextField

```dart
CustomTextField(controller: _ctrl, labelText: LocaleKeys.email.tr(),
  validator: (v) => v!.isEmpty ? LocaleKeys.fieldRequired.tr() : null)
CustomTextField(controller: _ctrl, isFieldObscure: true)           // password
CustomTextField(controller: _ctrl, isSearch: true, onChanged: _fn) // search
CustomTextField(controller: _ctrl, keyboardType: TextInputType.phone, ltr: true)
CustomTextField(controller: _ctrl, maxLines: 4, minLines: 2)
```

## PaginationBuilderWdg

```dart
PaginationBuilderWdg<{Name}Cubit, {Entity}>(
  loadingItemsWidget: _buildShimmerList(),
  itemWdg: (entity) => {Entity}Item(entity: entity),
  separatorWidget: const DashedDivider(),
  notItemsMsg: LocaleKeys.no{Feature}.tr(),
  wantKeepAlive: true,
)
// - يجب تغليفه بـ BlocProvider<{Name}Cubit>
// - {Name}Cubit يجب أن يـ extend PaginationCubit<{Entity}>
// - override close() لإلغاء الطلبات (إلزامي)
```

## State Widgets

```dart
const LoadingWidget()
EmptyStateWidget(titleKey: LocaleKeys.no{Feature}, icon: Icons.inbox_outlined,
  onAction: () => context.router.push(const {Feature}FormRoute()), actionLabelKey: LocaleKeys.add{Feature})
ErrorStateWidget(messageKey: errorMessage, onRetry: () => context.read<{Name}Cubit>().load())
const NoInternetWidget()
const MaintenanceWidget()
```

## Shimmer

```dart
ShimmerLoadingWidget(
  baseColor: const Color(0xFFE0E0E0),
  highlightColor: const Color(0xFFF5F5F5),
  child: ListView.builder(shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(), itemCount: 8,
    itemBuilder: (_, __) => Container(color: Colors.white, height: 60)),
)
// SkeletonWidget منفرداً فقط — لا تضعه داخل ShimmerLoadingWidget
SkeletonWidget(width: 120, height: 14)
```

## RefreshCubit — تفعيل/تعطيل زر real-time

```dart
final _refreshCubit = RefreshCubit();
// initState: _ctrl.addListener(_refreshCubit.refresh)
// dispose: _refreshCubit.close()

BlocBuilder<RefreshCubit, RefreshState>(
  bloc: _refreshCubit,
  builder: (context, _) {
    final can = _ctrl.text.isNotEmpty;
    return PrimaryButton(isEnabled: can, onTap: can ? () => _submit(context) : null);
  },
)
```

## Spacing & Padding

```dart
8.widthBox · 16.heightBox · 16.allPadding · 16.horizontalPadding · 16.verticalPadding
// import: package:app_template/presentation/extensions/app_padding_extension.dart
```

## قواعد مكان Widget

| المكان | متى |
|---|---|
| `lib/shared/widgets/` | يُستخدم في أكثر من Feature |
| `lib/Features/{f}/presentation/widgets/` | خاص بـ Feature واحدة |

بعد إضافة widget مشترك → أضفه في `lib/shared/widgets/widgets.dart`:
```dart
export 'layout/my_new_widget.dart';
```

## ✅ Checklist UI

- [ ] تحقق من `lib/shared/widgets/` أولاً — لا تُعيد بناء موجود
- [ ] كل نص: `LocaleKeys.xxx.tr()` — ممنوع hardcode
- [ ] كل لون: `context.colors.xxx`
- [ ] كل style: `context.textTheme.xxx`
- [ ] Loading: `LoadingWidget()` أو shimmer · Error: `ErrorStateWidget` · Empty: `EmptyStateWidget`
