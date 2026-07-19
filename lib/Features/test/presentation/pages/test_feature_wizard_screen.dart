import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class _Snippet {
  const _Snippet({required this.label, required this.code});
  final String label;
  final String code;
}

class _StepData {
  const _StepData({
    required this.icon,
    required this.titleKey,
    required this.description,
    required this.snippets,
  });
  final IconData icon;
  final String titleKey;
  final String description;
  final List<_Snippet> snippets;
}

// ─── Step Definitions ────────────────────────────────────────────────────────

const _steps = <_StepData>[
  // Step 0 — Domain
  _StepData(
    icon: Icons.account_tree_outlined,
    titleKey: LocaleKeys.stepDomain,
    description:
        'Define your entities (pure Dart + Equatable) and the abstract repository '
        'interface. No JSON, no imports from the data layer — just the contract.',
    snippets: [
      _Snippet(
        label: 'lib/Features/products/domain/entities/product.dart',
        code: '''import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  @override
  List<Object?> get props => [id, name, price];
}''',
      ),
      _Snippet(
        label:
            'lib/Features/products/domain/repositories/product_repository.dart',
        code: '''import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'product.dart';

abstract interface class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    required int page,
  });
}''',
      ),
    ],
  ),

  // Step 1 — Data
  _StepData(
    icon: Icons.storage_outlined,
    titleKey: LocaleKeys.stepData,
    description:
        'Create the JSON model (fromJson + toEntity) and the Retrofit API service. '
        'Keep models in data/models/ — they never escape to domain.',
    snippets: [
      _Snippet(
        label: 'lib/Features/products/data/models/product_model.dart',
        code: '''class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  factory ProductModel.fromJson(Map<String, dynamic> j) =>
      ProductModel(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
      );

  Product toEntity() =>
      Product(id: id, name: name, price: price);
}''',
      ),
      _Snippet(
        label:
            'lib/Features/products/data/datasources/products_api_service.dart',
        code: '''@RestApi()
abstract class ProductsApiService {
  factory ProductsApiService(Dio dio) =
      _ProductsApiService;

  @GET(ApiUrls.products)
  Future<ApiResponse<List<ProductModel>>> getProducts(
    @Query('page') int page,
  );
}''',
      ),
    ],
  ),

  // Step 2 — Use Cases & DI
  _StepData(
    icon: Icons.bolt_outlined,
    titleKey: LocaleKeys.stepUseCases,
    description:
        'Each use case wraps a single repository call. Mark them @injectable so '
        'get_it picks them up automatically after build_runner.',
    snippets: [
      _Snippet(
        label:
            'lib/Features/products/domain/usecases/get_products_list.dart',
        code: '''@injectable
class GetProductsList
    extends BaseUseCase<List<Product>, PageParams> {
  GetProductsList(this._repo);
  final ProductRepository _repo;

  @override
  Future<Either<Failure, List<Product>>> call(
    PageParams p,
  ) => _repo.getProducts(page: p.page);
}''',
      ),
      _Snippet(
        label:
            'lib/Features/products/data/repositories/product_repository_impl.dart',
        code: '''@Injectable(as: ProductRepository)
class ProductRepositoryImpl
    extends BaseRepository
    implements ProductRepository {
  ProductRepositoryImpl(this._remote);
  final ProductsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    required int page,
  }) =>
      handle(() async => (await _remote
              .getProducts(page: page))
          .map((m) => m.toEntity())
          .toList());
}''',
      ),
    ],
  ),

  // Step 3 — Route
  _StepData(
    icon: Icons.route_outlined,
    titleKey: LocaleKeys.stepRoute,
    description:
        'Add @RoutePage() to each screen, register the routes in router.dart, '
        'then regenerate the router with build_runner.',
    snippets: [
      _Snippet(
        label: 'lib/routes/router.dart  (inside routes list)',
        code: '''// أضف داخل routes:
AutoRoute(
  page: ProductsListRoute.page,
  path: '/products',
),
AutoRoute(
  page: ProductFormRoute.page,
  path: '/products/form',
),''',
      ),
      _Snippet(
        label: 'Terminal',
        code: '''dart run build_runner build \\
  --delete-conflicting-outputs''',
      ),
    ],
  ),

  // Step 4 — Presentation
  _StepData(
    icon: Icons.layers_outlined,
    titleKey: LocaleKeys.stepPresentation,
    description:
        'The cubit extends PaginationCubit so infinite scroll is free. '
        'The screen wraps everything in BlocProvider and uses PaginationBuilderWdg.',
    snippets: [
      _Snippet(
        label:
            'lib/Features/products/presentation/cubits/products_list_cubit.dart',
        code: '''@injectable
class ProductsListCubit
    extends PaginationCubit<Product> {
  ProductsListCubit(this._getProducts)
      : super(pageSize: 20);

  final GetProductsList _getProducts;

  @override
  Future<Either<Failure, List<Product>>> fetchPage(
    int page,
  ) => _getProducts(PageParams(page: page));
}''',
      ),
      _Snippet(
        label:
            'lib/Features/products/presentation/pages/products_list_screen.dart',
        code: '''@RoutePage()
class ProductsListScreen extends StatelessWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(LocaleKeys.products.tr()),
    ),
    body: BlocProvider(
      create: (_) => getIt<ProductsListCubit>()
        ..loadFirstPage(),
      child: PaginationBuilderWdg<
          ProductsListCubit,
          Product>(
        itemWdg: (p) => ProductItem(product: p),
        notItemsMsg: LocaleKeys.noProducts.tr(),
      ),
    ),
  );
}''',
      ),
    ],
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

@RoutePage()
class TestFeatureWizardScreen extends StatefulWidget {
  const TestFeatureWizardScreen({super.key});

  @override
  State<TestFeatureWizardScreen> createState() =>
      _TestFeatureWizardScreenState();
}

class _TestFeatureWizardScreenState extends State<TestFeatureWizardScreen> {
  int _currentStep = 0;

  void _goNext() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _goPrev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final step = _steps[_currentStep];
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.testFeatureWizardTitle.tr(),
              style: context.textTheme.headlineSmall,
            ),
            Text(
              LocaleKeys.testFeatureWizardSubtitle.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Step progress indicator ───────────────────────────────────────
          _StepProgressIndicator(
            total: _steps.length,
            current: _currentStep,
          ),
          const SizedBox(height: 8),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _StepContent(
                key: ValueKey(_currentStep),
                step: step,
              ),
            ),
          ),

          // ── Navigation buttons ────────────────────────────────────────────
          _WizardNavBar(
            currentStep: _currentStep,
            totalSteps: _steps.length,
            onPrev: _goPrev,
            onNext: _goNext,
          ),
        ],
      ),
    );
  }
}

