import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _Product {
  _Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  final String id;
  final String name;
  final double price;
  final String category;

  _Product copyWith({String? name, double? price, String? category}) =>
      _Product(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        category: category ?? this.category,
      );
}

const _kCategories = ['Electronics', 'Clothing', 'Food', 'Sports', 'Books'];

List<_Product> _initialProducts() => [
      _Product(id: '1', name: 'Wireless Headphones', price: 89.99, category: 'Electronics'),
      _Product(id: '2', name: 'Running Shoes', price: 129.00, category: 'Sports'),
      _Product(id: '3', name: 'Python Programming', price: 34.50, category: 'Books'),
      _Product(id: '4', name: 'Organic Coffee', price: 18.75, category: 'Food'),
      _Product(id: '5', name: 'Denim Jacket', price: 65.00, category: 'Clothing'),
    ];

// ── Event Log ─────────────────────────────────────────────────────────────────

enum _LogType { add, edit, delete, error, rollback }

class _LogEntry {
  _LogEntry(this.message, this.type);
  final String message;
  final _LogType type;
}

// ── Screen ────────────────────────────────────────────────────────────────────

@RoutePage()
class TestCrudDemoScreen extends StatefulWidget {
  const TestCrudDemoScreen({super.key});

  @override
  State<TestCrudDemoScreen> createState() => _TestCrudDemoScreenState();
}

class _TestCrudDemoScreenState extends State<TestCrudDemoScreen> {
  List<_Product> _products = _initialProducts();
  final List<_LogEntry> _log = [];
  bool _simulateError = false;
  bool _showLog = false;
  int _nextId = 100;

  void _addLog(String msg, _LogType type) {
    setState(() => _log.insert(0, _LogEntry(msg, type)));
  }

  // ── Add ────────────────────────────────────────────────────────────────────

