import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/shared/entities/remembered_account.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// One saved account, compact — avatar, first name, and the way to remove it.
///
/// Deliberately small: this sits **above** the ordinary email/password form
/// rather than replacing it, so it has to read as a shortcut on the login
/// screen and not as the screen itself. The address is not shown here — it is
/// long, it forces the tile wide, and it is repeated in full on the password
/// screen where it actually answers "am I signing in as the right person?".
///
/// The remove control is a visible button, not a long-press: a saved address is
/// the user's own data on their own device, and "hold down the face you want
/// gone" is a gesture nobody discovers. It stays inside the tile's bounds — a
/// child painted outside its parent's box still draws but does not reliably
/// hit-test, which would make it visible and dead.
class RememberedAccountCard extends StatelessWidget {
  const RememberedAccountCard({
    super.key,
    required this.account,
    required this.onTap,
    required this.onRemove,
  });

  final RememberedAccount account;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const double _width = 84;
  static const double _avatarRadius = 26;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              // Room at the top-end corner for the remove button, so the
              // avatar never sits under it.
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarWidget(
                    imageUrl: account.imageUrl,
                    initial: account.fullName,
                    radius: _avatarRadius,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // First name only — a full name wraps or gets cut at this
                    // width, and the picture is doing most of the identifying.
                    account.fullName.split(' ').first,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Semantics(
              button: true,
              label: LocaleKeys.remove.tr(),
              child: InkResponse(
                onTap: onRemove,
                radius: 18,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.colors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.borderSubtle),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
