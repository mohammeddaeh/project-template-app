import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/modules/session_guard/presentation/cubits/session_guard_cubit.dart';
import 'package:app_template/modules/session_guard/presentation/widgets/pin_pad.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

const _pinLength = 4;

/// شاشة القفل — تُعرض بدل جسد التطبيق كاملاً، لا فوقه، طالما الحالة
/// [SessionGuardLocked]. راجع `SessionGuardGate`.
class SessionLockScreen extends StatefulWidget {
  const SessionLockScreen({super.key});

  @override
  State<SessionLockScreen> createState() => _SessionLockScreenState();
}

class _SessionLockScreenState extends State<SessionLockScreen> {
  String _entered = '';

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SessionGuardCubit>();
    if (cubit.canUseBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
    }
  }

  Future<void> _tryBiometrics() async {
    if (!mounted) return;
    await context.read<SessionGuardCubit>().unlockWithBiometrics(
      LocaleKeys.sessionGuardBiometricReason.tr(),
    );
  }

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() => _entered += digit);
    if (_entered.length == _pinLength) _submit();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _submit() {
    context.read<SessionGuardCubit>().verifyPin(_entered);
    setState(() => _entered = '');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionGuardCubit, SessionGuardState>(
      listener: (context, state) {
        // ignore: unnecessary_statements — EasyLocalization dependency
        context.locale;
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<SessionGuardCubit, SessionGuardState>(
            builder: (context, state) {
              final wrongAttempt =
                  state is SessionGuardLocked && state.wrongAttempt;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.sessionGuardLockedTitle.tr(),
                      style: context.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (wrongAttempt
                              ? LocaleKeys.sessionGuardWrongPin
                              : LocaleKeys.sessionGuardEnterPin)
                          .tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: wrongAttempt
                            ? context.colors.error
                            : context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),
                    PinPad(
                      enteredLength: _entered.length,
                      pinLength: _pinLength,
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                    ),
                    if (context.read<SessionGuardCubit>().canUseBiometrics) ...[
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _tryBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(LocaleKeys.sessionGuardUseBiometrics.tr()),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