  Future<void> _showAddSheet() async {
    final result = await _showProductSheet(context);
    if (result == null || !mounted) return;

    // Optimistic: add immediately
    setState(() => _products.insert(0, result));
    _addLog('+ Added "${result.name}"', _LogType.add);

    // Simulate server
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_simulateError) {
      // Rollback
      setState(() => _products.removeWhere((p) => p.id == result.id));
      _addLog('↩ Rolled back "${result.name}" (server error)', _LogType.rollback);
      context.feedback.error(LocaleKeys.somethingWrong.tr());
    } else {
      context.feedback.success(LocaleKeys.addedSuccessfully.tr());
    }
  }

  // ── Edit ───────────────────────────────────────────────────────────────────

  Future<void> _showEditSheet(_Product original) async {
    final result = await _showProductSheet(context, initial: original);
    if (result == null || !mounted) return;

    // Optimistic: replace immediately
    setState(() {
      final idx = _products.indexWhere((p) => p.id == original.id);
      if (idx >= 0) _products[idx] = result;
    });
    _addLog('✎ Edited "${result.name}"', _LogType.edit);

    // Simulate server
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_simulateError) {
      // Rollback
      setState(() {
        final idx = _products.indexWhere((p) => p.id == original.id);
        if (idx >= 0) _products[idx] = original;
      });
      _addLog('↩ Rolled back "${original.name}" (server error)', _LogType.rollback);
      context.feedback.error(LocaleKeys.somethingWrong.tr());
    } else {
      context.feedback.success(LocaleKeys.updatedSuccessfully.tr());
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(_Product product) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.deleteConfirmTitle,
      messageKey: LocaleKeys.deleteConfirmMessage,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    // Optimistic: remove immediately
    final backup = List<_Product>.from(_products);
    setState(() => _products.removeWhere((p) => p.id == product.id));
    _addLog('✕ Deleted "${product.name}"', _LogType.delete);

    // Simulate server
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_simulateError) {
      // Rollback
      setState(() => _products = backup);
      _addLog('↩ Rolled back delete "${product.name}" (server error)', _LogType.rollback);
      context.feedback.error(LocaleKeys.somethingWrong.tr());
    } else {
      context.feedback.success(LocaleKeys.deletedSuccessfully.tr());
    }
  }

  // ── Bottom Sheet Form ──────────────────────────────────────────────────────

  Future<_Product?> _showProductSheet(
    BuildContext ctx, {
    _Product? initial,
  }) {
    return showModalBottomSheet<_Product>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductSheet(
        initial: initial,
        nextId: '${_nextId++}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testCrudDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          // Event log toggle
          IconButton(
            onPressed: () => setState(() => _showLog = !_showLog),
            icon: Icon(
              _showLog ? Icons.receipt_long : Icons.receipt_long_outlined,
              color: _showLog ? scheme.primary : null,
            ),
            tooltip: LocaleKeys.eventLog.tr(),
          ),
          // Server error toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _simulateError ? '⚠ Error ON' : 'Error OFF',
                style: context.textTheme.labelSmall?.copyWith(
                  color: _simulateError ? scheme.error : scheme.outline,
                ),
              ),
              selected: _simulateError,
              onSelected: (v) => setState(() => _simulateError = v),
              selectedColor: scheme.errorContainer,
              showCheckmark: false,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Event Log Panel ────────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildLogPanel(),
            crossFadeState: _showLog
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // ── Product List ───────────────────────────────────────────────────
          Expanded(
            child: _products.isEmpty
                ? EmptyStateWidget(
                    titleKey: LocaleKeys.noItems,
                    icon: Icons.inventory_2_outlined,
                    onAction: _showAddSheet,
                    actionLabelKey: LocaleKeys.addProduct,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80, top: 8),
                    itemCount: _products.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _buildProductTile(_products[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: Text(LocaleKeys.addProduct.tr()),
      ),
    );
  }

  Widget _buildProductTile(_Product product) {
    final scheme = context.colorScheme;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(
          product.name[0],
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(product.name, style: context.textTheme.bodyMedium),
      subtitle: Text(
        '${product.category} · \$${product.price.toStringAsFixed(2)}',
        style: context.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _showEditSheet(product),
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: LocaleKeys.editProduct.tr(),
          ),
          IconButton(
            onPressed: () => _confirmDelete(product),
            icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
            tooltip: LocaleKeys.delete.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    final scheme = context.colorScheme;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.2))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Text(
                  LocaleKeys.eventLog.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.outline,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _log.clear()),
                  child: Text(LocaleKeys.clearLog.tr(),
                      style: context.textTheme.labelSmall),
                ),
              ],
            ),
          ),
          Expanded(
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      LocaleKeys.noEventsYet.tr(),
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: scheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _log.length,
                    itemBuilder: (_, i) => _buildLogRow(_log[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(_LogEntry entry) {
    final scheme = context.colorScheme;
    final color = switch (entry.type) {
      _LogType.add      => scheme.primary,
      _LogType.edit     => scheme.tertiary,
      _LogType.delete   => scheme.error,
      _LogType.error    => scheme.error,
      _LogType.rollback => scheme.secondary,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              style: context.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Bottom Sheet ──────────────────────────────────────────────────────

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({this.initial, required this.nextId});
  final _Product? initial;
  final String nextId;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  String _category = _kCategories.first;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initial != null
          ? widget.initial!.price.toStringAsFixed(2)
          : '',
    );
    if (widget.initial != null) _category = widget.initial!.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.unfocus();
    final product = _Product(
      id: widget.initial?.id ?? widget.nextId,
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      category: _category,
    );
    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final scheme = context.colorScheme;
    final isEdit = widget.initial != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit
                    ? LocaleKeys.editProduct.tr()
                    : LocaleKeys.addProduct.tr(),
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _nameCtrl,
                labelText: LocaleKeys.productName.tr(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? LocaleKeys.fieldRequired.tr()
                    : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _priceCtrl,
                labelText: LocaleKeys.productPrice.tr(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                ltr: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return LocaleKeys.fieldRequired.tr();
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return LocaleKeys.invalidInput.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppSelectField<String>(
                labelText: LocaleKeys.productCategory.tr(),
                value: _category,
                items: _kCategories,
                labelResolver: (c) => c,
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: isEdit ? LocaleKeys.save.tr() : LocaleKeys.add.tr(),
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
