// ignore_for_file: avoid_print
/// مولّد شريحة CRUD كاملة — يبني كل الطبقات (dtos → models → datasources →
/// repositories → entities → params → usecases → cubits → pages) مطابقةً حرفياً
/// للبنية والقواعد الصارمة الموصوفة بـ`lib/features/CLAUDE.md`
/// (§API-GENERATOR بـ`lib/core/CLAUDE.md` و§CRUD-PATTERNS).
///
/// كل ملف يُنتج **يُصرَّف ويعمل فوراً** بحقل تجريبي واحد (`title`) — الهدف توفير
/// الطبقات والقواعد (SafeCubit لا Cubit، freezed إلزامي، handle() لا try/catch،
/// PaginationCubit، الخ) لا تخمين الحقول الحقيقية لمشروعك. عدّل الحقول بعد
/// التوليد مباشرة.
///
/// راجع `readme/41_ROADMAP.md` بند #02 للسياق الكامل.
///
/// تشغيل من جذر المشروع:
///   `dart run scripts/scaffold_feature.dart <feature_name>`
///   مثال: dart run scripts/scaffold_feature.dart invoices
library;

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _die('الاستخدام: dart run scripts/scaffold_feature.dart <feature_name>\n'
        '  مثال: dart run scripts/scaffold_feature.dart invoices');
  }

  final feature = _toSnakeCase(args.first);
  if (feature.isEmpty || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(feature)) {
    _die('اسم غير صالح: "${args.first}" — أحرف صغيرة وأرقام و"_" فقط، يبدأ بحرف.');
  }

  final vars = <String, String>{
    '__feature__': feature,
    '__Feature__': _toPascalCase(feature),
    '__featureCamel__': _toCamelCase(feature),
    '__feature-kebab__': feature.replaceAll('_', '-'),
  };

  final featureDir = Directory('lib/features/$feature');
  if (featureDir.existsSync()) {
    _die('lib/features/$feature/ موجود بالفعل — احذفه أولاً إن أردت إعادة التوليد.');
  }

  _header('🏗️   scaffold_feature — إنشاء "${vars['__Feature__']}"');

  _section('📁  كتابة ملفات الشريحة');
  for (final entry in _fileTemplates.entries) {
    _writeFile(_render(entry.key, vars), _render(entry.value, vars));
  }

  _section('🔗  وصل الملفات المشتركة');
  _appendApiUrl(vars);
  _appendInjection(vars);
  _appendRoutes(vars);

  _section('🌍  ترجمة');
  _addTranslationKeys(vars, 'assets/translations/ar.json', _arTranslations);
  _addTranslationKeys(vars, 'assets/translations/en.json', _enTranslations);

  await _stream('⚙️   gen_code — توليد الكود', 'dart', ['run', 'scripts/gen_code.dart']);

  final healthy = await _runHealthChecks();

  _footer(
    healthy
        ? '✅  "${vars['__Feature__']}" جاهزة — التحليل والاختبارات نظيفة'
        : '⚠️   الملفات كُتبت لكن فحصاً واحداً على الأقل فشل — راجع الإخراج أعلاه',
  );

  print(
    'التالي:\n'
    '  1. بدّل الحقل التجريبي "title" بحقول ${vars['__Feature__']} الحقيقية —\n'
    '     domain/entities · data/models · data/dtos · presentation/pages.\n'
    "  2. راجع GET ApiUrls.${vars['__featureCamel__']} مقابل عقد الباك الفعلي.\n"
    '  3. لا اختبارات مولَّدة — أضفها بـtest/features/$feature/ (راجع أمثلة auth/).\n',
  );

  if (!healthy) exit(1);
}

// ── File templates ───────────────────────────────────────────────────────────
// المفتاح: مسار الملف (بـ__tokens__) · القيمة: محتواه (بـ__tokens__).
// كل محتوى raw string (r'''...''') — فـ`$` بداخله حرفيٌّ لا استيفاءً، وهذا
// بالضبط ما تحتاجه أسطرٌ مثل `${ApiUrls.x}/{id}` بالملف الناتج.

