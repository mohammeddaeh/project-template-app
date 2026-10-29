import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/features/auth/profile/presentation/pages/profile_screen.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// **تبويب الحساب بوضع `AuthMode.optional`**: الملف الشخصي لمن دخل، ودعوةٌ إلى
/// الدخول للزائر — ويتبدّل وحده حين يدخل المستخدم أو يخرج (`userStream`).
///
/// الدخول يُدفع فوق القشرة (`push`) لا مكانها، فـ«رجوع» يُعيد الزائر حيث كان.
class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final users = getIt<CurrentUserRepository>();
    return StreamBuilder<AuthUser?>(
      stream: users.userStream,
      initialData: users.currentUser,
      builder: (context, snapshot) => snapshot.data != null
          ? const ProfileScreen()
          : Scaffold(
              body: EmptyStateWidget(
                titleKey: LocaleKeys.guestTitle,
                descriptionKey: LocaleKeys.guestBody,
                icon: Icons.person_outline_rounded,
                actionLabelKey: LocaleKeys.signIn,
                onAction: () => context.router.push(const LoginRoute()),
              ),
            ),
    );
  }
}
