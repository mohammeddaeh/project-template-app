import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Every kind of [Failure], through [FailureUiMapper], into what the screen
/// draws — the same path a real cubit's failure takes.
class FailuresDemo extends StatefulWidget {
  const FailuresDemo({super.key});

  @override
  State<FailuresDemo> createState() => _FailuresDemoState();
}

class _FailuresDemoState extends State<FailuresDemo> {
  int _selected = 0;

  /// One sample of each kind, named as it is written in code.
  List<(String, Failure)> _cases() => [
    ('NoInternetFailure', const NoInternetFailure()),
    ('TimeoutFailure', const TimeoutFailure()),
    ('BadCertificateFailure', const BadCertificateFailure()),
    ('CancelledFailure', const CancelledFailure()),
    ('ServerUnreachableFailure', const ServerUnreachableFailure()),
    ('UnauthorizedFailure', const UnauthorizedFailure()),
    ('ForbiddenFailure', const ForbiddenFailure()),
    ('LoginFailure', const LoginFailure()),
    ('LoginPendingApprovalFailure', const LoginPendingApprovalFailure()),
    ('LoginRejectedFailure', const LoginRejectedFailure()),
    ('LoginSuspendedFailure', const LoginSuspendedFailure()),
    ('LoginDisabledFailure', const LoginDisabledFailure()),
    ('RegisterFailure', const RegisterFailure()),
    (
      'RateLimitFailure(retryAfterSeconds: 120)',
      const RateLimitFailure(retryAfterSeconds: 120),
    ),
    (
      'ServiceUnavailableFailure(503)',
      const ServiceUnavailableFailure(statusCode: 503, retryAfterSeconds: 30),
    ),
    ('ServerFailure(500)', const ServerFailure(statusCode: 500)),
    ('BusinessFailure(404)', const BusinessFailure(statusCode: 404)),
    (
      'ValidationFailure(fields: …)',
      ValidationFailure(
        fields: {'email': LocaleKeys.showcaseFailuresEmailInvalid.tr()},
      ),
    ),
    ('ParseFailure', const ParseFailure(kind: ParseErrorKind.malformedJson)),
    ('CacheFailure', const CacheFailure()),
    ('StorageFailure', const StorageFailure(operation: StorageOperation.write)),
    (
      'PermissionFailure(denied)',
      const PermissionFailure(
        permission: 'camera',
        reason: PermissionDeniedReason.denied,
      ),
    ),
    (
      'PermissionFailure(permanentlyDenied)',
      const PermissionFailure(
        permission: 'camera',
        reason: PermissionDeniedReason.permanentlyDenied,
      ),
    ),
    ('ConflictFailure', const ConflictFailure()),
    ('DeviceNotFoundFailure', const DeviceNotFoundFailure()),
    ('NotPrimaryDeviceFailure', const NotPrimaryDeviceFailure()),
    ('UnknownFailure', const UnknownFailure()),
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    final cases = _cases();
    final (name, failure) = cases[_selected];
    final action = FailureUiMapper.toAction(failure);
    final canRetry = action is ShowError && action.canRetry;
    final onRetry = canRetry
        ? () => context.feedback.toast(LocaleKeys.showcaseFailuresRetried.tr())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'FailureUiMapper.toAction(failure) → UiAction',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: ChipRow<int>(
                  items: [for (var i = 0; i < cases.length; i++) i],
                  labelResolver: (i) => cases[i].$1,
                  selectedValue: _selected,
                  scrollable: false,
                  onSelected: (i) => setState(() => _selected = i ?? _selected),
                ),
              ),
              12.heightBox,
              KeyValueRow(
                labelKey: LocaleKeys.showcaseFailuresAction,
                ltr: true,
                value: switch (action) {
                  ShowError() => 'ShowError',
                  NavigateToLogin() => 'NavigateToLogin',
                  Silent() => 'Silent',
                },
              ),
              if (action case ShowError(:final message))
                KeyValueRow(
                  labelKey: LocaleKeys.showcaseFailuresMessage,
                  value: message,
                ),
              KeyValueRow(
                labelKey: LocaleKeys.showcaseFailuresCanRetry,
                ltr: true,
                value: '$canRetry',
              ),
              KeyValueRow(
                labelKey: LocaleKeys.showcaseFailuresOffline,
                ltr: true,
                value: '${FailureStateView.isOffline(failure)}',
                showDivider: false,
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'FailureStateView(failure: $name, onRetry: …)',
          child: action is ShowError
              ? FailureStateView(failure: failure, onRetry: onRetry)
              : _NothingDrawn(),
        ),
        DemoBlock(
          code: 'FailureStateView.compact(failure: …, onRetry: …)',
          child: action is ShowError
              ? FailureStateView.compact(failure: failure, onRetry: onRetry)
              : _NothingDrawn(),
        ),
      ],
    );
  }
}

/// Session expiry navigates on its own and a cancel is deliberate — the view
/// draws nothing for either, and says so here rather than leaving a gap.
class _NothingDrawn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.showcaseFailuresNothingDrawn.tr(),
    style: context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    ),
  );
}
