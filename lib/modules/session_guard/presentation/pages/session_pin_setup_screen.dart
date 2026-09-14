import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/modules/session_guard/presentation/cubits/session_guard_cubit.dart';
import 'package:app_template/modules/session_guard/presentation/widgets/pin_pad.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

const _pinLength = 4;

/// إعداد رقم القفل أوّل مرّة — خطوتان بشاشةٍ واحدة: اكتب الرقم ثم أكِّده.
/// `SessionGuardGate` يعرضها بدل جسد التطبيق طالما [SessionGuardNeedsSetup]
/// قائمة.
class SessionPinSetupScreen extends StatefulWidget {
  const SessionPinSetupScreen({super.key});

  @override
  State<SessionPinSetupScreen> createState() => _SessionPinSetupScreenState();
}

class _SessionPinSetupScreenState extends State<SessionPinSetupScreen> {
  String _first = '';
  String _entered = '';
  bool _confirming = false;

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() => _entered += digit);
    if (_entered.length == _pinLength) _onComplete();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _onComplete() {
    if (!_confirming) {
      setState(() {
        _first = _entered;
        _entered = '';
        _confirming = true;
      });
      return;
    }

    if (_entered != _first) {
      context.feedback.error(LocaleKeys.sessionGuardPinMismatch.tr());
      setState(() {
        _first = '';
        _entered = '';
        _confirming = false;
      });
      return;
    }

    context.read<SessionGuardCubit>().setPin(_entered);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pin_outlined, size: 48, color: context.colors.primary),
              const SizedBox(height: 16),
              Text(
                (_confirming
                        ? LocaleKeys.sessionGuardConfirmPinTitle
                        : LocaleKeys.sessionGuardSetupPinTitle)
                    .tr(),
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.sessionGuardSetupPinSubtitle.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              PinPad(
                enteredLength: _entered.length,
                pinLength: _pinLength,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
