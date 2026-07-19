import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class TestFormsDemoScreen extends StatefulWidget {
  const TestFormsDemoScreen({super.key});

  @override
  State<TestFormsDemoScreen> createState() => _TestFormsDemoScreenState();
}

class _TestFormsDemoScreenState extends State<TestFormsDemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _refreshCubit = RefreshCubit();

  bool _isLoading = false;
  bool _submitted = false;

  bool get _formHasContent =>
      _nameCtrl.text.isNotEmpty ||
      _emailCtrl.text.isNotEmpty ||
      _passwordCtrl.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_refreshCubit.refresh);
    _emailCtrl.addListener(_refreshCubit.refresh);
    _passwordCtrl.addListener(_refreshCubit.refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _refreshCubit.close();
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
    if (v.length < 8 || v.length > 30) return LocaleKeys.passwordLength.tr();
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    context.unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.feedback.success(LocaleKeys.submitSuccess.tr());
  }

  void _reset() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _passwordCtrl.clear();
    _formKey.currentState?.reset();
    setState(() {
      _submitted = false;
      _isLoading = false;
    });
    _refreshCubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(LocaleKeys.testFormsDemoTitle.tr()),
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
      body: KeyboardDismissWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  LocaleKeys.testFormsSubtitle.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameCtrl,
                  labelText: LocaleKeys.fullName.tr(),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailCtrl,
                  labelText: LocaleKeys.eMail.tr(),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneCtrl,
                  labelText: LocaleKeys.phone.tr(),
                  keyboardType: TextInputType.phone,
                  ltr: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordCtrl,
                  labelText: LocaleKeys.password.tr(),
                  isFieldObscure: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 32),
                BlocBuilder<RefreshCubit, RefreshState>(
                  bloc: _refreshCubit,
                  builder: (context, _) {
                    context.locale;
                    final canSubmit = _formHasContent && !_isLoading;
                    return PrimaryButton(
                      text: LocaleKeys.send.tr(),
                      isLoading: _isLoading,
                      isEnabled: canSubmit,
                      onTap: canSubmit ? _submit : null,
                    );
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
