/// The shared vocabulary of a detail screen: a header, section headings, and
/// labelled facts.
///
/// Every detail screen in the app — user, branch, role, profile — had grown its
/// OWN private `_IdentityCard` and `_Fact`. Four copies each, and they had
/// already diverged: two supported an edit control, one supported a hint line,
/// two forced LTR on phone numbers, and only some stated an absent value
/// instead of dropping the row. A reader moving between the screens met four
/// slightly different renderings of the same idea, and any fix had to be made
/// four times or silently not at all.
///
/// These are the union, so a screen gains a capability by passing an argument
/// rather than by growing a fifth copy.
library;

import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/layout/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────

/// One labelled fact: what it is, what it says, and — when offered — how to
/// change it.
///
/// **An absent value is stated, never omitted.** A missing address and an
/// address nobody entered look identical if the row disappears, and the reader
/// cannot tell "we have no phone for this person" from "this screen forgot to
/// show it".
class DetailFact extends StatelessWidget {
  const DetailFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.onEdit,
    this.editTooltip,
    this.forceLtr = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;

  /// Null or blank renders as "not specified", in italics — a stated absence.
  final String? value;

  /// One line under the value, for the meaning a number cannot carry on its own
  /// (what an authority level is, what a status implies).
  final String? hint;

  /// Null when this fact is read-only for the current reader. The control is
  /// then **absent, not disabled** — a greyed button invites a tap that will
  /// never work and says nothing about why.
  final VoidCallback? onEdit;
  final String? editTooltip;

  /// Emails, phone numbers, and anything else whose digits reorder visibly in
  /// an RTL layout.
  final bool forceLtr;

  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value != null && value!.trim().isNotEmpty;
    final text = hasValue ? value!.trim() : LocaleKeys.notSpecified.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A tinted square rather than a bare glyph: at 18px an outline icon
          // beside 14px text reads as visual noise, and the fixed 34px box also
          // keeps every label in the column starting at the same x.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.bgNeutral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: colors.iconSubtle),
          ),
          12.widthBox,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    text,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color:
                          valueColor ??
                          (hasValue ? colors.textPrimary : colors.textMuted),
                      fontStyle: hasValue ? null : FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    // ui.TextDirection — easy_localization re-exports intl,
                    // whose own TextDirection would win the bare name here.
                    textDirection: forceLtr && hasValue
                        ? ui.TextDirection.ltr
                        : null,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.tune, size: 18, color: colors.iconAction),
              tooltip: editTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// The hero card that opens a detail screen: who or what this is, its state,
/// and the facts that identify it.
///
/// The name sits on a tinted band so the eye lands on it before the fields —
/// the screen's first job is to say *what am I looking at*, and a plain list of
/// rows makes the title just another row.
class DetailHeaderCard extends StatelessWidget {
  const DetailHeaderCard({
    super.key,
    required this.title,
    required this.leading,
    this.subtitle,
    this.tags = const [],
    this.facts = const [],
    this.trailing,
    this.footer,
  });

  final String title;

  /// The avatar or icon that identifies this record.
  final Widget leading;

  /// One line under the title — an email, an address, whatever answers "which
  /// one is this" when two records share a name.
  final String? subtitle;

  /// Status pills. Rendered in a `Wrap`, so a record in several states at once
  /// never overflows its row.
  final List<Widget> tags;

  /// [DetailFact]s, separated by hairlines rather than blank space: a divider
  /// makes each row a distinct answer, where spacing alone reads as one block
  /// of text.
  final List<Widget> facts;

  /// An action that belongs to the identity itself — renaming, editing.
  final Widget? trailing;

  /// A closing note, for a rule the reader needs before acting (a protected
  /// record, a system default).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      margin: EdgeInsets.zero,
      variant: AppCardVariant.container,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgNeutral,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                14.widthBox,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.headlineMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: tags),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          if (facts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  for (var i = 0; i < facts.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: colors.dividerSubtle),
                    facts[i],
                  ],
                ],
              ),
            ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// The heading every section on a detail screen shares.
///
/// [subtitle] is where a section states the fact that makes its action
/// meaningful — how many people a permission edit reaches, what a status change
/// would do. It belongs in the heading, above the control, rather than
/// somewhere the reader meets it after deciding.
class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// The section's own action — "edit", "add" — placed with the heading so it
  /// is found without scrolling the section first.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: colors.onPrimaryContainer),
          ),
          10.widthBox,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[8.widthBox, trailing!],
        ],
      ),
    );
  }
}
