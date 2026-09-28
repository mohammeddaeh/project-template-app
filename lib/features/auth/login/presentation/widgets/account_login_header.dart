import 'package:app_template/features/auth/shared/entities/remembered_account.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Who is being signed into — avatar, name, and the full address.
///
/// The address is shown here and not on the saved card: this is where it
/// answers "am I signing in as the right person?".
class AccountLoginHeader extends StatelessWidget {
  const AccountLoginHeader({super.key, required this.account});

  final RememberedAccount account;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AvatarWidget(
            imageUrl: account.imageUrl,
            initial: account.fullName,
            radius: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          account.fullName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          account.email,
          // Forced LTR: an address laid out RTL has its parts reordered, so
          // `m@example.com` can read `example.com@m`.
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
