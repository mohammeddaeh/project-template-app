import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

// ─── Flow step model ─────────────────────────────────────────────────────────

class _FlowStep {
  const _FlowStep(
    this.icon,
    this.layer,
    this.operation,
    this.code, {
    this.isSpecial = false,
  });

  final IconData icon;
  final String layer;
  final String operation;
  final String code;

  /// Highlighted differently — side-effects outside the main chain
  /// (AuthInterceptor, SyncConflictResolver).
  final bool isSpecial;
}

// Shorthand constructors for the layers that repeat across flows.
_FlowStep _server(String op, String code) =>
    _FlowStep(Icons.cloud_outlined, 'Server', op, code);
_FlowStep _dio(String op, String code) =>
    _FlowStep(Icons.swap_calls_rounded, 'Dio Client', op, code);
_FlowStep _registry(String op, String code) =>
    _FlowStep(Icons.swap_horiz_rounded, 'FailureMapperRegistry', op, code);
_FlowStep _repo(String op, String code) =>
    _FlowStep(Icons.storage_outlined, 'BaseRepository.handle()', op, code);
_FlowStep _uiMapper(String op, String code) =>
    _FlowStep(Icons.account_tree_outlined, 'FailureUiMapper', op, code);
_FlowStep _ui(String op, String code) =>
    _FlowStep(Icons.notifications_active_outlined, 'UI Layer', op, code);

// ─── Failure cases with their flows ──────────────────────────────────────────

class _FailureCase {
  const _FailureCase({
    required this.label,
    required this.failure,
    required this.steps,
  });

  final String label;
  final Failure failure;
  final List<_FlowStep> steps;
}

class _CaseGroup {
  const _CaseGroup({
    required this.icon,
    required this.title,
    required this.cases,
  });

  final IconData icon;
  final String title;
  final List<_FailureCase> cases;
}