// ─── Step Progress Indicator ─────────────────────────────────────────────────

class _StepProgressIndicator extends StatelessWidget {
  const _StepProgressIndicator({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          // Even indices → circles, odd indices → connectors
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final done = stepIndex < current;
            return Expanded(
              child: Container(
                height: 2,
                color: done
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < current;
          final isCurrent = stepIndex == current;
          return _StepCircle(
            index: stepIndex,
            isDone: isDone,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isDone,
    required this.isCurrent,
  });

  final int index;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    Color bg;
    Color fg;
    Widget child;

    if (isDone) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
      child = Icon(Icons.check, size: 14, color: fg);
    } else if (isCurrent) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
      child = Text(
        '${index + 1}',
        style: context.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      bg = Colors.transparent;
      fg = scheme.outlineVariant;
      child = Text(
        '${index + 1}',
        style: context.textTheme.labelLarge?.copyWith(
          color: scheme.outline,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isDone || isCurrent
            ? null
            : Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ─── Step Content ─────────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  const _StepContent({super.key, required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    context.locale;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                step.icon,
                color: context.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.titleKey.tr(),
                style: context.textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          step.description,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Snippets
        for (final snippet in step.snippets) ...[
          _SnippetBlock(snippet: snippet),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ─── Snippet Block ────────────────────────────────────────────────────────────

class _SnippetBlock extends StatelessWidget {
  const _SnippetBlock({required this.snippet});

  final _Snippet snippet;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: snippet.code));
    context.feedback.toast(LocaleKeys.codeCopied.tr());
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File path chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            snippet.label,
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Code block
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Code content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 48, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    snippet.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFD4D4D4),
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              // Copy button
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white60,
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(28, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: LocaleKeys.copyCode.tr(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Nav Bar ──────────────────────────────────────────────────────────────────

class _WizardNavBar extends StatelessWidget {
  const _WizardNavBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onPrev,
    required this.onNext,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    context.locale;
    final isFirst = currentStep == 0;
    final isLast = currentStep == totalSteps - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: isFirst ? null : onPrev,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: Text(LocaleKeys.prevStep.tr()),
            ),
            const Spacer(),
            // Step counter
            Text(
              '${currentStep + 1} / $totalSteps',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.outline,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLast ? null : onNext,
              label: Text(LocaleKeys.nextStep.tr()),
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
    );
  }
}
