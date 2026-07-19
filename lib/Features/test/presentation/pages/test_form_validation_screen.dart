import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

enum _IndicatorState { idle, invalid, loading, apiError, done }

@RoutePage()
class TestFormValidationScreen extends StatefulWidget {
  const TestFormValidationScreen({super.key});

  @override
  State<TestFormValidationScreen> createState() =>
      _TestFormValidationScreenState();
}

class _TestFormValidationScreenState extends State<TestFormValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  _IndicatorState _indicator = _IndicatorState.idle;
  bool _submitted = false;
  bool _isLoading = false;
  bool _autoValidateEnabled = true;
  bool _guardEnabled = true;
  bool _simulateApiError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return LocaleKeys.fieldRequired.tr();
    if (v.trim().length < 3) return LocaleKeys.invalidInput.tr();
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return LocaleKeys.fieldRequired.tr();
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v.trim())) {
      return LocaleKeys.invalidEmail.tr();
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return LocaleKeys.fieldRequired.tr();
    if (v.length < 8) return LocaleKeys.passwordLength.tr();
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() => _indicator = _IndicatorState.invalid);
      return;
    }
    if (_guardEnabled && _isLoading) {
      context.feedback.warning(LocaleKeys.doubleSubmitBlocked.tr());
      return;
    }
    context.unfocus();
    setState(() {
      _isLoading = true;
      _indicator = _IndicatorState.loading;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (_simulateApiError) {
      setState(() {
        _isLoading = false;
        _indicator = _IndicatorState.apiError;
      });
      context.feedback.error(LocaleKeys.somethingWrong.tr());
    } else {
      setState(() {
        _isLoading = false;
        _indicator = _IndicatorState.done;
      });
      context.feedback.success(LocaleKeys.submitSuccess.tr());
    }
  }

  void _reset() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _formKey.currentState?.reset();
    setState(() {
      _submitted = false;
      _isLoading = false;
      _indicator = _IndicatorState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(LocaleKeys.testFormValidationTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(LocaleKeys.reset.tr()),
          ),
        ],
      ),
      body: Column(
        children: [
          _IndicatorBar(
            indicator: _indicator,
            submitted: _submitted,
            isLoading: _isLoading,
          ),
          Expanded(
            child: KeyboardDismissWidget(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted && _autoValidateEnabled
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _nameCtrl,
                        labelText: LocaleKeys.fullName.tr(),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _emailCtrl,
                        labelText: LocaleKeys.eMail.tr(),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _passwordCtrl,
                        labelText: LocaleKeys.password.tr(),
                        isFieldObscure: true,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: LocaleKeys.send.tr(),
                        isLoading: _isLoading,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _ControlPanel(
            autoValidateEnabled: _autoValidateEnabled,
            guardEnabled: _guardEnabled,
            simulateApiError: _simulateApiError,
            submitted: _submitted,
            isLoading: _isLoading,
            onAutoValidate: (v) => setState(() => _autoValidateEnabled = v),
            onGuard: (v) => setState(() => _guardEnabled = v),
            onSimulateError: (v) => setState(() => _simulateApiError = v),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _IndicatorBar extends StatelessWidget {
  const _IndicatorBar({
    required this.indicator,
    required this.submitted,
    required this.isLoading,
  });

  final _IndicatorState indicator;
  final bool submitted;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (color, icon, label) = switch (indicator) {
      _IndicatorState.idle =>
        (scheme.outline, Icons.pending_outlined, LocaleKeys.beforeFirstSubmit.tr()),
      _IndicatorState.invalid =>
        (scheme.error, Icons.error_outline, LocaleKeys.formInvalid.tr()),
      _IndicatorState.loading =>
        (scheme.tertiary, Icons.hourglass_top_rounded, LocaleKeys.loading.tr()),
      _IndicatorState.apiError =>
        (scheme.error, Icons.cloud_off_outlined, LocaleKeys.somethingWrong.tr()),
      _IndicatorState.done =>
        (scheme.primary, Icons.check_circle_outline, LocaleKeys.success.tr()),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${LocaleKeys.formStateLabel.tr()}: $label',
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (submitted) ...[
            const SizedBox(width: 8),
            _CodeTag('_submitted', color),
          ],
          if (isLoading) ...[
            const SizedBox(width: 6),
            _CodeTag('_isLoading', scheme.tertiary),
          ],
        ],
      ),
    );
  }
}

class _CodeTag extends StatelessWidget {
  const _CodeTag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.autoValidateEnabled,
    required this.guardEnabled,
    required this.simulateApiError,
    required this.submitted,
    required this.isLoading,
    required this.onAutoValidate,
    required this.onGuard,
    required this.onSimulateError,
  });

  final bool autoValidateEnabled, guardEnabled, simulateApiError, submitted,
      isLoading;
  final ValueChanged<bool> onAutoValidate, onGuard, onSimulateError;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _SwitchRow(
            label: LocaleKeys.autoValidate.tr(),
            hint: 'autovalidateMode.onUserInteraction after first submit',
            value: autoValidateEnabled,
            onChanged: onAutoValidate,
          ),
          _SwitchRow(
            label: LocaleKeys.submitGuard.tr(),
            hint: 'if (_isLoading) return; — prevents double tap',
            value: guardEnabled,
            onChanged: onGuard,
          ),
          _SwitchRow(
            label: LocaleKeys.simulateApiError.tr(),
            hint: 'next submit returns API error toast',
            value: simulateApiError,
            onChanged: onSimulateError,
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String label, hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textTheme.bodyMedium),
              Text(
                hint,
                style: context.textTheme.labelSmall
                    ?.copyWith(color: context.colorScheme.outline),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
