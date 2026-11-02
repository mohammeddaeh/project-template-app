import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/session_guard/presentation/widgets/pin_pad.dart';
import 'package:app_template/modules/session_guard/session_guard_config.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/session_guard/` played on the device: create a PIN, confirm it,
/// then lock and unlock with the real [PinPad] — the PIN is kept in this page,
/// where the module keeps a salted hash in secure storage.
class SessionGuardSimDemo extends StatefulWidget {
  const SessionGuardSimDemo({super.key});

  @override
  State<SessionGuardSimDemo> createState() => _SessionGuardSimDemoState();
}

enum _Step { setup, confirm, unlocked, locked }

class _SessionGuardSimDemoState extends State<SessionGuardSimDemo> {
  /// The module's own length — both of its screens use four digits.
  static const _pinLength = 4;

  _Step _step = _Step.setup;
  String _pin = '';
  String _first = '';
  String _entered = '';
  int _wrong = 0;
  String? _error;

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() => _entered += digit);
    if (_entered.length == _pinLength) _complete();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _complete() {
    final value = _entered;
    setState(() {
      _entered = '';
      _error = null;
      switch (_step) {
        case _Step.setup:
          _first = value;
          _step = _Step.confirm;
        case _Step.confirm:
          if (value == _first) {
            _pin = value;
            _step = _Step.unlocked;
          } else {
            _error = LocaleKeys.sessionGuardPinMismatch.tr();
            _step = _Step.setup;
          }
        case _Step.locked:
          if (value == _pin) {
            _wrong = 0;
            _step = _Step.unlocked;
          } else if (++_wrong >= SessionGuardConfig.maxWrongAttempts) {
            // The module signs out here — a real sign-out, not another lock.
            _pin = _first = '';
            _wrong = 0;
            _step = _Step.setup;
            _error = LocaleKeys.showcaseGuardSignedOut.tr();
          } else {
            _error = LocaleKeys.sessionGuardWrongPin.tr();
          }
        case _Step.unlocked:
          break;
      }
    });
  }

  void _reset() => setState(() {
    _step = _Step.setup;
    _pin = _first = _entered = '';
    _wrong = 0;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final s = context.screen;
    final motion = AppMotion.of(context);

    final (title, subtitle) = switch (_step) {
      _Step.setup => (
        LocaleKeys.sessionGuardSetupPinTitle.tr(),
        LocaleKeys.sessionGuardSetupPinSubtitle.tr(),
      ),
      _Step.confirm => (LocaleKeys.sessionGuardConfirmPinTitle.tr(), ''),
      _Step.locked => (
        LocaleKeys.sessionGuardLockedTitle.tr(),
        LocaleKeys.sessionGuardEnterPin.tr(),
      ),
      _Step.unlocked => (LocaleKeys.showcaseGuardUnlocked.tr(), ''),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code: switch (_step) {
            _Step.setup || _Step.confirm => 'SessionPinSetupScreen → PinPad',
            _Step.locked => 'SessionLockScreen → PinPad',
            _Step.unlocked => 'SessionGuardGate(child: MainShellPage)',
          },
          child: AnimatedSwitcher(
            duration: motion.base,
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: Column(
                children: [
                  Icon(
                    _step == _Step.unlocked
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline,
                    size: s.size(40),
                    color: colors.primary,
                  ),
                  SizedBox(height: s.space(12)),
                  Text(
                    title,
                    style: context.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle.isNotEmpty || _error != null) ...[
                    SizedBox(height: s.space(6)),
                    Text(
                      _error ?? subtitle,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: _error != null ? colors.error : colors.textMuted,
                      ),
                    ),
                  ],
                  SizedBox(height: s.space(20)),
                  if (_step == _Step.unlocked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          LocaleKeys.showcaseGuardLockHint.tr(
                            args: ['${SessionGuardConfig.lockAfter.inMinutes}'],
                          ),
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        12.heightBox,
                        AppButton(
                          text: LocaleKeys.showcaseGuardLockNow.tr(),
                          leadingIcon: Icons.lock_outline,
                          onTap: () => setState(() => _step = _Step.locked),
                        ),
                      ],
                    )
                  else
                    PinPad(
                      enteredLength: _entered.length,
                      pinLength: _pinLength,
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                    ),
                  if (_step == _Step.locked && _wrong > 0) ...[
                    SizedBox(height: s.space(12)),
                    StatusChip(
                      labelText: LocaleKeys.showcaseGuardAttempts.tr(
                        args: [
                          '$_wrong',
                          '${SessionGuardConfig.maxWrongAttempts}',
                        ],
                      ),
                      tone: StatusTone.warning,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        DemoBlock(
          code:
              'PinPad(enteredLength:, pinLength:, onDigit:, onBackspace:) · '
              'SessionGuardConfig.lockAfter · .maxWrongAttempts',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseGuardRealNote.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              8.heightBox,
              AppButton(
                text: LocaleKeys.showcaseReplay.tr(),
                variant: AppButtonVariant.text,
                onTap: _reset,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