final Map<String, String> _fileTemplates = {
  'lib/features/__feature__/domain/entities/__feature___entity.dart': _entityTemplate,
  'lib/features/__feature__/domain/repositories/__feature___repository.dart': _repositoryTemplate,
  'lib/features/__feature__/domain/params/__feature___params.dart': _paramsTemplate,
  'lib/features/__feature__/domain/usecases/get___feature___list.dart': _getListUseCaseTemplate,
  'lib/features/__feature__/domain/usecases/create___feature__.dart': _createUseCaseTemplate,
  'lib/features/__feature__/domain/usecases/update___feature__.dart': _updateUseCaseTemplate,
  'lib/features/__feature__/domain/usecases/delete___feature__.dart': _deleteUseCaseTemplate,
  'lib/features/__feature__/data/dtos/__feature___request_dto.dart': _dtoTemplate,
  'lib/features/__feature__/data/models/__feature___model.dart': _modelTemplate,
  'lib/features/__feature__/data/datasources/__feature___api_service.dart': _apiServiceTemplate,
  'lib/features/__feature__/data/datasources/__feature___remote_datasource.dart': _remoteDataSourceTemplate,
  'lib/features/__feature__/data/repositories/__feature___repository_impl.dart': _repositoryImplTemplate,
  'lib/features/__feature__/presentation/cubits/__feature___list_cubit.dart': _listCubitTemplate,
  'lib/features/__feature__/presentation/cubits/__feature___form_cubit.dart': _formCubitTemplate,
  'lib/features/__feature__/presentation/cubits/__feature___form_state.dart': _formStateTemplate,
  'lib/features/__feature__/presentation/widgets/__feature___item_tile.dart': _itemTileTemplate,
  'lib/features/__feature__/presentation/pages/__feature___list_screen.dart': _listScreenTemplate,
  'lib/features/__feature__/presentation/pages/__feature___form_screen.dart': _formScreenTemplate,
};

const _entityTemplate = r'''
import 'package:equatable/equatable.dart';

/// وُلِّدت بـ`scripts/scaffold_feature.dart` — بدّل `title` بحقول __Feature__
/// الحقيقية.
class __Feature__Entity extends Equatable {
  const __Feature__Entity({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, createdAt];
}
''';

const _repositoryTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';

abstract class __Feature__Repository {
  Future<Either<Failure, PaginationDataEntity<__Feature__Entity>>> getList(
    Get__Feature__ListParams params,
  );

  Future<Either<Failure, __Feature__Entity>> create(
    Create__Feature__Params params,
  );

  Future<Either<Failure, __Feature__Entity>> update(
    Update__Feature__Params params,
  );

  Future<Either<Failure, bool>> delete(Delete__Feature__Params params);
}
''';

const _paramsTemplate = r'''
import 'package:app_template/core/foundation/contracts/pagination_query.dart';
import 'package:app_template/core/foundation/domain/use_case_params.dart';

class Get__Feature__ListParams extends UseCaseParams {
  const Get__Feature__ListParams({required this.paginationQuery});
  final PaginationQuery paginationQuery;
}

class Create__Feature__Params extends UseCaseParams {
  const Create__Feature__Params({required this.title});
  final String title;
}

class Update__Feature__Params extends UseCaseParams {
  const Update__Feature__Params({required this.id, required this.title});
  final String id;
  final String title;
}

class Delete__Feature__Params extends UseCaseParams {
  const Delete__Feature__Params({required this.id});
  final String id;
}
''';

const _getListUseCaseTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class Get__Feature__ListUseCase extends BaseUseCase<
    Either<Failure, PaginationDataEntity<__Feature__Entity>>,
    Get__Feature__ListParams> {
  Get__Feature__ListUseCase(this._repository);

  final __Feature__Repository _repository;

  @override
  Future<Either<Failure, PaginationDataEntity<__Feature__Entity>>> call(
    covariant Get__Feature__ListParams params,
  ) => _repository.getList(params);
}
''';

