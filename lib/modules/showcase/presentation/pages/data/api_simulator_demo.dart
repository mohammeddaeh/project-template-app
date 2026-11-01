import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// A request's path through this template's REST stack, stage by stage —
/// interceptors in their registration order (`injection_module.dart`), the
/// failure mapper, the repository boundary, the UI mapper. Nothing is sent:
/// the stages are drawn from the interceptors' own rules, and the failure at
/// the end is a real [Failure] put through the real [FailureUiMapper].
///
/// The knobs are the decisions a project actually makes: opting a GET into the
/// cache, `RetryInterceptor(maxRetries:)`, whether a `TokenRefreshGateway` is
/// registered — plus what the server and the refresh call answer.
class ApiSimulatorDemo extends StatefulWidget {
  const ApiSimulatorDemo({super.key});

  @override
  State<ApiSimulatorDemo> createState() => _ApiSimulatorDemoState();
}

enum _Outcome {
  ok('200', 200),
  unauthorized('401', 401),
  forbidden('403', 403),
  notFound('404', 404),
  validation('422', 422),
  server('500', 500),
  unavailable('503', 503),
  timeout('timeout', null),
  offline('offline', null);

  const _Outcome(this.label, this.status);

  final String label;
  final int? status;

  /// `RetryInterceptor._isRetryable` for the answers this simulator offers:
  /// timeouts and 408/502/503/504 — never 4xx, never 500.
  bool get retryable => this == timeout || this == unavailable;
}

enum _CacheEntry { none, fresh, stale }

enum _RetryAfter { none, s5, s30 }

enum _Refresh { succeeds, refused, unreachable }

enum _StepState { passed, stopped, skipped }

/// How the run ends, which decides the line under the stages.
enum _End { data, cache, error, login, deferred }

class _Step {
  const _Step(this.code, this.note, [this.state = _StepState.passed]);

  final String code;
  final String note;
  final _StepState state;
}

class _Run {
  _Run(this.steps, this.end, [this.failure]);

  final List<_Step> steps;
  final _End end;
  final Failure? failure;
}

class _ApiSimulatorDemoState extends State<ApiSimulatorDemo> {
  _Outcome _outcome = _Outcome.ok;

  // Knobs — each one a real decision in a project.
  bool _cacheOptIn = false;
  _CacheEntry _cacheEntry = _CacheEntry.none;
  int _maxRetries = 3; // RetryInterceptor's default
  int _recoverOn = 0; // 0 = the server never recovers
  _RetryAfter _retryAfter = _RetryAfter.none;
  bool _hasRefresh = true; // the template registers TokenRefreshGatewayImpl
  _Refresh _refresh = _Refresh.succeeds;

  int _revealed = -1;
  int _runId = 0;

  void _change(VoidCallback f) => setState(() {
    f();
    _runId++;
    _revealed = -1;
  });

  Failure _failureFor(_Outcome o) => switch (o) {
    _Outcome.unauthorized => const UnauthorizedFailure(),
    _Outcome.forbidden => const ForbiddenFailure(),
    _Outcome.notFound => BusinessFailure(
      statusCode: 404,
      serverMessage: LocaleKeys.showcaseApiNotFound.tr(),
    ),
    // `ServerMessageExtractor` lifts the first entry of `errors` — that is
    // the message the user reads.
    _Outcome.validation => BusinessFailure(
      statusCode: 422,
      serverMessage: LocaleKeys.showcaseApiFieldError.tr(),
    ),
    _Outcome.server => const ServerFailure(statusCode: 500),
    _Outcome.unavailable => ServiceUnavailableFailure(
      statusCode: 503,
      retryAfterSeconds: switch (_retryAfter) {
        _RetryAfter.none => null,
        _RetryAfter.s5 => 5,
        _RetryAfter.s30 => 30,
      },
    ),
    _Outcome.timeout => const TimeoutFailure(),
    _Outcome.offline => const NoInternetFailure(),
    _Outcome.ok => throw StateError('200 is not a failure'),
  };

  String _failureName(Failure f) => switch (f) {
    UnauthorizedFailure() => 'UnauthorizedFailure',
    ForbiddenFailure() => 'ForbiddenFailure',
    BusinessFailure(:final statusCode) => 'BusinessFailure($statusCode)',
    ServerFailure(:final statusCode) => 'ServerFailure($statusCode)',
    ServiceUnavailableFailure(:final statusCode, :final retryAfterSeconds) =>
      'ServiceUnavailableFailure($statusCode'
          '${retryAfterSeconds == null ? '' : ', retryAfter: $retryAfterSeconds'})',
    TimeoutFailure() => 'TimeoutFailure',
    NoInternetFailure() => 'NoInternetFailure',
    _ => 'Failure',
  };

