import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/layout/section_title.dart';

// ─── "When to Use" Table Data ─────────────────────────────────────────────────

class _NavMethod {
  const _NavMethod({
    required this.name,
    required this.when,
  });
  final String name;
  final String when;
}

const _navMethods = <_NavMethod>[
  _NavMethod(
    name: 'push',
    when: 'New screen on top — user can go back',
  ),
  _NavMethod(
    name: 'replace',
    when: 'Swap current — no back to previous',
  ),
  _NavMethod(
    name: 'replaceAll',
    when: 'Clear all — fresh navigation start',
  ),
  _NavMethod(
    name: 'pop',
    when: 'Return to previous screen',
  ),
  _NavMethod(
    name: 'pop(value)',
    when: 'Return with result (CRUD form)',
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

@RoutePage()
class TestNavStackScreen extends StatefulWidget {
  const TestNavStackScreen({super.key});

  @override
  State<TestNavStackScreen> createState() => _TestNavStackScreenState();
}

class _TestNavStackScreenState extends State<TestNavStackScreen> {
  final List<String> _stack = ['HomeRoute'];
  int _counter = 0;

  void _push() =>
      setState(() => _stack.insert(0, 'Screen${++_counter}Route'));

  void _replace() =>
      setState(() => _stack[0] = 'Screen${++_counter}Route');

  void _replaceAll() => setState(() {
        _stack
          ..clear()
          ..add('HomeRoute');
        _counter = 0;
      });

  void _pop() {
    if (_stack.length > 1) setState(() => _stack.removeAt(0));
  }

  void _sessionExpired() => setState(() {
        _stack
          ..clear()
          ..add('LoginRoute');
        _counter = 0;
      });

  @override
  Widget build(BuildContext context) {
    context.locale;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.testNavStackTitle.tr(),
              style: context.textTheme.headlineSmall,
            ),
            Text(
              LocaleKeys.testNavStackSubtitle.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Current Stack header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SectionTitle(titleKey: LocaleKeys.currentStack),
          ),

          // ── Stack visualization ───────────────────────────────────────────
          Expanded(
            child: _stack.isEmpty
                ? Center(
                    child: Text(
                      LocaleKeys.stackEmpty.tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _stack.length,
                    itemBuilder: (context, index) {
                      final routeName = _stack[index];
                      final isTop = index == 0;
                      final isBase = index == _stack.length - 1;
                      return _StackCard(
                        routeName: routeName,
                        position: _stack.length - index,
                        isTop: isTop,
                        isBase: isBase,
                      );
                    },
                  ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          _ActionButtonRow(
            canPop: _stack.length > 1,
            onPush: _push,
            onReplace: _replace,
            onReplaceAll: _replaceAll,
            onPop: _pop,
          ),

          const Divider(height: 1),

          // ── When to Use table ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SectionTitle(titleKey: LocaleKeys.whenToUse),
          ),
          _WhenToUseTable(),

          // ── Session Expired chip ──────────────────────────────────────────
          _SessionExpiredChip(onTap: _sessionExpired),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Stack Card ──────────────────────────────────────────────────────────────

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.routeName,
    required this.position,
    required this.isTop,
    required this.isBase,
  });

  final String routeName;
  final int position;
  final bool isTop;
  final bool isBase;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bg = isBase
        ? scheme.primaryContainer
        : isTop
            ? scheme.secondaryContainer
            : scheme.surfaceContainer;
    final fg = isBase
        ? scheme.onPrimaryContainer
        : isTop
            ? scheme.onSecondaryContainer
            : scheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: fg.withValues(alpha: 0.15),
          child: Text(
            '$position',
            style: context.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          routeName,
          style: context.textTheme.bodyMedium?.copyWith(
            color: fg,
            fontFamily: 'monospace',
            fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isTop
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'top',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : isBase
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'base',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}

// ─── Action Button Row ────────────────────────────────────────────────────────

class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({
    required this.canPop,
    required this.onPush,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onPop,
  });

  final bool canPop;
  final VoidCallback onPush;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;
  final VoidCallback onPop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionBtn(
              label: 'push',
              icon: Icons.arrow_upward_rounded,
              color: scheme.primary,
              onTap: onPush,
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              label: 'replace',
              icon: Icons.swap_vert_rounded,
              color: scheme.secondary,
              onTap: onReplace,
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              label: 'replaceAll',
              icon: Icons.layers_clear_rounded,
              color: scheme.tertiary,
              onTap: onReplaceAll,
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              label: 'pop',
              icon: Icons.arrow_downward_rounded,
              color: canPop ? scheme.error : scheme.outlineVariant,
              onTap: canPop ? onPop : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? color : context.colorScheme.surfaceContainer,
        foregroundColor:
            enabled ? context.colorScheme.surface : context.colorScheme.outline,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}

// ─── When to Use Table ────────────────────────────────────────────────────────

class _WhenToUseTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          border: TableBorder.all(
            color: scheme.outlineVariant,
            width: 0.8,
            borderRadius: BorderRadius.circular(10),
          ),
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
              ),
              children: [
                _TableCell(
                  text: 'Method',
                  isHeader: true,
                ),
                _TableCell(
                  text: 'When',
                  isHeader: true,
                ),
              ],
            ),
            // Data rows
            for (final m in _navMethods)
              TableRow(
                children: [
                  _TableCell(text: m.name, isCode: true),
                  _TableCell(text: m.when),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.text,
    this.isHeader = false,
    this.isCode = false,
  });

  final String text;
  final bool isHeader;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        text,
        style: isHeader
            ? context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              )
            : isCode
                ? context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  )
                : context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
      ),
    );
  }
}

// ─── Session Expired Chip ────────────────────────────────────────────────────

class _SessionExpiredChip extends StatelessWidget {
  const _SessionExpiredChip({required this.onTap});

  final VoidCallback onTap;

  static const _code =
      "getIt<AppRouter>().replaceAll([const LoginRoute()])";

  void _copyCode(BuildContext context) {
    context.locale;
    Clipboard.setData(const ClipboardData(text: _code));
    context.feedback.toast(LocaleKeys.codeCopied.tr());
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 16,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Session Expired → $_code',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.onErrorContainer,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: () => _copyCode(context),
            icon: const Icon(Icons.copy_rounded, size: 16),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: LocaleKeys.copyCode.tr(),
          ),
        ],
      ),
    );
  }
}