const _createUseCaseTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class Create__Feature__UseCase
    extends BaseUseCase<Either<Failure, __Feature__Entity>, Create__Feature__Params> {
  Create__Feature__UseCase(this._repository);

  final __Feature__Repository _repository;

  @override
  Future<Either<Failure, __Feature__Entity>> call(
    covariant Create__Feature__Params params,
  ) => _repository.create(params);
}
''';

const _updateUseCaseTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class Update__Feature__UseCase
    extends BaseUseCase<Either<Failure, __Feature__Entity>, Update__Feature__Params> {
  Update__Feature__UseCase(this._repository);

  final __Feature__Repository _repository;

  @override
  Future<Either<Failure, __Feature__Entity>> call(
    covariant Update__Feature__Params params,
  ) => _repository.update(params);
}
''';

const _deleteUseCaseTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class Delete__Feature__UseCase
    extends BaseUseCase<Either<Failure, bool>, Delete__Feature__Params> {
  Delete__Feature__UseCase(this._repository);

  final __Feature__Repository _repository;

  @override
  Future<Either<Failure, bool>> call(covariant Delete__Feature__Params params) =>
      _repository.delete(params);
}
''';

const _dtoTemplate = r'''
/// جسد POST/PUT — بدّل `title` بحقول __Feature__ الحقيقية.
class __Feature__RequestDto {
  const __Feature__RequestDto({required this.title});

  final String title;

  Map<String, dynamic> toJson() => {'title': title};
}
''';

const _modelTemplate = r'''
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';

class __Feature__Model {
  const __Feature__Model({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String createdAt; // النوع الخام من API — يُحوَّل بـtoEntity()

  factory __Feature__Model.fromJson(Map<String, dynamic> json) => __Feature__Model(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
  );

  __Feature__Entity toEntity() => __Feature__Entity(
    id: id,
    title: title,
    createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
  );
}
''';

const _apiServiceTemplate = r'''
import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/features/__feature__/data/dtos/__feature___request_dto.dart';
import 'package:retrofit/retrofit.dart';

part '__feature___api_service.g.dart';

@RestApi()
abstract class __Feature__ApiService {
  factory __Feature__ApiService(Dio dio) =>
      ___Feature__ApiService(dio, baseUrl: Env.baseUrl);

  @GET(ApiUrls.__featureCamel__)
  Future<HttpResponse<dynamic>> getList(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiUrls.__featureCamel__)
  Future<HttpResponse<dynamic>> create(@Body() __Feature__RequestDto body);

  @PUT('${ApiUrls.__featureCamel__}/{id}')
  Future<HttpResponse<dynamic>> update(
    @Path('id') String id,
    @Body() __Feature__RequestDto body,
  );

  @DELETE('${ApiUrls.__featureCamel__}/{id}')
  Future<HttpResponse<dynamic>> delete(@Path('id') String id);
}
''';

const _remoteDataSourceTemplate = r'''
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/features/__feature__/data/datasources/__feature___api_service.dart';
import 'package:app_template/features/__feature__/data/dtos/__feature___request_dto.dart';
import 'package:app_template/features/__feature__/data/models/__feature___model.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class __Feature__RemoteDataSource {
  __Feature__RemoteDataSource(this._apiService);

  final __Feature__ApiService _apiService;

  /// **يفترض شكل صفحة `{items, page, limit, total, total_pages}` تحت `data`** —
  /// طابِقه مع عقد باكك الفعلي (راجع `test/wire_contract_test.dart`).
  Future<ApiResponse<PaginationDataEntity<__Feature__Model>>> getList({
    required int page,
    required int limit,
  }) async {
    final response = await _apiService.getList(page, limit);
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;

    if (data == null) {
      return const ApiResponse(status: 'error', message: '', data: null);
    }

    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => __Feature__Model.fromJson(e as Map<String, dynamic>))
        .toList();
    final currentPage = data['page'] as int? ?? page;
    final totalPages = data['total_pages'] as int? ?? currentPage;

    return ApiResponse.data(
      data: PaginationDataEntity<__Feature__Model>(
        data: items,
        paginationInfo: PaginationInfo(
          isFirstPage: currentPage <= 1,
          isLastPage: currentPage >= totalPages,
        ),
      ),
    );
  }