  _Step _serverStep(_Outcome o, {String suffix = ''}) {
    final (code, key) = switch (o) {
      _Outcome.ok => ('HTTP 200', LocaleKeys.showcaseApiServer200),
      _Outcome.unauthorized => ('HTTP 401', LocaleKeys.showcaseApiServer401),
      _Outcome.forbidden => ('HTTP 403', LocaleKeys.showcaseApiServer403),
      _Outcome.notFound => ('HTTP 404', LocaleKeys.showcaseApiServer404),
      _Outcome.validation => ('HTTP 422', LocaleKeys.showcaseApiServer422),
      _Outcome.server => ('HTTP 500', LocaleKeys.showcaseApiServer500),
      _Outcome.unavailable => ('HTTP 503', LocaleKeys.showcaseApiServer503),
      _Outcome.timeout => ('…', LocaleKeys.showcaseApiServerTimeout),
      _Outcome.offline => ('Server', LocaleKeys.showcaseApiServerNone),
    };
    return _Step(
      '$code$suffix',
      key.tr(),
      o == _Outcome.ok ? _StepState.passed : _StepState.stopped,
    );
  }

  /// The run, decided before it is drawn — every branch is a rule read from
  /// the interceptor that owns it.
  _Run _plan() {
    final steps = <_Step>[
      _Step('NetworkOriginInterceptor', LocaleKeys.showcaseApiStepOrigin.tr()),
    ];

    _Run succeed({required bool fromCache}) {
      if (_cacheOptIn && !fromCache) {
        steps.add(
          _Step(
            'RequestCacheInterceptor.onResponse → WRITE',
            LocaleKeys.showcaseApiCacheWrite.tr(),
          ),
        );
      }
      steps.addAll([
        _Step('HandleBodyResponse', LocaleKeys.showcaseApiStepBody.tr()),
        _Step(
          'BaseRepository.handle → Right(data)',
          LocaleKeys.showcaseApiStepRepository.tr(),
        ),
        _Step('Cubit → emit(success)', LocaleKeys.showcaseApiCubit.tr()),
      ]);
      return _Run(steps, fromCache ? _End.cache : _End.data);
    }

    _Run fail(Failure failure, [_End? end]) {
      final action = FailureUiMapper.toAction(failure);
      steps.addAll([
        _Step(
          'FailureMapperRegistry → ${_failureName(failure)}',
          LocaleKeys.showcaseApiStepMapper.tr(),
        ),
        _Step(
          'BaseRepository.handle → Left(failure)',
          LocaleKeys.showcaseApiStepRepository.tr(),
        ),
        _Step(
          'FailureUiMapper.toAction → ${switch (action) {
            ShowError(:final canRetry) => 'ShowError(canRetry: $canRetry)',
            NavigateToLogin() => 'NavigateToLogin',
            Silent() => 'Silent',
          }}',
          LocaleKeys.showcaseApiStepUiMapper.tr(),
        ),
      ]);
      return _Run(
        steps,
        end ?? (action is NavigateToLogin ? _End.login : _End.error),
        failure,
      );
    }

    // 1. The cache — before the offline guard, so it can answer offline.
    if (!_cacheOptIn) {
      steps.add(
        _Step('RequestCacheInterceptor', LocaleKeys.showcaseApiCacheOff.tr()),
      );
    } else {
      switch (_cacheEntry) {
        case _CacheEntry.fresh:
          steps.add(
            _Step(
              'RequestCacheInterceptor → HIT · handler.resolve()',
              LocaleKeys.showcaseApiCacheHit.tr(),
            ),
          );
          return succeed(fromCache: true);
        case _CacheEntry.stale:
          steps.add(
            _Step(
              'RequestCacheInterceptor → STALE',
              LocaleKeys.showcaseApiCacheStale.tr(),
            ),
          );
        case _CacheEntry.none:
          steps.add(
            _Step(
              'RequestCacheInterceptor → MISS',
              LocaleKeys.showcaseApiCacheMiss.tr(),
            ),
          );
      }
    }

    // 2. The offline guard — the request never leaves.
    if (_outcome == _Outcome.offline) {
      steps.addAll([
        _Step(
          'InternetCheckerInterceptor',
          LocaleKeys.showcaseApiGuardBlocked.tr(),
          _StepState.stopped,
        ),
        _Step(
          'AuthInterceptor',
          LocaleKeys.showcaseApiStepAuth.tr(),
          _StepState.skipped,
        ),
        _serverStep(_Outcome.offline),
        _Step(
          'RetryInterceptor.onError',
          LocaleKeys.showcaseApiBackRetryOffline.tr(),
        ),
      ]);
      return fail(_failureFor(_Outcome.offline));
    }
    steps
      ..add(
        _Step(
          'InternetCheckerInterceptor',
          LocaleKeys.showcaseApiStepGuard.tr(),
        ),
      )
      ..add(_Step('AuthInterceptor', LocaleKeys.showcaseApiStepAuth.tr()));

    // 3. The server, and the error interceptors in registration order:
    //    AuthInterceptor → TokenRefreshInterceptor → RetryInterceptor.
    for (var attempt = 0; ; attempt++) {
      final answer = attempt > 0 && attempt == _recoverOn
          ? _Outcome.ok
          : _outcome;
      steps.add(
        _serverStep(answer, suffix: attempt == 0 ? '' : '  (retry $attempt)'),
      );
      if (answer == _Outcome.ok) return succeed(fromCache: false);

      switch (answer) {
        case _Outcome.unauthorized when !_hasRefresh:
          steps.add(
            _Step(
              'AuthInterceptor.onError',
              LocaleKeys.showcaseApiAuthExpire.tr(),
              _StepState.stopped,
            ),
          );
          return fail(_failureFor(answer));
        case _Outcome.unauthorized:
          switch (_refresh) {
            case _Refresh.succeeds:
              steps.addAll([
                _Step(
                  'TokenRefreshInterceptor.onError → refresh()',
                  LocaleKeys.showcaseApiRefreshOk.tr(),
                ),
                _serverStep(_Outcome.ok, suffix: '  (replay)'),
              ]);
              return succeed(fromCache: false);
            case _Refresh.refused:
              steps.add(
                _Step(
                  'TokenRefreshInterceptor.onError → refresh() ✕',
                  LocaleKeys.showcaseApiRefreshRefused.tr(),
                  _StepState.stopped,
                ),
              );
              return fail(_failureFor(answer));
            case _Refresh.unreachable:
              steps.add(
                _Step(
                  'TokenRefreshInterceptor.onError → refresh() ⌁',
                  LocaleKeys.showcaseApiRefreshDeferred.tr(),
                  _StepState.stopped,
                ),
              );
              return fail(_failureFor(answer), _End.deferred);
          }
        case _Outcome.forbidden:
          steps.add(
            _Step(
              'AuthInterceptor.onError',
              LocaleKeys.showcaseApiAuthForbidden.tr(),
            ),
          );
          return fail(_failureFor(answer));
        case _Outcome.server:
          steps.add(
            _Step(
              'RetryInterceptor.onError',
              LocaleKeys.showcaseApiBackRetry500.tr(),
            ),
          );
          return fail(_failureFor(answer));
        case _ when answer.retryable:
          if (answer == _Outcome.unavailable &&
              _retryAfter == _RetryAfter.s30) {
            steps.add(
              _Step(
                'RetryInterceptor.onError  (Retry-After: 30)',
                LocaleKeys.showcaseApiRetryAfterLong.tr(),
                _StepState.stopped,
              ),
            );
            return fail(_failureFor(answer));
          }
          if (attempt >= _maxRetries) {
            steps.add(
              _Step(
                'RetryInterceptor.onError',
                _maxRetries == 0
                    ? LocaleKeys.showcaseApiRetryNone.tr()
                    : LocaleKeys.showcaseApiRetryUsedUp.tr(
                        args: ['$_maxRetries'],
                      ),
                _StepState.stopped,
              ),
            );
            return fail(_failureFor(answer));
          }
          final serverWait =
              answer == _Outcome.unavailable && _retryAfter == _RetryAfter.s5;
          final wait = serverWait ? 5 : 1 << attempt;
          steps.add(
            _Step(
              'RetryInterceptor.onError → retry ${attempt + 1}/$_maxRetries',
              serverWait
                  ? LocaleKeys.showcaseApiRetryWaitServer.tr(args: ['$wait'])
                  : LocaleKeys.showcaseApiRetryWait.tr(args: ['$wait']),
            ),
          );
        default:
          // 404 · 422 — a client error: no interceptor steps in.
          return fail(_failureFor(answer));
      }
    }
  }

  Future<void> _send(int count) async {
    final run = ++_runId;
    setState(() => _revealed = 0);
    for (var i = 1; i <= count; i++) {
      // A pace to read by, not a network delay.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || run != _runId) return;
      setState(() => _revealed = i);
    }
  }

  String get _code {
    final lines = [
      'Dio → interceptors → FailureMapperRegistry → '
          'BaseRepository.handle → FailureUiMapper',
      if (_cacheOptIn)
        "dio.get('/items', options: Options(extra: "
            '{RequestCacheInterceptor.cacheKey: true}))',
      if (_maxRetries != 3) 'RetryInterceptor(dio, maxRetries: $_maxRetries)',
      if (!_hasRefresh) '// no TokenRefreshGateway registered',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    final run = _plan();
    final steps = run.steps;
    final done = _revealed >= steps.length;
    final failure = run.failure;
    final action = failure == null ? null : FailureUiMapper.toAction(failure);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: context.colors.textMuted,
              ),
              8.widthBox,
              Expanded(
                child: Text(
                  LocaleKeys.showcaseSimulated.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: _code,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KnobLabel(LocaleKeys.showcaseApiServerAnswers.tr()),
              ChipRow<_Outcome>(
                items: _Outcome.values,
                labelResolver: (o) => o.label,
                selectedValue: _outcome,
                scrollable: false,
                onSelected: (o) => _change(() => _outcome = o ?? _outcome),
              ),
              12.heightBox,
              ExpandableSection(
                titleKey: LocaleKeys.showcaseApiKnobs,
                leading: const Icon(Icons.tune),
                initiallyExpanded: true,
                child: _knobs(context),
              ),
              12.heightBox,
              AppButton(
                text: LocaleKeys.showcaseApiSend.tr(),
                leadingIcon: Icons.send_outlined,
                isLoading: _revealed >= 0 && !done,
                onTap: () => _send(steps.length),
              ),
              12.heightBox,
              for (final (i, step) in steps.indexed)
                _StepRow(
                  step: step,
                  shown: _revealed > i,
                  current: _revealed == i,
                ),
              if (done) ...[
                12.heightBox,
                switch (run.end) {
                  _End.data => _Outcomeline(LocaleKeys.showcaseApiCubit.tr()),
                  _End.cache => _Outcomeline(
                    LocaleKeys.showcaseApiUiFromCache.tr(),
                  ),
                  _End.login => _Outcomeline(
                    LocaleKeys.showcaseApiUiLogin.tr(),
                  ),
                  _End.deferred => _Outcomeline(
                    LocaleKeys.showcaseApiUiDeferred.tr(),
                  ),
                  _End.error => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Outcomeline(LocaleKeys.showcaseApiUiError.tr()),
                      FailureStateView.compact(
                        failure: failure!,
                        onRetry: action is ShowError && action.canRetry
                            ? () => _send(steps.length)
                            : null,
                      ),
                    ],
                  ),
                },
              ],
            ],
          ),
        ),
        const _RetryRules(),
        const _OriginGuardSim(),
      ],
    );
  }

  Widget _knobs(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Cache.
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const _Code('extra: {RequestCacheInterceptor.cacheKey: true}'),
        subtitle: Text(LocaleKeys.showcaseApiKnobCache.tr()),
        value: _cacheOptIn,
        onChanged: (v) => _change(() => _cacheOptIn = v),
      ),
      if (_cacheOptIn) ...[
        _KnobLabel(LocaleKeys.showcaseApiKnobCacheEntry.tr()),
        ChipRow<_CacheEntry>(
          items: _CacheEntry.values,
          labelResolver: (e) => switch (e) {
            _CacheEntry.none => LocaleKeys.showcaseApiEntryNone.tr(),
            _CacheEntry.fresh => LocaleKeys.showcaseApiEntryFresh.tr(),
            _CacheEntry.stale => LocaleKeys.showcaseApiEntryStale.tr(),
          },
          selectedValue: _cacheEntry,
          scrollable: false,
          onSelected: (e) => _change(() => _cacheEntry = e ?? _cacheEntry),
        ),
        12.heightBox,
      ],
      // Retry.
      const _KnobLabel('RetryInterceptor(dio, maxRetries: …)'),
      ChipRow<int>(
        items: const [0, 1, 2, 3],
        labelResolver: (n) => '$n',
        selectedValue: _maxRetries,
        scrollable: false,
        onSelected: (n) => _change(() => _maxRetries = n ?? _maxRetries),
      ),
      12.heightBox,
      _KnobLabel(LocaleKeys.showcaseApiKnobRecover.tr()),
      ChipRow<int>(
        items: const [0, 1, 2, 3],
        labelResolver: (n) =>
            n == 0 ? LocaleKeys.showcaseApiRecoverNever.tr() : '$n',
        selectedValue: _recoverOn,
        scrollable: false,
        onSelected: (n) => _change(() => _recoverOn = n ?? _recoverOn),
      ),
      12.heightBox,
      _KnobLabel(LocaleKeys.showcaseApiKnobRetryAfter.tr()),
      ChipRow<_RetryAfter>(
        items: _RetryAfter.values,
        labelResolver: (r) => switch (r) {
          _RetryAfter.none => '—',
          _RetryAfter.s5 => 'Retry-After: 5',
          _RetryAfter.s30 => 'Retry-After: 30',
        },
        selectedValue: _retryAfter,
        scrollable: false,
        onSelected: (r) => _change(() => _retryAfter = r ?? _retryAfter),
      ),
      12.heightBox,
      // Token refresh.
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const _Code('getIt.isRegistered<TokenRefreshGateway>()'),
        subtitle: Text(LocaleKeys.showcaseApiKnobRefresh.tr()),
        value: _hasRefresh,
        onChanged: (v) => _change(() => _hasRefresh = v),
      ),
      if (_hasRefresh) ...[
        _KnobLabel(LocaleKeys.showcaseApiKnobRefreshAnswer.tr()),
        ChipRow<_Refresh>(
          items: _Refresh.values,
          labelResolver: (r) => switch (r) {
            _Refresh.succeeds => LocaleKeys.showcaseApiRefreshAnswerOk.tr(),
            _Refresh.refused => LocaleKeys.showcaseApiRefreshAnswerRefused.tr(),
            _Refresh.unreachable =>
              LocaleKeys.showcaseApiRefreshAnswerUnreachable.tr(),
          },
          selectedValue: _refresh,
          scrollable: false,
          onSelected: (r) => _change(() => _refresh = r ?? _refresh),
        ),
      ],
    ],
  );
}

