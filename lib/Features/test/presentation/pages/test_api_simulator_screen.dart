import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

enum _StepStatus { idle, running, success, error }

enum _InjectFailure { none, noInternet, timeout, server500, parseError }

class _PipelineStep {
  _PipelineStep({
    required this.layer,
    required this.detail,
    required this.successCode,
    required this.errorCode,
  }) : status = _StepStatus.idle;

  final String layer;
  final String detail;
  final String successCode;
  final String errorCode;
  _StepStatus status;
  int? elapsedMs;
}

List<_PipelineStep> _buildSteps() => [
      _PipelineStep(
        layer: 'UseCase.call(params)',
        detail: 'Validates params, delegates to Repository',
        successCode: 'await _repo.getItems(page: 1)',
        errorCode: 'Left(ValidationFailure(...))',
      ),
      _PipelineStep(
        layer: 'ConnectivityService.isOnline()',
        detail: 'Checks for active network interface',
        successCode: 'online — proceeding',
        errorCode: 'return Left(NoInternetFailure())',
      ),
      _PipelineStep(
        layer: 'RemoteDataSource → Retrofit',
        detail: 'HTTP GET /api/v1/items?page=1',
        successCode: '200 OK — data received',
        errorCode: 'DioException thrown',
      ),
      _PipelineStep(
        layer: 'FailureMapper / Model.fromJson()',
        detail: 'Maps exception to Failure OR parses JSON',
        successCode: 'ItemModel.fromJson(json)',
        errorCode: 'Failure produced from exception',
      ),
      _PipelineStep(
        layer: 'BaseRepository.handle()',
        detail: 'Returns Either<Failure, Entity>',
        successCode: "Right(Item(id: '42', name: 'Widget'))",
        errorCode: 'Left(Failure) propagated to UseCase',
      ),
      _PipelineStep(
        layer: 'Cubit emits state',
        detail: 'fold() branches on Left/Right',
        successCode: 'emit(ItemsState.loaded(items: [...]))',
        errorCode: "emit(ItemsState.error(message: '...'))",
      ),
    ];

const _mockJson = '{\n'
    '  "id": "a4f8c",\n'
    '  "name": "Widget Pro",\n'
    '  "price": 29.99,\n'
    '  "category": "tools"\n'
    '}';

// ─── Screen ──────────────────────────────────────────────────────────────────

@RoutePage()
class TestApiSimulatorScreen extends StatefulWidget {
  const TestApiSimulatorScreen({super.key});

  @override
  State<TestApiSimulatorScreen> createState() => _TestApiSimulatorScreenState();
}

class _TestApiSimulatorScreenState extends State<TestApiSimulatorScreen> {
  List<_PipelineStep> _steps = _buildSteps();
  _InjectFailure _inject = _InjectFailure.none;
  double _networkDelay = 800;
  bool _isRunning = false;
  bool _succeeded = false;
  Failure? _failure;
  int _totalMs = 0;

  // At which step index each injected failure interrupts the pipeline.
  int get _failStepIndex => switch (_inject) {
        _InjectFailure.none => -1,
        _InjectFailure.noInternet => 1,
        _InjectFailure.timeout => 2,
        _InjectFailure.server500 => 3,
        _InjectFailure.parseError => 3,
      };

  Failure? get _injectedFailure => switch (_inject) {
        _InjectFailure.none => null,
        _InjectFailure.noInternet => const NoInternetFailure(),
        _InjectFailure.timeout => const TimeoutFailure(),
        _InjectFailure.server500 => const ServerFailure(statusCode: 500),
        _InjectFailure.parseError =>
          const ParseFailure(kind: ParseErrorKind.malformedJson),
      };

  Future<void> _send() async {
    if (_isRunning) return;
    setState(() {
      _steps = _buildSteps();
      _isRunning = true;
      _succeeded = false;
      _failure = null;
      _totalMs = 0;
    });

    final sw = Stopwatch()..start();

    for (var i = 0; i < _steps.length; i++) {
      setState(() => _steps[i].status = _StepStatus.running);
      final stepSw = Stopwatch()..start();

      final delay = i == 2 ? _networkDelay.round() : 60;
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;

      if (i == _failStepIndex) {
        setState(() {
          _steps[i]
            ..status = _StepStatus.error
            ..elapsedMs = stepSw.elapsedMilliseconds;
          _failure = _injectedFailure;
          _totalMs = sw.elapsedMilliseconds;
          _isRunning = false;
        });
        return;
      }

      setState(() {
        _steps[i]
          ..status = _StepStatus.success
          ..elapsedMs = stepSw.elapsedMilliseconds;
      });
    }

    setState(() {
      _succeeded = true;
      _totalMs = sw.elapsedMilliseconds;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testApiSimulatorTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Config ────────────────────────────────────────────────────────
          SectionTitle(titleKey: LocaleKeys.requestConfig),
          _ConfigCard(
            networkDelay: _networkDelay,
            inject: _inject,
            isRunning: _isRunning,
            onDelayChanged: (v) => setState(() => _networkDelay = v),
            onInjectChanged: (v) => setState(() => _inject = v),
            onSend: _send,
          ),
          const SizedBox(height: 20),

          // ── Pipeline ──────────────────────────────────────────────────────
          SectionTitle(
            titleKey: LocaleKeys.pipelineTitle,
            trailing: _totalMs > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_totalMs}ms',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
          for (var i = 0; i < _steps.length; i++) ...[
            _StepCard(step: _steps[i], index: i),
            if (i < _steps.length - 1)
              Align(
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: context.colorScheme.outlineVariant,
                ),
              ),
          ],
          const SizedBox(height: 20),

          // ── Result ────────────────────────────────────────────────────────
          SectionTitle(titleKey: LocaleKeys.simulatedResult),
          _ResultCard(
            succeeded: _succeeded,
            failure: _failure,
            totalMs: _totalMs,
          ),
        ],
      ),
    );
  }
}