  Future<ApiResponse<__Feature__Model>> create(__Feature__RequestDto body) async {
    final response = await _apiService.create(body);
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    return ApiResponse.data(
      data: data != null ? __Feature__Model.fromJson(data) : null,
    );
  }

  Future<ApiResponse<__Feature__Model>> update(
    String id,
    __Feature__RequestDto body,
  ) async {
    final response = await _apiService.update(id, body);
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    return ApiResponse.data(
      data: data != null ? __Feature__Model.fromJson(data) : null,
    );
  }

  Future<void> delete(String id) => _apiService.delete(id);
}
''';

const _repositoryImplTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/features/__feature__/data/datasources/__feature___remote_datasource.dart';
import 'package:app_template/features/__feature__/data/dtos/__feature___request_dto.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/repositories/__feature___repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: __Feature__Repository)
class __Feature__RepositoryImpl extends BaseRepository implements __Feature__Repository {
  __Feature__RepositoryImpl(this._dataSource, HandleBodyResponse handler)
      : super(handler);

  final __Feature__RemoteDataSource _dataSource;

  @override
  Future<Either<Failure, PaginationDataEntity<__Feature__Entity>>> getList(
    Get__Feature__ListParams params,
  ) => handle(() async {
    final res = await _dataSource.getList(
      page: params.paginationQuery.page,
      limit: params.paginationQuery.perPage,
    );
    if (res.error != null || res.data == null) {
      return Left(BusinessFailure(statusCode: res.error?.code ?? 400));
    }
    final page = res.data!;
    return Right(
      PaginationDataEntity<__Feature__Entity>(
        data: page.data.map((m) => m.toEntity()).toList(),
        paginationInfo: page.paginationInfo,
      ),
    );
  });

  @override
  Future<Either<Failure, __Feature__Entity>> create(
    Create__Feature__Params params,
  ) => handle(() async {
    final res = await _dataSource.create(
      __Feature__RequestDto(title: params.title),
    );
    if (res.error != null || res.data == null) {
      return Left(BusinessFailure(statusCode: res.error?.code ?? 400));
    }
    return Right(res.data!.toEntity());
  });

  @override
  Future<Either<Failure, __Feature__Entity>> update(
    Update__Feature__Params params,
  ) => handle(() async {
    final res = await _dataSource.update(
      params.id,
      __Feature__RequestDto(title: params.title),
    );
    if (res.error != null || res.data == null) {
      return Left(BusinessFailure(statusCode: res.error?.code ?? 400));
    }
    return Right(res.data!.toEntity());
  });

  @override
  Future<Either<Failure, bool>> delete(Delete__Feature__Params params) =>
      handle(() async {
        await _dataSource.delete(params.id);
        return const Right(true);
      });
}
''';

const _listCubitTemplate = r'''
import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/usecases/get___feature___list.dart';
import 'package:app_template/ui/state/pagination/pagination_cubit.dart';
import 'package:injectable/injectable.dart';

@injectable
class __Feature__ListCubit extends PaginationCubit<__Feature__Entity> {
  __Feature__ListCubit(this._getListUseCase);

  final Get__Feature__ListUseCase _getListUseCase;

  @override
  Future<Either<Failure, PaginationDataEntity<__Feature__Entity>>> call() =>
      _getListUseCase(Get__Feature__ListParams(paginationQuery: paginationQuery));

  @override
  bool isMatchedTwoEntity(__Feature__Entity e1, __Feature__Entity e2) =>
      e1.id == e2.id;
}
''';

