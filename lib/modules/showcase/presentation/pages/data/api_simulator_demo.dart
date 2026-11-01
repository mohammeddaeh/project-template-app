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
/// the stages are drawn, and the failure at the end is a real [Failure] put
/// through the real [FailureUiMapper].
class ApiSimulatorDemo extends StatefulWidget {
  const ApiSimulatorDemo({super.key});

  @override
  State<ApiSimulatorDemo> createState() => _ApiSimulatorDemoState();
}

enum _Outcome {
  ok('200'),
  unauthorized('401'),
  forbidden('403'),
  notFound('404'),
  validation('422'),
  server('500'),
  timeout('timeout'),
  offline('offline');

  const _Outcome(this.label);

  final String label;
}

enum _StepState { passed, stopped, skipped }

class _Step {
  const _Step(this.code, this.noteKey, [this.state = _StepState.passed]);

  final String code;
  final String noteKey;
  final _StepState state;
}

class _ApiSimulatorDemoState extends State<ApiSimulatorDemo> {
  _Outcome _outcome = _Outcome.ok;
  int _revealed = -1;
  int _runId = 0;

  /// What the server's answer becomes — built here because two of the
  /// messages are translated sample text from the server.
  Failure? _failure() => switch (_outcome) {
    _Outcome.ok => null,
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
    _Outcome.timeout => const TimeoutFailure(),
    _Outcome.offline => const NoInternetFailure(),
  };

  String _failureName(Failure f) => switch (f) {
    UnauthorizedFailure() => 'UnauthorizedFailure',
    ForbiddenFailure() => 'ForbiddenFailure',
    BusinessFailure(:final statusCode) => 'BusinessFailure($statusCode)',
    ServerFailure(:final statusCode) => 'ServerFailure($statusCode)',
    TimeoutFailure() => 'TimeoutFailure',
    NoInternetFailure() => 'NoInternetFailure',
    _ => 'Failure',
  };

  List<_Step> _steps(Failure? failure) {
    final offline = _outcome == _Outcome.offline;
    final skip = offline ? _StepState.skipped : _StepState.passed;
    final (serverCode, serverKey) = switch (_outcome) {
      _Outcome.ok => ('HTTP 200', LocaleKeys.showcaseApiServer200),
      _Outcome.unauthorized => ('HTTP 401', LocaleKeys.showcaseApiServer401),
      _Outcome.forbidden => ('HTTP 403', LocaleKeys.showcaseApiServer403),
      _Outcome.notFound => ('HTTP 404', LocaleKeys.showcaseApiServer404),
      _Outcome.validation => ('HTTP 422', LocaleKeys.showcaseApiServer422),
      _Outcome.server => ('HTTP 500', LocaleKeys.showcaseApiServer500),
      _Outcome.timeout => ('…', LocaleKeys.showcaseApiServerTimeout),
      _Outcome.offline => ('Server', LocaleKeys.showcaseApiServerNone),
    };
    final back = switch (_outcome) {
      _Outcome.unauthorized => const _Step(
        'TokenRefreshInterceptor.onError',
        LocaleKeys.showcaseApiBackRefresh,
      ),
      _Outcome.timeout => const _Step(
        'RetryInterceptor.onError',
        LocaleKeys.showcaseApiBackRetryTimeout,
      ),
      _Outcome.server => const _Step(
        'RetryInterceptor.onError',
        LocaleKeys.showcaseApiBackRetry500,
      ),
      _Outcome.offline => const _Step(
        'RetryInterceptor.onError',
        LocaleKeys.showcaseApiBackRetryOffline,
      ),
      _ => null,
    };

    return [
      const _Step('NetworkOriginInterceptor', LocaleKeys.showcaseApiStepOrigin),
      const _Step('RequestCacheInterceptor', LocaleKeys.showcaseApiStepCache),
      offline
          ? const _Step(
              'InternetCheckerInterceptor',
              LocaleKeys.showcaseApiGuardBlocked,
              _StepState.stopped,
            )
          : const _Step(
              'InternetCheckerInterceptor',
              LocaleKeys.showcaseApiStepGuard,
            ),
      _Step('AuthInterceptor', LocaleKeys.showcaseApiStepAuth, skip),
      _Step('TokenRefreshInterceptor', LocaleKeys.showcaseApiStepRefresh, skip),
      _Step('RetryInterceptor', LocaleKeys.showcaseApiStepRetry, skip),
      _Step(
        serverCode,
        serverKey,
        offline
            ? _StepState.skipped
            : failure == null
            ? _StepState.passed
            : _StepState.stopped,
      ),
      ?back,
      if (failure == null) ...[
        const _Step('HandleBodyResponse', LocaleKeys.showcaseApiStepBody),
        const _Step(
          'BaseRepository.handle → Right(data)',
          LocaleKeys.showcaseApiStepRepository,
        ),
        const _Step('Cubit → emit(success)', LocaleKeys.showcaseApiCubit),
      ] else ...[
        _Step(
          'FailureMapperRegistry → ${_failureName(failure)}',
          LocaleKeys.showcaseApiStepMapper,
        ),
        const _Step(
          'BaseRepository.handle → Left(failure)',
          LocaleKeys.showcaseApiStepRepository,
        ),
        _Step(
          'FailureUiMapper.toAction → ${switch (FailureUiMapper.toAction(failure)) {
            ShowError(:final canRetry) => 'ShowError(canRetry: $canRetry)',
            NavigateToLogin() => 'NavigateToLogin',
            Silent() => 'Silent',
          }}',
          LocaleKeys.showcaseApiStepUiMapper,
        ),
      ],
    ];
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

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    final failure = _failure();
    final steps = _steps(failure);
    final done = _revealed >= steps.length;
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
          code:
              'Dio → interceptors → FailureMapperRegistry → '
              'BaseRepository.handle → FailureUiMapper',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<_Outcome>(
                items: _Outcome.values,
                labelResolver: (o) => o.label,
                selectedValue: _outcome,
                scrollable: false,
                onSelected: (o) => setState(() {
                  _outcome = o ?? _outcome;
                  _runId++;
                  _revealed = -1;
                }),
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
                if (action == null)
                  _Outcomeline(LocaleKeys.showcaseApiCubit.tr())
                else if (action is NavigateToLogin)
                  _Outcomeline(LocaleKeys.showcaseApiUiLogin.tr())
                else ...[
                  _Outcomeline(LocaleKeys.showcaseApiUiError.tr()),
                  FailureStateView.compact(
                    failure: failure!,
                    onRetry: action is ShowError && action.canRetry
                        ? () => _send(steps.length)
                        : null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
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
                    step.noteKey.tr(),
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