/// `RetryInterceptor._isRetryable`, as a table.
class _RetryRules extends StatelessWidget {
  const _RetryRules();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget row(String label, String codes, Color tone, IconData icon) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: tone),
              8.widthBox,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(label, style: context.textTheme.labelMedium),
                    _Code(codes),
                  ],
                ),
              ),
            ],
          ),
        );

    return DemoBlock(
      code: 'RetryInterceptor._isRetryable(err)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            LocaleKeys.showcaseApiRetried.tr(),
            'connectionError · connectionTimeout · receiveTimeout · '
            '408 · 502 · 503 · 504',
            colors.statusSuccessFg,
            Icons.replay,
          ),
          row(
            LocaleKeys.showcaseApiNotRetried.tr(),
            '4xx · 401 · 500 · 501 · 505 · cancel · '
            'InternetCheckerInterceptor.blockedOfflineKey',
            colors.error,
            Icons.block,
          ),
          8.heightBox,
          Text(
            LocaleKeys.showcaseApiRetryRulesNote.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DataOriginGuard ────────────────────────────────────────────────────────

enum _Origin { firstRun, same, changed, emptyBaseUrl }

/// `DataOriginGuard.ensureCurrentOrigin()` — the first question at startup,
/// before any token is read.
class _OriginGuardSim extends StatefulWidget {
  const _OriginGuardSim();

  @override
  State<_OriginGuardSim> createState() => _OriginGuardSimState();
}

class _OriginGuardSimState extends State<_OriginGuardSim> {
  static const _current = "'https://api.example.com'";
  static const _old = "'https://staging.example.com'";

  _Origin _origin = _Origin.changed;
  int _revealed = -1;
  int _runId = 0;

  List<_Step> get _steps {
    final read = 'storage.readString(PersistenceKeys.dataOrigin)';
    const write =
        'storage.writeString(PersistenceKeys.dataOrigin, Env.baseUrl)';
    return [
      _Step(
        'StartupResolver.resolve() → DataOriginGuard.ensureCurrentOrigin()',
        LocaleKeys.showcaseApiOriginStart.tr(),
      ),
      ...switch (_origin) {
        _Origin.emptyBaseUrl => [
          _Step(
            "Env.baseUrl == ''",
            LocaleKeys.showcaseApiOriginEmpty.tr(),
            _StepState.stopped,
          ),
          _Step('→ false', LocaleKeys.showcaseApiOriginKept.tr()),
        ],
        _Origin.firstRun => [
          _Step('$read → null', LocaleKeys.showcaseApiOriginFirst.tr()),
          _Step(write, LocaleKeys.showcaseApiOriginWrite.tr()),
          _Step('→ false', LocaleKeys.showcaseApiOriginKept.tr()),
        ],
        _Origin.same => [
          _Step('$read → $_current', LocaleKeys.showcaseApiOriginSame.tr()),
          _Step('→ false', LocaleKeys.showcaseApiOriginKept.tr()),
        ],
        _Origin.changed => [
          _Step(
            '$read → $_old',
            LocaleKeys.showcaseApiOriginChanged.tr(),
            _StepState.stopped,
          ),
          _Step(
            'SessionRepository.clearSession()',
            LocaleKeys.showcaseApiOriginSession.tr(),
          ),
          _Step(
            'AccountDataCleaner.clearForSignOut()',
            LocaleKeys.showcaseApiOriginAccount.tr(),
          ),
          _Step(
            'storage.delete(PersistenceKeys.rememberedAccounts)',
            LocaleKeys.showcaseApiOriginRemembered.tr(),
          ),
          _Step(write, LocaleKeys.showcaseApiOriginWrite.tr()),
          _Step('→ true', LocaleKeys.showcaseApiOriginWiped.tr()),
        ],
      },
    ];
  }

  Future<void> _launch(int count) async {
    final run = ++_runId;
    setState(() => _revealed = 0);
    for (var i = 1; i <= count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || run != _runId) return;
      setState(() => _revealed = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final done = _revealed >= steps.length;
    return DemoBlock(
      code: 'await getIt<DataOriginGuard>().ensureCurrentOrigin();',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.showcaseApiOriginIntro.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          8.heightBox,
          const _Code('Env.baseUrl = $_current'),
          12.heightBox,
          ChipRow<_Origin>(
            items: _Origin.values,
            labelResolver: (o) => switch (o) {
              _Origin.firstRun => LocaleKeys.showcaseApiOriginFirstRun.tr(),
              _Origin.same => LocaleKeys.showcaseApiOriginSameServer.tr(),
              _Origin.changed => LocaleKeys.showcaseApiOriginNewServer.tr(),
              _Origin.emptyBaseUrl => LocaleKeys.showcaseApiOriginNoUrl.tr(),
            },
            selectedValue: _origin,
            scrollable: false,
            onSelected: (o) => setState(() {
              _origin = o ?? _origin;
              _runId++;
              _revealed = -1;
            }),
          ),
          12.heightBox,
          AppButton(
            text: LocaleKeys.showcaseApiOriginLaunch.tr(),
            leadingIcon: Icons.power_settings_new,
            isLoading: _revealed >= 0 && !done,
            onTap: () => _launch(steps.length),
          ),
          12.heightBox,
          for (final (i, step) in steps.indexed)
            _StepRow(step: step, shown: _revealed > i, current: _revealed == i),
        ],
      ),
    );
  }
}