const _formCubitTemplate = r'''
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/domain/params/__feature___params.dart';
import 'package:app_template/features/__feature__/domain/usecases/create___feature__.dart';
import 'package:app_template/features/__feature__/domain/usecases/update___feature__.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part '__feature___form_cubit.freezed.dart';
part '__feature___form_state.dart';

@injectable
class __Feature__FormCubit extends SafeCubit<__Feature__FormState> {
  __Feature__FormCubit(this._create, this._update)
      : super(const __Feature__FormState.initial());

  final Create__Feature__UseCase _create;
  final Update__Feature__UseCase _update;

  Future<void> submit({required String? id, required String title}) async {
    emit(const __Feature__FormState.loading());

    final res = id == null
        ? await _create(Create__Feature__Params(title: title))
        : await _update(Update__Feature__Params(id: id, title: title));

    res.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(__Feature__FormState.error(errorMessage: message));
          case NavigateToLogin():
            break;
          case Silent():
            break;
        }
      },
      (entity) => emit(__Feature__FormState.success(entity: entity)),
    );
  }
}
''';

const _formStateTemplate = r'''
part of '__feature___form_cubit.dart';

@freezed
abstract class __Feature__FormState with _$__Feature__FormState {
  const factory __Feature__FormState.initial() = __Feature__FormInitial;
  const factory __Feature__FormState.loading() = __Feature__FormLoading;
  const factory __Feature__FormState.success({required __Feature__Entity entity}) =
      __Feature__FormSuccess;
  const factory __Feature__FormState.error({required String errorMessage}) =
      __Feature__FormError;
}
''';

const _itemTileTemplate = r'''
import 'package:flutter/material.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// صفٌّ واحد بقائمة __Feature__ — استُخرج ودجةً مسمّاة (لا دالة) حتى تُبنى مرّة
/// واحدة وتحمل اسمها بشجرة الأخطاء. راجع lib/CLAUDE.md §بنية الصفحة.
class __Feature__ItemTile extends StatelessWidget {
  const __Feature__ItemTile({required this.entity, required this.onTap, super.key});

  final __Feature__Entity entity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppListTile(
    titleText: entity.title,
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}
''';

const _listScreenTemplate = r'''
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/presentation/cubits/__feature___list_cubit.dart';
import 'package:app_template/features/__feature__/presentation/widgets/__feature___item_tile.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';

@RoutePage()
class __Feature__ListScreen extends StatelessWidget {
  const __Feature__ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<__Feature__ListCubit>(),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.__featureCamel__ListTitle.tr())),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context, null),
          child: const Icon(Icons.add),
        ),
        body: PaginationBuilderWdg<__Feature__ListCubit, __Feature__Entity>(
          notItemsMsg: LocaleKeys.__featureCamel__Empty.tr(),
          itemWdg: (entity) => __Feature__ItemTile(
            entity: entity,
            onTap: () => _openForm(context, entity),
          ),
          separatorWidget: const SizedBox(height: 4),
          wantKeepAlive: true,
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, __Feature__Entity? entity) async {
    final cubit = context.read<__Feature__ListCubit>();
    final saved = await context.router.push<__Feature__Entity?>(
      __Feature__FormRoute(entity: entity),
    );
    if (saved == null) return;
    entity == null ? cubit.prependItem(saved) : cubit.replaceEntityItem(saved);
  }
}
''';

const _formScreenTemplate = r'''
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/features/__feature__/domain/entities/__feature___entity.dart';
import 'package:app_template/features/__feature__/presentation/cubits/__feature___form_cubit.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// إضافة وتعديل بملفٍّ واحد — `entity == null` يعني إضافة.
@RoutePage()
class __Feature__FormScreen extends StatefulWidget {
  const __Feature__FormScreen({this.entity, super.key});

  final __Feature__Entity? entity;

  @override
  State<__Feature__FormScreen> createState() => ___Feature__FormScreenState();
}

class ___Feature__FormScreenState extends State<__Feature__FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl = TextEditingController(text: widget.entity?.title);
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entity != null;
    return BlocProvider(
      create: (_) => getIt<__Feature__FormCubit>(),
      child: BlocConsumer<__Feature__FormCubit, __Feature__FormState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (entity) => context.router.pop(entity),
            error: (msg) => _onError(msg),
            orElse: () {},
          );
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(
              (isEdit
                      ? LocaleKeys.__featureCamel__FormTitleEdit
                      : LocaleKeys.__featureCamel__FormTitleAdd)
                  .tr(),
            ),
          ),
          body: _FormBody(
            formKey: _formKey,
            titleCtrl: _titleCtrl,
            submitted: _submitted,
            isLoading: _isLoading,
            onSubmit: () => _submit(context),
          ),
        ),
      ),
    );
  }

  void _onError(String message) {
    setState(() => _isLoading = false);
    context.feedback.error(message);
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    context.unfocus();
    setState(() => _isLoading = true);
    context.read<__Feature__FormCubit>().submit(
          id: widget.entity?.id,
          title: _titleCtrl.text.trim(),
        );
  }
}

/// جسد النموذج وحده — مستخرَج ودجةً مسمّاة كي يبقى `build()` بالشاشة تحت
/// السقف المفروض (٥٠ سطراً). راجع lib/CLAUDE.md §بنية الصفحة.
class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.titleCtrl,
    required this.submitted,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final bool submitted;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => KeyboardDismissWidget(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        autovalidateMode: submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            CustomTextField(
              controller: titleCtrl,
              labelText: LocaleKeys.__featureCamel__TitleFieldLabel.tr(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? LocaleKeys.fieldRequired.tr() : null,
            ),
            16.heightBox,
            PrimaryButton(
              text: LocaleKeys.save.tr(),
              isLoading: isLoading,
              isEnabled: !isLoading,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    ),
  );
}
''';

