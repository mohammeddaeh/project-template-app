import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

// ─── Simulated state machine ─────────────────────────────────────────────────

enum _BlocState { initial, loading, loaded, error }

class _HistoryEntry {
  const _HistoryEntry(this.time, this.state);
  final DateTime time;
  final _BlocState state;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

@RoutePage()
class TestBlocStatesScreen extends StatefulWidget {
  const TestBlocStatesScreen({super.key});

  @override
  State<TestBlocStatesScreen> createState() => _TestBlocStatesScreenState();
}

class _TestBlocStatesScreenState extends State<TestBlocStatesScreen> {
  _BlocState _state = _BlocState.initial;
  bool _injectError = false;
  double _delayMs = 800;
  Timer? _timer;
  final List<_HistoryEntry> _history = [];

  void _transition(_BlocState next) {
    if (!mounted) return;
    setState(() {
      _state = next;
      _history.insert(0, _HistoryEntry(DateTime.now(), next));
      if (_history.length > 20) _history.removeLast();
    });
  }

  void _load() {
    if (_state == _BlocState.loading) return;
    _timer?.cancel();
    _transition(_BlocState.loading);
    _timer = Timer(Duration(milliseconds: _delayMs.round()), () {
      _transition(_injectError ? _BlocState.error : _BlocState.loaded);
    });
  }

  void _reset() {
    _timer?.cancel();
    _transition(_BlocState.initial);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testBlocStatesDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── State diagram ────────────────────────────────────────────────
          _StateDiagram(current: _state),
          const SizedBox(height: 16),

          // ── Controls ──────────────────────────────────────────────────────
          _ControlsCard(
            isLoading: _state == _BlocState.loading,
            injectError: _injectError,
            delayMs: _delayMs,
            onLoad: _load,
            onReset: _reset,
            onInjectChanged: (v) => setState(() => _injectError = v),
            onDelayChanged: (v) => setState(() => _delayMs = v),
          ),
          const SizedBox(height: 20),

          // ── Freezed definition ────────────────────────────────────────────
          SectionTitle(titleKey: LocaleKeys.stateDefinition),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _CodeBlock(
              key: ValueKey('freezed_${_state.name}'),
              code: _freezedSnippet(_state),
            ),
          ),
          const SizedBox(height: 12),

          // ── BlocConsumer snippet ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _CodeBlock(
              key: ValueKey('consumer_${_state.name}'),
              code: _consumerSnippet(_state),
            ),
          ),
          const SizedBox(height: 20),

          // ── History ───────────────────────────────────────────────────────
          SectionTitle(
            titleKey: LocaleKeys.stateHistory,
            trailing: _history.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: () => setState(_history.clear),
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(LocaleKeys.clearLog.tr()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
          ),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                LocaleKeys.noEventsYet.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.outline,
                ),
              ),
            )
          else
            for (final entry in _history) _HistoryRow(entry: entry),
        ],
      ),
    );
  }
}

// ─── State visuals ────────────────────────────────────────────────────────────

(IconData, Color) _stateStyle(BuildContext context, _BlocState s) =>
    switch (s) {
      _BlocState.initial => (
          Icons.fiber_manual_record_outlined,
          context.colorScheme.outline,
        ),
      _BlocState.loading => (
          Icons.hourglass_empty_rounded,
          context.colorScheme.primary,
        ),
      _BlocState.loaded => (
          Icons.check_circle_outline_rounded,
          Colors.green.shade600,
        ),
      _BlocState.error => (
          Icons.error_outline_rounded,
          context.colorScheme.error,
        ),
    };

// ─── State Diagram ────────────────────────────────────────────────────────────

class _StateDiagram extends StatelessWidget {
  const _StateDiagram({required this.current});

  final _BlocState current;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in _BlocState.values) ...[
              if (s != _BlocState.values.first)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
              _StateNode(state: s, isCurrent: s == current),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateNode extends StatelessWidget {
  const _StateNode({required this.state, required this.isCurrent});

  final _BlocState state;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _stateStyle(context, state);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCurrent ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isCurrent ? 0 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isCurrent && state == _BlocState.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: isCurrent ? Colors.white : color,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          state.name,
          style: context.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: color,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Controls ─────────────────────────────────────────────────────────────────

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.isLoading,
    required this.injectError,
    required this.delayMs,
    required this.onLoad,
    required this.onReset,
    required this.onInjectChanged,
    required this.onDelayChanged,
  });

  final bool isLoading;
  final bool injectError;
  final double delayMs;
  final VoidCallback onLoad;
  final VoidCallback onReset;
  final ValueChanged<bool> onInjectChanged;
  final ValueChanged<double> onDelayChanged;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: isLoading ? null : onLoad,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(LocaleKeys.triggerLoad.tr()),
              ),
              const Spacer(),
              TextButton(
                onPressed: onReset,
                child: Text(LocaleKeys.reset.tr()),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.injectError.tr(),
                  style: context.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(value: injectError, onChanged: onInjectChanged),
            ],
          ),
          Row(
            children: [
              Text(
                LocaleKeys.delayMs.tr(),
                style: context.textTheme.bodyMedium,
              ),
              Expanded(
                child: Slider(
                  value: delayMs,
                  min: 300,
                  max: 2000,
                  divisions: 17,
                  onChanged: onDelayChanged,
                ),
              ),
              Text(
                '${delayMs.round()}ms',
                style: context.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: context.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Code snippets ────────────────────────────────────────────────────────────

String _freezedSnippet(_BlocState s) {
  String m(_BlocState x) => x == s ? '  // ← ACTIVE' : '';
  return '@freezed\n'
      'abstract class ProductsState with _\$ProductsState {\n'
      '  const factory ProductsState.initial() = ProductsInitial;${m(_BlocState.initial)}\n'
      '  const factory ProductsState.loading() = ProductsLoading;${m(_BlocState.loading)}\n'
      '  const factory ProductsState.loaded({\n'
      '    required List<Product> products,\n'
      '  }) = ProductsLoaded;${m(_BlocState.loaded)}\n'
      '  const factory ProductsState.error({\n'
      '    required String message,\n'
      '  }) = ProductsError;${m(_BlocState.error)}\n'
      '}';
}

String _consumerSnippet(_BlocState s) {
  String m(_BlocState x) => x == s ? '  // ← ACTIVE' : '';
  return 'BlocConsumer<ProductsCubit, ProductsState>(\n'
      '  listener: (context, state) {\n'
      '    state.maybeWhen(\n'
      '      error: (msg) => context.feedback.error(msg),\n'
      '      orElse: () {},\n'
      '    );\n'
      '  },\n'
      '  builder: (context, state) => state.when(\n'
      '    initial: () => const SizedBox.shrink(),${m(_BlocState.initial)}\n'
      '    loading: () => const LoadingWidget(),${m(_BlocState.loading)}\n'
      '    loaded: (products) => ProductsList(products),${m(_BlocState.loaded)}\n'
      '    error: (_) => const SizedBox.shrink(),${m(_BlocState.error)}\n'
      '  ),\n'
      ')';
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFFD4D4D4),
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

// ─── History Row ──────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _stateStyle(context, entry.state);
    final t = entry.time;
    final timeStr = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            timeStr,
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: context.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded,
              size: 12, color: context.colorScheme.outlineVariant),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  entry.state.name,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
