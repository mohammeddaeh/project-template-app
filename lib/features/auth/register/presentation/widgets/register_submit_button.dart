import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The full-width "create account" button.
///
/// Rebuilt on every [refreshCubit] tick, so [canSubmit] is a getter read at
/// that moment — a plain `bool` would freeze the value the page had when it
/// last built, and the button would never enable.
class RegisterSubmitButton extends StatelessWidget {
  const RegisterSubmitButton({
    super.key,
    required this.refreshCubit,
    required this.isLoading,
    required this.canSubmit,
    required this.onSubmit,
  });

  final RefreshCubit refreshCubit;
  final bool isLoading;
  final ValueGetter<bool> canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RefreshCubit, RefreshState>(
      bloc: refreshCubit,
      builder: (context, _) => SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          text: LocaleKeys.registerCta.tr(),
          isLoading: isLoading,
          isEnabled: canSubmit(),
          onTap: onSubmit,
        ),
      ),
    );
  }
}