// ── Shared-file edits ─────────────────────────────────────────────────────────

void _appendApiUrl(Map<String, String> vars) {
  final file = File('lib/core/infra/network/rest/api_urls.dart');
  const marker = '  // ── Your own features go below ────────────────────────────────────────────\n}';
  final line =
      "  static const String ${vars['__featureCamel__']} = '/api/v1/${vars['__feature-kebab__']}';\n\n$marker";
  final content = file.readAsStringSync();
  if (!content.contains(marker)) {
    _die('لم أجد نقطة الوصل بـ${file.path} — راجعها يدوياً.');
  }
  file.writeAsStringSync(content.replaceFirst(marker, line));
  print('  ✓ api_urls.dart');
}

void _appendInjection(Map<String, String> vars) {
  final file = File('lib/core/di/injection_module.dart');
  var content = file.readAsStringSync();

  final feature = vars['__feature__']!;
  final featurePascal = vars['__Feature__']!;
  final camel = vars['__featureCamel__']!;

  const importMarker = "import 'injection.dart';";
  final newImport =
      "import 'package:app_template/features/$feature/data/datasources/${feature}_api_service.dart';\n$importMarker";
  if (!content.contains(importMarker)) {
    _die('لم أجد نقطة إدراج الـimport بـ${file.path}.');
  }
  content = content.replaceFirst(importMarker, newImport);

  const registrationMarker = '''
  @lazySingleton
  VerifyEmailApiService verifyEmailApiService(Dio dio) =>
      VerifyEmailApiService(dio);''';
  final newRegistration = '''
$registrationMarker

  @lazySingleton
  ${featurePascal}ApiService ${camel}ApiService(Dio dio) => ${featurePascal}ApiService(dio);''';
  if (!content.contains(registrationMarker)) {
    _die('لم أجد نقطة تسجيل ApiService بـ${file.path}.');
  }
  content = content.replaceFirst(registrationMarker, newRegistration);

  file.writeAsStringSync(content);
  print('  ✓ injection_module.dart');
}

void _appendRoutes(Map<String, String> vars) {
  final file = File('lib/routes/router.dart');
  final featurePascal = vars['__Feature__']!;
  const marker = "    AutoRoute(page: ErrorRoute.page, path: '/error'),";
  final newRoutes =
      "    AutoRoute(page: ${featurePascal}ListRoute.page, path: '/${vars['__feature-kebab__']}'),\n"
      "    AutoRoute(page: ${featurePascal}FormRoute.page, path: '/${vars['__feature-kebab__']}/form'),\n\n"
      '$marker';
  final content = file.readAsStringSync();
  if (!content.contains(marker)) {
    _die('لم أجد نقطة إدراج المسارات بـ${file.path}.');
  }
  file.writeAsStringSync(content.replaceFirst(marker, newRoutes));
  print(
    '  ✓ router.dart (سيُحلّ ${featurePascal}ListRoute/${featurePascal}FormRoute بعد build_runner)',
  );
}