final List<_CaseGroup> _groups = [
  _CaseGroup(
    icon: Icons.signal_wifi_off_outlined,
    title: 'Transport',
    cases: [
      _FailureCase(
        label: 'NoInternet',
        failure: const NoInternetFailure(),
        steps: [
          _FlowStep(Icons.wifi_off_rounded, 'Network Layer',
              'No active interface detected', 'ConnectivityResult.none'),
          _FlowStep(Icons.block_rounded, 'ConnectivityService',
              'isOffline() → true', 'return Left(NoInternetFailure())'),
          _uiMapper('NoInternetFailure → ShowError', 'canRetry: true'),
          _ui('context.feedback.error(msg)', 'feedback banner displayed'),
        ],
      ),
      _FailureCase(
        label: 'Timeout',
        failure: const TimeoutFailure(),
        steps: [
          _dio('DioException(connectionTimeout)', 'after 30s no response'),
          _registry('map() → TimeoutFailure()',
              'switch(e.type) → connectionTimeout'),
          _repo('catch → Left(TimeoutFailure())', 'return Left(failure)'),
          _uiMapper('TimeoutFailure → ShowError',
              'sessionTimedOut, canRetry: true'),
          _ui('context.feedback.error(msg)', 'feedback banner displayed'),
        ],
      ),
      _FailureCase(
        label: 'BadCertificate',
        failure: const BadCertificateFailure(),
        steps: [
          _dio('DioException(badCertificate)', 'SSL/TLS validation failed'),
          _registry('→ BadCertificateFailure()', 'certificate rejected'),
          _uiMapper('→ ShowError', 'same message as NoInternet'),
          _ui('context.feedback.error(msg)', 'feedback displayed'),
        ],
      ),
      _FailureCase(
        label: 'Cancelled',
        failure: const CancelledFailure(),
        steps: [
          _dio('CancelToken.cancel() called', 'DioException(type: cancel)'),
          _registry('→ CancelledFailure()', 'intentional cancel'),
          _uiMapper('CancelledFailure → Silent()', 'swallowed — no UI action'),
          _FlowStep(Icons.volume_off_outlined, 'UI Layer',
              'nothing happens — Silent()', '// no toast, no state'),
        ],
      ),
    ],
  ),
  _CaseGroup(
    icon: Icons.lock_outline,
    title: 'Auth',
    cases: [
      _FailureCase(
        label: 'Login 401',
        failure: const LoginFailure(serverMessage: 'Wrong credentials'),
        steps: [
          _server('HTTP 401 on /auth/login', 'wrong credentials'),
          _registry('→ LoginFailure(serverMessage)',
              'distinct from UnauthorizedFailure'),
          _repo('Left(LoginFailure(...))', 'auth error, not session expiry'),
          _uiMapper('→ ShowError(serverMessage)',
              'shows server message or fallback'),
          _ui('context.feedback.error(msg)', 'login form shows error'),
        ],
      ),
      _FailureCase(
        label: 'Register 400',
        failure: const RegisterFailure(serverMessage: 'Email taken'),
        steps: [
          _server('HTTP 400/422 on /auth/register', 'duplicate email'),
          _registry('→ RegisterFailure(serverMessage)', 'register endpoint'),
          _uiMapper('→ ShowError(serverMessage)', 'fallback: somethingWrong'),
          _ui('context.feedback.error(msg)', 'register form shows error'),
        ],
      ),
      _FailureCase(
        label: 'Session Expired',
        failure: const UnauthorizedFailure(),
        steps: [
          _server('HTTP 401 during active session',
              'token expired or invalid scope'),
          _FlowStep(Icons.security_rounded, 'AuthInterceptor',
              'AuthEventBus.sessionExpired fires', 'BEFORE cubit gets failure',
              isSpecial: true),
          _registry('→ UnauthorizedFailure()', 'parallel to AuthInterceptor'),
          _repo('Left(UnauthorizedFailure())', 'cubit gets failure too'),
          _uiMapper('→ NavigateToLogin()', 'NOT ShowError — deduplicated'),
          _FlowStep(Icons.login_rounded, 'AppRouter',
              'replaceAll([LoginRoute()])',
              'getIt<AppRouter>().replaceAll([...])'),
        ],
      ),
    ],
  ),
  _CaseGroup(
    icon: Icons.dns_outlined,
    title: 'Server',
    cases: [
      _FailureCase(
        label: 'RateLimit 429',
        failure: const RateLimitFailure(),
        steps: [
          _server('HTTP 429 Too Many Requests', 'rate limit exceeded'),
          _registry('→ RateLimitFailure(retryAfter)',
              'may include retryAfterSeconds'),
          _uiMapper('→ ShowError(serverMessage)', 'fallback: serverError'),
          _ui('context.feedback.error(msg)', 'user told to wait'),
        ],
      ),
      _FailureCase(
        label: 'Server 500',
        failure: const ServerFailure(statusCode: 500),
        steps: [
          _server('HTTP 500 Internal Server Error', 'statusCode: 500'),
          _registry('→ ServerFailure(statusCode: 500)', 'all 5xx responses'),
          _uiMapper('→ ShowError', 'serverMessage or generic'),
          _ui('context.feedback.error(msg)', 'generic server error shown'),
        ],
      ),
      _FailureCase(
        label: 'Business 422',
        failure: const BusinessFailure(
            statusCode: 422, serverMessage: 'Duplicate entry'),
        steps: [
          _server('HTTP 422 Unprocessable Entity', 'business validation failed'),
          _registry('→ BusinessFailure(422, msg)',
              '4xx excluding 401/408/429'),
          _uiMapper('→ ShowError(serverMessage)', 'domain-specific error'),
          _ui('context.feedback.error(msg)', "e.g. 'Duplicate entry'"),
        ],
      ),
    ],
  ),
  _CaseGroup(
    icon: Icons.code_outlined,
    title: 'Parse',
    cases: [
      _FailureCase(
        label: 'MalformedJSON',
        failure: const ParseFailure(kind: ParseErrorKind.malformedJson),
        steps: [
          _server('HTTP 200 OK — but body malformed',
              'valid status, invalid body'),
          _FlowStep(Icons.code_rounded, 'Model.fromJson()',
              'throws FormatException', 'body is HTML, not JSON'),
          _registry('→ ParseFailure(malformedJson)',
              'kind + fieldName for logging only'),
          _uiMapper('→ ShowError(parseDataError)',
              'all ParseErrorKind → same message'),
          _ui('context.feedback.error(msg)', "user sees generic 'data error'"),
        ],
      ),
      _FailureCase(
        label: 'TypeMismatch',
        failure: const ParseFailure(
            kind: ParseErrorKind.typeMismatch, fieldName: 'price'),
        steps: [
          _server('HTTP 200 OK — wrong field type', 'valid status'),
          _FlowStep(Icons.code_rounded, 'Model.fromJson()',
              'throws TypeError', "json['price'] is String, not double"),
          _registry("→ ParseFailure(typeMismatch, 'price')",
              'fieldName preserved for logs'),
          _uiMapper('→ ShowError(parseDataError)', 'same user-facing message'),
          _ui('context.feedback.error(msg)', 'generic data error shown'),
        ],
      ),
    ],
  ),
  _CaseGroup(
    icon: Icons.storage_outlined,
    title: 'Local',
    cases: [
      _FailureCase(
        label: 'Validation',
        failure: const ValidationFailure(message: 'Email is invalid'),
        steps: [
          _FlowStep(Icons.edit_outlined, 'UseCase / local logic',
              'validation runs on params', 'no network call made'),
          _FlowStep(Icons.block_rounded, 'UseCase returns',
              'Left(ValidationFailure(msg))', 'skips repository entirely'),
          _uiMapper('→ ShowError(field message)',
              'fields.values.first or message'),
          _ui('context.feedback.error(msg)', 'inline field error or banner'),
        ],
      ),
      _FailureCase(
        label: 'Cache',
        failure: const CacheFailure(),
        steps: [
          _FlowStep(Icons.storage_outlined, 'Repository / DataSource',
              'local cache read/write fails', 'HTTP-cache error'),
          _FlowStep(Icons.block_rounded, 'Repository',
              'Left(CacheFailure(message))', 'manual construction'),
          _uiMapper('→ ShowError(cacheError)', 'generic cache key'),
          _ui('context.feedback.error(msg)', 'cache error shown'),
        ],
      ),
      _FailureCase(
        label: 'Storage.read',
        failure: const StorageFailure(
            operation: StorageOperation.read, key: 'auth_token'),
        steps: [
          _FlowStep(Icons.sd_storage_outlined, 'StorageService',
              'SharedPreferences read throws', "key: 'auth_token'"),
          _FlowStep(Icons.block_rounded, 'Service returns',
              'Left(StorageFailure(read, key))',
              'operation + key for logs only'),
          _uiMapper('→ ShowError(cacheError)', 'user sees generic message'),
          _ui('context.feedback.error(msg)', 'storage error shown'),
        ],
      ),
    ],
  ),
  _CaseGroup(
    icon: Icons.sync_problem_outlined,
    title: 'Sync & Multi-Device',
    cases: [
      _FailureCase(
        label: 'Conflict',
        failure: const ConflictFailure(),
        steps: [
          _server('HTTP 409 Conflict', 'sync version mismatch'),
          _registry('→ ConflictFailure(conflictFields)',
              'fields that diverged'),
          _uiMapper('→ Silent()', 'NOT shown to user'),
          _FlowStep(Icons.merge_rounded, 'SyncConflictResolver',
              'resolves: server/client/merge', 'strategy from SyncConfig',
              isSpecial: true),
          _FlowStep(Icons.check_circle_outline_rounded, 'Result',
              'conflict resolved silently', 'user never sees this'),
        ],
      ),
      _FailureCase(
        label: 'DeviceNotFound',
        failure: const DeviceNotFoundFailure(),
        steps: [
          _server('HTTP 404 on device revoke', 'device already removed'),
          _registry('→ DeviceNotFoundFailure()', 'multi-device module'),
          _uiMapper('→ ShowError(deviceNotFound)', 'specific message key'),
          _ui('context.feedback.error(msg)', 'device list refreshed'),
        ],
      ),
      _FailureCase(
        label: 'NotPrimary',
        failure: const NotPrimaryDeviceFailure(),
        steps: [
          _server('HTTP 403 on device revoke', 'not the primary device'),
          _registry('→ NotPrimaryDeviceFailure()', 'permission-style failure'),
          _uiMapper('→ ShowError(notPrimaryDevice)', 'specific message key'),
          _ui('context.feedback.error(msg)', 'action blocked with reason'),
        ],
      ),
    ],
  ),
  _CaseGroup(
    icon: Icons.help_outline,
    title: 'Unknown',
    cases: [
      _FailureCase(
        label: 'Unknown',
        failure: const UnknownFailure(message: 'Unexpected state'),
        steps: [
          _FlowStep(Icons.bug_report_outlined, 'Anywhere',
              'unexpected exception caught', 'try/catch in handle()'),
          _registry('→ UnknownFailure(message)', 'catch-all handler'),
          _uiMapper('→ ShowError(unknownError)', 'canRetry: true'),
          _ui('context.feedback.error(msg)', 'generic error shown'),
        ],
      ),
    ],
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

@RoutePage()
class TestFailureDemoScreen extends StatefulWidget {
  const TestFailureDemoScreen({super.key});

  @override
  State<TestFailureDemoScreen> createState() => _TestFailureDemoScreenState();
}

class _TestFailureDemoScreenState extends State<TestFailureDemoScreen> {
  _FailureCase? _selected;
  UiAction? _lastAction;
  int _visibleSteps = 0;
  Timer? _animTimer;

  bool get _flowDone =>
      _selected != null && _visibleSteps >= _selected!.steps.length;

  void _select(_FailureCase c) {
    _animTimer?.cancel();
    final action = FailureUiMapper.toAction(c.failure);
    setState(() {
      _selected = c;
      _lastAction = action;
      _visibleSteps = 0;
    });
    _animTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_visibleSteps >= c.steps.length) {
        t.cancel();
        _fireFeedback(action);
        return;
      }
      setState(() => _visibleSteps++);
    });
  }

  void _fireFeedback(UiAction action) {
    if (!mounted) return;
    switch (action) {
      case ShowError(:final message):
        context.feedback.error(message);
      case NavigateToLogin():
        context.feedback.warning('Session expired → LoginRoute');
      case Silent():
        break; // faithful to the real behavior — nothing happens
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testFailureDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Failure selector ─────────────────────────────────────────────
          for (final group in _groups) _GroupSection(
            group: group,
            selected: _selected,
            onSelect: _select,
          ),
          const Divider(height: 32),

          // ── Flow visualizer ──────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 18, color: context.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.flowVisualizer.tr(),
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selected == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 32, color: context.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.tapFailureHint.tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            Text(
              _selected!.failure.runtimeType.toString(),
              style: context.textTheme.headlineSmall?.copyWith(
                fontFamily: 'monospace',
                color: context.colorScheme.error,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _visibleSteps; i++) ...[
              _StepCard(
                step: _selected!.steps[i],
                index: i,
              ),
              if (i < _selected!.steps.length - 1)
                Align(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
            ],
            if (_flowDone) ...[
              const SizedBox(height: 12),
              _ResultPanel(action: _lastAction!),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Group Section ────────────────────────────────────────────────────────────

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.selected,
    required this.onSelect,
  });

  final _CaseGroup group;
  final _FailureCase? selected;
  final ValueChanged<_FailureCase> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, size: 14, color: context.colorScheme.outline),
              const SizedBox(width: 6),
              Text(
                group.title,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in group.cases)
                _CaseChip(
                  caseData: c,
                  isSelected: identical(c, selected),
                  onTap: () => onSelect(c),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaseChip extends StatelessWidget {
  const _CaseChip({
    required this.caseData,
    required this.isSelected,
    required this.onTap,
  });

  final _FailureCase caseData;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          caseData.label,
          style: context.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

Color _layerColor(BuildContext context, _FlowStep step) {
  if (step.isSpecial) return Colors.amber.shade800;
  final scheme = context.colorScheme;
  final l = step.layer;
  if (l.contains('Server') || l.contains('Dio') || l.contains('Network')) {
    return scheme.error;
  }
  if (l.contains('Registry')) return Colors.orange.shade700;
  if (l.contains('Repository') ||
      l.contains('UseCase') ||
      l.contains('Service')) {
    return scheme.primary;
  }
  if (l.contains('FailureUiMapper')) return scheme.secondary;
  return scheme.tertiary; // UI Layer, AppRouter, Result …
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index});

  final _FlowStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _layerColor(context, step);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(24 * (1 - v), 0),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: step.isSpecial
              ? Colors.amber.withValues(alpha: 0.10)
              : context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: step.isSpecial
                ? Colors.amber.shade700
                : color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(step.icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.layer,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    step.operation,
                    style: context.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    step.code,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ─── Result Panel ─────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.action});

  final UiAction action;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    final scheme = context.colorScheme;

    final (bg, border, icon, label, detail) = switch (action) {
      ShowError(:final title, :final message, :final canRetry) => (
          scheme.errorContainer,
          scheme.error,
          Icons.error_outline_rounded,
          '${LocaleKeys.uiActionShowError.tr()}  •  $title',
          '$message\n${LocaleKeys.canRetry.tr()}: $canRetry',
        ),
      NavigateToLogin() => (
          Colors.orange.withValues(alpha: 0.12),
          Colors.orange.shade700,
          Icons.login_rounded,
          LocaleKeys.uiActionNavigateToLogin.tr(),
          '→ LoginRoute',
        ),
      Silent() => (
          scheme.surfaceContainerHighest,
          scheme.outline,
          Icons.volume_off_outlined,
          LocaleKeys.uiActionSilent.tr(),
          'Swallowed silently — no UI action',
        ),
    };

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: border),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocaleKeys.simulatedResult.tr(),
                    style: context.textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: border,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