// ─── Config Card ──────────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.networkDelay,
    required this.inject,
    required this.isRunning,
    required this.onDelayChanged,
    required this.onInjectChanged,
    required this.onSend,
  });

  final double networkDelay;
  final _InjectFailure inject;
  final bool isRunning;
  final ValueChanged<double> onDelayChanged;
  final ValueChanged<_InjectFailure> onInjectChanged;
  final VoidCallback onSend;

  String _injectLabel(BuildContext context, _InjectFailure f) => switch (f) {
        _InjectFailure.none => LocaleKeys.injectNone.tr(),
        _InjectFailure.noInternet => 'NoInternetFailure',
        _InjectFailure.timeout => 'TimeoutFailure',
        _InjectFailure.server500 => 'ServerFailure(500)',
        _InjectFailure.parseError => 'ParseFailure',
      };

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.networkDelay.tr(),
                  style: context.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${networkDelay.round()}ms',
                style: context.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: context.colorScheme.outline,
                ),
              ),
            ],
          ),
          Slider(
            value: networkDelay,
            min: 100,
            max: 3000,
            divisions: 29,
            onChanged: isRunning ? null : onDelayChanged,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.injectFailure.tr(),
                  style: context.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownButton<_InjectFailure>(
                value: inject,
                onChanged: isRunning
                    ? null
                    : (v) {
                        if (v != null) onInjectChanged(v);
                      },
                items: [
                  for (final f in _InjectFailure.values)
                    DropdownMenuItem(
                      value: f,
                      child: Text(
                        _injectLabel(context, f),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontFamily:
                              f == _InjectFailure.none ? null : 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isRunning ? null : onSend,
              icon: isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(LocaleKeys.sendRequest.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index});

  final _PipelineStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (bg, border) = switch (step.status) {
      _StepStatus.idle => (scheme.surfaceContainerHighest, Colors.transparent),
      _StepStatus.running => (scheme.primaryContainer, scheme.primary),
      _StepStatus.success => (
          Colors.green.withValues(alpha: 0.10),
          Colors.green.shade600,
        ),
      _StepStatus.error => (scheme.errorContainer, scheme.error),
    };

    final code = step.status == _StepStatus.error
        ? step.errorCode
        : step.successCode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: border,
          width: step.status == _StepStatus.idle ? 0 : 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusIndicator(status: step.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.layer,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (step.elapsedMs != null)
                      Text(
                        '+${step.elapsedMs}ms',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (step.status == _StepStatus.success ||
                    step.status == _StepStatus.error) ...[
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: step.status == _StepStatus.error
                          ? scheme.error
                          : Colors.green.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SizedBox(
      width: 22,
      height: 22,
      child: switch (status) {
        _StepStatus.idle => Icon(
            Icons.circle_outlined,
            size: 18,
            color: scheme.outlineVariant,
          ),
        _StepStatus.running => const Padding(
            padding: EdgeInsets.all(2),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        _StepStatus.success => Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Colors.green.shade600,
          ),
        _StepStatus.error => Icon(
            Icons.error_rounded,
            size: 20,
            color: scheme.error,
          ),
      },
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.succeeded,
    required this.failure,
    required this.totalMs,
  });

  final bool succeeded;
  final Failure? failure;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    final scheme = context.colorScheme;

    if (!succeeded && failure == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          LocaleKeys.pressSendHint.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (succeeded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade600.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${LocaleKeys.requestSuccess.tr()} — ${totalMs}ms',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _mockJson,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFD4D4D4),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Failure result — run the REAL FailureUiMapper on the injected failure.
    final action = FailureUiMapper.toAction(failure!);
    final actionText = switch (action) {
      ShowError(:final message, :final canRetry) =>
        "ShowError(message: '$message', canRetry: $canRetry)",
      NavigateToLogin() => 'NavigateToLogin()',
      Silent() => 'Silent()',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${LocaleKeys.requestFailed.tr()} — ${totalMs}ms',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onErrorContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            failure.runtimeType.toString(),
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: scheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '→ $actionText',
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: scheme.onErrorContainer,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