// ── Translations ──────────────────────────────────────────────────────────────

Map<String, String> _arTranslations(String camel, String pascal) => {
      '${camel}ListTitle': pascal,
      '${camel}Empty': 'لا توجد عناصر بعد',
      '${camel}FormTitleAdd': 'إضافة',
      '${camel}FormTitleEdit': 'تعديل',
      '${camel}TitleFieldLabel': 'العنوان',
    };

Map<String, String> _enTranslations(String camel, String pascal) => {
      '${camel}ListTitle': pascal,
      '${camel}Empty': 'No items yet',
      '${camel}FormTitleAdd': 'Add',
      '${camel}FormTitleEdit': 'Edit',
      '${camel}TitleFieldLabel': 'Title',
    };

void _addTranslationKeys(
  Map<String, String> vars,
  String path,
  Map<String, String> Function(String camel, String pascal) build,
) {
  final file = File(path);
  final content = file.readAsStringSync();
  final decoded = _decodeJsonObject(content);
  final newKeys = build(vars['__featureCamel__']!, vars['__Feature__']!);

  for (final entry in newKeys.entries) {
    if (decoded.containsKey(entry.key)) {
      _die('المفتاح "${entry.key}" موجود بالفعل بـ$path — الشريحة أُنشئت من قبل؟');
    }
    decoded[entry.key] = entry.value;
  }

  final sorted = Map.fromEntries(
    decoded.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  file.writeAsStringSync('${_encodeJsonObject(sorted)}\n');
  print('  ✓ $path (+${newKeys.length} مفتاحاً)');
}

// ── JSON helpers (dart:convert فقط) ──────────────────────────────────────────

Map<String, dynamic> _decodeJsonObject(String content) =>
    Map<String, dynamic>.from(jsonDecode(content) as Map<dynamic, dynamic>);

String _encodeJsonObject(Map<String, dynamic> data) =>
    const JsonEncoder.withIndent('  ').convert(data);

// ── Output helpers (بنمط scripts/gen_code.dart) ────────────────────────────────

Future<void> _stream(String label, String exe, List<String> args) async {
  _section(label);
  final process = await Process.start(exe, args, runInShell: true);
  await Future.wait([
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  final code = await process.exitCode;
  if (code != 0) _die('فشل الأمر (exit $code): $exe ${args.join(' ')}');
  print('');
}

Future<bool> _runHealthChecks() async {
  _header('🩺  فحوصات ما بعد التوليد');
  var allPassed = true;
  allPassed &= await _check('🔍  dart analyze lib', 'dart', ['analyze', 'lib']);
  allPassed &= await _check('🧪  flutter test', 'flutter', ['test']);
  allPassed &= await _check(
    '🏗   check_structure',
    'dart',
    ['run', 'scripts/check_structure.dart'],
  );
  return allPassed;
}

Future<bool> _check(String label, String exe, List<String> args) async {
  _section(label);
  final process = await Process.start(exe, args, runInShell: true);
  await Future.wait([
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  final code = await process.exitCode;
  final ok = code == 0;
  print(ok ? '  ✅  نجح' : '  ❌  فشل (exit $code)');
  return ok;
}

void _writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  print('  ✓ $path');
}

String _render(String template, Map<String, String> vars) {
  var result = template;
  for (final entry in vars.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

// ── Case conversion ───────────────────────────────────────────────────────────

String _toSnakeCase(String input) => input
    .trim()
    .replaceAll(RegExp(r'[\s-]+'), '_')
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)}_${m.group(2)}',
    )
    .toLowerCase();

String _toPascalCase(String snake) => snake
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join();

String _toCamelCase(String snake) {
  final pascal = _toPascalCase(snake);
  return pascal.isEmpty ? pascal : pascal[0].toLowerCase() + pascal.substring(1);
}

void _header(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}');
void _footer(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}\n');
void _section(String msg) => print('\n▸ $msg');
void _die(String msg) {
  print('\n❌  $msg\n');
  exit(1);
}