// ── Shared pieces ──────────────────────────────────────────────────────────

class _Code extends StatelessWidget {
  const _Code(this.code);

  final String code;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      code,
      textAlign: Directionality.of(context) == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
      ),
    ),
  );
}

class _KnobLabel extends StatelessWidget {
  const _KnobLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: context.textTheme.labelMedium),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.shown,
    required this.current,
  });

  final _Step step;
  final bool shown;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, tone) = !shown
        ? (Icons.circle_outlined, colors.textMuted)
        : switch (step.state) {
            _StepState.passed => (Icons.check_circle, colors.statusSuccessFg),
            _StepState.stopped => (Icons.cancel, colors.error),
            _StepState.skipped => (
              Icons.remove_circle_outline,
              colors.textMuted,
            ),
          };

    return AnimatedOpacity(
      opacity: shown || current ? 1 : 0.35,
      duration: AppMotion.of(context).base,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 20,
              child: current
                  ? const AppProgress.circular(size: AppProgressSize.sm)
                  : Icon(icon, size: 20, color: tone),
            ),
            12.widthBox,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      step.code,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: context.textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    step.note,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Outcomeline extends StatelessWidget {
  const _Outcomeline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.arrow_forward, size: 18, color: context.colors.textSecondary),
      8.widthBox,
      Expanded(child: Text(text, style: context.textTheme.bodyMedium)),
    ],
  );
}
