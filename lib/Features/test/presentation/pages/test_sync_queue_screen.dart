// ============================================================================
// FILE: test_sync_queue_screen.dart
// ============================================================================

import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

// ============================================================================
// 1. نماذج البيانات
// ============================================================================

/// أنواع العمليات
enum OperationType { create, update, delete }

/// حالة العنصر داخل طابور المعلَّقات (لا يوجد "مكتمل" — العنصر يُحذف فور نجاحه)
enum PendingItemStatus {
  pending, // في انتظار الرفع (سيُنفَّذ عند توفر الاتصال)
  processing, // جاري الرفع حالياً
  offline, // تم الحفظ محلياً فقط (غير متصل)
}

/// عنصر في طابور المعلَّقات
class PendingSyncItem {
  PendingSyncItem({
    required this.id,
    required this.type,
    required this.entityName,
    required this.entityId,
    required this.createdAt,
    required this.status,
    this.attempts = 0,
    this.data = const {},
  });

  final String id;
  final OperationType type;
  final String entityName;
  final String entityId;
  final DateTime createdAt;
  PendingItemStatus status;
  int attempts;
  Map<String, dynamic> data;
}

/// عنصر في طابور الأخطاء — عملية فشل تنفيذها وتحتاج تدخلاً (إعادة محاولة أو تجاهل)
class FailedSyncItem {
  FailedSyncItem({
    required this.id,
    required this.type,
    required this.entityName,
    required this.entityId,
    required this.createdAt,
    required this.failedAt,
    required this.attempts,
    required this.error,
    this.data = const {},
  });

  final String id;
  final OperationType type;
  final String entityName;
  final String entityId;
  final DateTime createdAt;
  final DateTime failedAt;
  final int attempts;
  final String error;
  Map<String, dynamic> data;
}

/// كيان في التخزين المحلي
class LocalEntity {
  LocalEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.data = const {},
    this.isSynced = true,
    this.hasPendingChanges = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> data;
  bool isSynced;
  bool hasPendingChanges;
}

/// كيان في السيرفر
class ServerEntity {
  ServerEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.data = const {},
    this.version = 1,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> data;
  int version;
  bool isDeleted;
}

/// إحصائيات المزامنة — كل عدَّاد مشتق من طابور مستقل، لا من قائمة مشتركة
class SyncStatistics {
  const SyncStatistics({
    this.pending = 0,
    this.processing = 0,
    this.offline = 0,
    this.failed = 0,
    this.syncedCount = 0,
  });

  final int pending;
  final int processing;
  final int offline;
  final int failed;

  /// عدَّاد تراكمي للعمليات التي نجحت خلال الجلسة (لا تُحفَظ كعناصر — تُحذف فور نجاحها)
  final int syncedCount;

  int get pendingTotal => pending + processing + offline;
  bool get hasPendingItems => pendingTotal > 0;
  bool get hasFailedItems => failed > 0;
}

// ============================================================================
// 2. شاشة المحاكاة الرئيسية
// ============================================================================

@RoutePage()
class TestSyncQueueScreen extends StatefulWidget {
  const TestSyncQueueScreen({super.key});

  @override
  State<TestSyncQueueScreen> createState() => _TestSyncQueueScreenState();
}

class _TestSyncQueueScreenState extends State<TestSyncQueueScreen> {
  // ── الحالة العامة ──────────────────────────────────────────────────────

  bool _isOnline = true;
  bool _isProcessing = false;
  final bool _isAutoSyncEnabled = true;

  // المخازن
  final List<LocalEntity> _localStore = [];
  final List<ServerEntity> _serverStore = [];

  // طابوران مستقلان: معلَّق (بانتظار التنفيذ) وأخطاء (تحتاج تدخلاً)
  final List<PendingSyncItem> _pendingQueue = [];
  final List<FailedSyncItem> _failedQueue = [];

  /// عدَّاد العمليات الناجحة خلال الجلسة — لا يُحتفَظ بالعناصر بعد نجاحها
  int _syncedCount = 0;

  // سجل الأحداث
  final List<Map<String, dynamic>> _logs = [];

  // العنصر المختار
  LocalEntity? _selectedEntity;

  // المعرفات
  int _idCounter = 0;
  int _syncIdCounter = 0;

  // المؤقتات
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _addInitialData();
    _startAutoSync();
    _addLog('🚀 ${LocaleKeys.testSyncQueueTitle.tr()}');
    _addLog('📡 ${LocaleKeys.goOnline.tr()}');
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  // ── البيانات الأولية ───────────────────────────────────────────────────

  void _addInitialData() {
    _localStore.addAll([
      LocalEntity(
        id: _generateId(),
        name: '${LocaleKeys.product.tr()} 1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        data: {'price': 99.99, 'stock': 50, 'category': 'الكترونيات'},
        isSynced: true,
        hasPendingChanges: false,
      ),
      LocalEntity(
        id: _generateId(),
        name: '${LocaleKeys.product.tr()} 2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        data: {'price': 149.99, 'stock': 30, 'category': 'ملابس'},
        isSynced: true,
        hasPendingChanges: false,
      ),
    ]);

    for (var entity in _localStore) {
      _serverStore.add(
        ServerEntity(
          id: entity.id,
          name: entity.name,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
          data: entity.data,
          version: 1,
        ),
      );
    }
  }

  void _startAutoSync() {
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isOnline && _isAutoSyncEnabled && _pendingQueue.isNotEmpty) {
        _addLog('🔄 ${LocaleKeys.syncing.tr()}...', isInfo: true);
        _processQueue();
      }
    });
  }

  String _generateId() => 'entity_${++_idCounter}';
  String _generateSyncId() => 'sync_${++_syncIdCounter}';

  // ── إدارة السجلات ─────────────────────────────────────────────────────

  void _addLog(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isInfo = false,
  }) {
    setState(() {
      _logs.insert(0, {
        'time': DateTime.now(),
        'message': message,
        'isError': isError,
        'isSuccess': isSuccess,
        'isInfo': isInfo,
      });
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  // ── العمليات الأساسية ─────────────────────────────────────────────────

  void _editProduct(LocalEntity entity, Map<String, dynamic> newData) {
    final oldName = entity.name;

    setState(() {
      entity.data = {...entity.data, ...newData};
      entity.updatedAt = DateTime.now();
      entity.isSynced = _isOnline;
      entity.hasPendingChanges = !_isOnline;
    });

    _addLog(
      '✏️ ${LocaleKeys.updatedSuccessfully.tr()}: $oldName',
      isSuccess: true,
    );
    _enqueue(entity, OperationType.update);
  }

  void _deleteProduct(LocalEntity entity) {
    final name = entity.name;

    setState(() {
      _localStore.remove(entity);
      if (_selectedEntity == entity) _selectedEntity = null;
    });

    _addLog(
      '🗑️ ${LocaleKeys.deletedSuccessfully.tr()}: $name',
      isSuccess: true,
    );
    _enqueue(entity, OperationType.delete);
  }

  // ── طابور المعلَّقات وطابور الأخطاء ────────────────────────────────────

  /// يضيف عملية لطابور المعلَّقات، ويبدأ التنفيذ فوراً إن كان متصلاً
  void _enqueue(LocalEntity entity, OperationType type) {
    setState(() {
      _pendingQueue.add(
        PendingSyncItem(
          id: _generateSyncId(),
          type: type,
          entityName: entity.name,
          entityId: entity.id,
          createdAt: DateTime.now(),
          status: _isOnline
              ? PendingItemStatus.pending
              : PendingItemStatus.offline,
          data: entity.data,
        ),
      );
    });

    if (_isOnline) {
      _processQueue();
    } else {
      _addLog('📴 ${LocaleKeys.simulatedOffline.tr()}', isInfo: true);
    }
  }

  /// معالجة طابور المعلَّقات فقط — العناصر الفاشلة تنتقل لطابور مستقل
  /// ولا يُحتفَظ بأي عنصر بعد نجاحه (يتفرّغ الطابور بدل تراكم السجل فيه)
  Future<void> _processQueue() async {
    if (_isProcessing || !_isOnline) return;

    final runnable = _pendingQueue
        .where((item) => item.status != PendingItemStatus.offline)
        .toList();
    if (runnable.isEmpty) return;

    setState(() => _isProcessing = true);
    _addLog(
      '🔄 ${LocaleKeys.syncing.tr()}... (${runnable.length} ${LocaleKeys.items.tr()})',
      isInfo: true,
    );

    for (var item in runnable) {
      if (!_isOnline) break;
      await _processSingleItem(item);
    }

    setState(() => _isProcessing = false);

    if (_isOnline &&
        _pendingQueue.any((item) => item.status != PendingItemStatus.offline)) {
      _processQueue();
    } else {
      _addLog('✅ ${LocaleKeys.syncQueueEmpty.tr()}', isSuccess: true);
    }
  }

  Future<void> _processSingleItem(PendingSyncItem item) async {
    setState(() {
      item.status = PendingItemStatus.processing;
      item.attempts += 1;
    });

    _addLog(
      '⏳ ${LocaleKeys.syncing.tr()}: ${item.entityName} (${LocaleKeys.retry.tr()} ${item.attempts})',
      isInfo: true,
    );

    // محاكاة وقت الرفع
    await Future.delayed(const Duration(milliseconds: 800));

    // محاكاة الفشل (للتجربة) — أول محاولة تحديث فقط
    if (item.attempts == 1 && item.type == OperationType.update) {
      setState(() {
        _pendingQueue.remove(item);
        _failedQueue.add(
          FailedSyncItem(
            id: item.id,
            type: item.type,
            entityName: item.entityName,
            entityId: item.entityId,
            createdAt: item.createdAt,
            failedAt: DateTime.now(),
            attempts: item.attempts,
            error: '⚠️ ${LocaleKeys.error.tr()}: ${LocaleKeys.failedToSync.tr()}',
            data: item.data,
          ),
        );
      });
      _addLog(
        '❌ ${LocaleKeys.failedToSync.tr()}: ${item.entityName}',
        isError: true,
      );
      return;
    }

    // نجاح الرفع — يُحذف العنصر فوراً من الطابور، لا يُحتفَظ به
    setState(() {
      _pendingQueue.remove(item);
      _syncedCount++;
    });

    _syncToServer(item);

    final localEntity = _localStore.firstWhere(
      (e) => e.id == item.entityId,
      orElse: () => LocalEntity(id: '', name: '', createdAt: DateTime.now()),
    );
    if (localEntity.id.isNotEmpty) {
      localEntity.isSynced = true;
      localEntity.hasPendingChanges = false;
      if (mounted) setState(() {});
    }

    _addLog(
      '✅ ${LocaleKeys.success.tr()}: ${item.entityName}',
      isSuccess: true,
    );
  }

  /// مزامنة مع السيرفر
  void _syncToServer(PendingSyncItem item) {
    if (item.type == OperationType.delete) {
      final serverEntity = _serverStore.firstWhere(
        (e) => e.id == item.entityId,
        orElse: () => ServerEntity(id: '', name: '', createdAt: DateTime.now()),
      );
      if (serverEntity.id.isNotEmpty) {
        serverEntity.isDeleted = true;
        _serverStore.remove(serverEntity);
      }
      return;
    }

    final serverEntity = _serverStore.firstWhere(
      (e) => e.id == item.entityId,
      orElse: () => ServerEntity(
        id: item.entityId,
        name: item.entityName,
        createdAt: DateTime.now(),
        data: item.data,
      ),
    );

    final updatedEntity = ServerEntity(
      id: serverEntity.id,
      name: item.entityName,
      createdAt: serverEntity.createdAt,
      updatedAt: DateTime.now(),
      data: {...serverEntity.data, ...item.data},
      version: serverEntity.version + 1,
    );

    final index = _serverStore.indexWhere((e) => e.id == item.entityId);
    if (index >= 0) {
      _serverStore[index] = updatedEntity;
    } else {
      _serverStore.add(updatedEntity);
    }
  }

  // ── التحكم في الاتصال ──────────────────────────────────────────────────

  void _toggleConnectivity() {
    final wasOnline = _isOnline;
    setState(() => _isOnline = !_isOnline);

    if (wasOnline && !_isOnline) {
      _addLog('📡 ${LocaleKeys.goOffline.tr()}', isError: true);
      for (var item in _pendingQueue) {
        if (item.status == PendingItemStatus.processing) {
          item.status = PendingItemStatus.offline;
        }
      }
    } else if (!wasOnline && _isOnline) {
      _addLog('📡 ${LocaleKeys.goOnline.tr()}', isSuccess: true);
      for (var item in _pendingQueue) {
        if (item.status == PendingItemStatus.offline) {
          item.status = PendingItemStatus.pending;
        }
      }
      _processQueue();
    }
  }

  // ── إدارة الطابورين ────────────────────────────────────────────────────

  /// يعيد كل عناصر طابور الأخطاء إلى طابور المعلَّقات لإعادة تنفيذها
  void _retryFailed() {
    if (_failedQueue.isEmpty) {
      _addLog('ℹ️ ${LocaleKeys.noFailedItems.tr()}', isInfo: true);
      return;
    }

    setState(() {
      for (var failed in _failedQueue) {
        _pendingQueue.add(
          PendingSyncItem(
            id: failed.id,
            type: failed.type,
            entityName: failed.entityName,
            entityId: failed.entityId,
            createdAt: failed.createdAt,
            status: _isOnline
                ? PendingItemStatus.pending
                : PendingItemStatus.offline,
            attempts: failed.attempts,
            data: failed.data,
          ),
        );
      }
      final count = _failedQueue.length;
      _failedQueue.clear();
      _addLog(
        '🔄 ${LocaleKeys.retryingFailed.tr()}: $count ${LocaleKeys.items.tr()}',
        isSuccess: true,
      );
    });

    if (_isOnline) _processQueue();
  }

  void _clearPendingQueue() {
    if (_pendingQueue.isEmpty) {
      _addLog('ℹ️ ${LocaleKeys.syncQueueEmpty.tr()}', isInfo: true);
      return;
    }

    setState(() {
      _addLog(
        '🧹 ${LocaleKeys.clearedQueue.tr()}: ${_pendingQueue.length} ${LocaleKeys.items.tr()}',
        isSuccess: true,
      );
      _pendingQueue.clear();
    });
  }

  void _clearFailedQueue() {
    if (_failedQueue.isEmpty) {
      _addLog('ℹ️ ${LocaleKeys.noFailedItems.tr()}', isInfo: true);
      return;
    }

    setState(() {
      _addLog(
        '🧹 ${LocaleKeys.clearedQueue.tr()}: ${_failedQueue.length} ${LocaleKeys.items.tr()}',
        isSuccess: true,
      );
      _failedQueue.clear();
    });
  }

  void _clearAllQueues() {
    if (_pendingQueue.isEmpty && _failedQueue.isEmpty) {
      _addLog('ℹ️ ${LocaleKeys.syncQueueEmpty.tr()}', isInfo: true);
      return;
    }

    final count = _pendingQueue.length + _failedQueue.length;
    setState(() {
      _pendingQueue.clear();
      _failedQueue.clear();
    });
    _addLog(
      '🧹 ${LocaleKeys.clearedQueue.tr()}: $count ${LocaleKeys.items.tr()}',
      isSuccess: true,
    );
  }

  // ── إحصائيات المزامنة ─────────────────────────────────────────────────

  SyncStatistics _getSyncStats() {
    final pending = _pendingQueue
        .where((e) => e.status == PendingItemStatus.pending)
        .length;
    final processing = _pendingQueue
        .where((e) => e.status == PendingItemStatus.processing)
        .length;
    final offline = _pendingQueue
        .where((e) => e.status == PendingItemStatus.offline)
        .length;

    return SyncStatistics(
      pending: pending,
      processing: processing,
      offline: offline,
      failed: _failedQueue.length,
      syncedCount: _syncedCount,
    );
  }

  // ── عرض التفاصيل ──────────────────────────────────────────────────────

  void _showEntityDetails(LocalEntity entity) {
    setState(() => _selectedEntity = entity);
    _showEditDialog(entity);
  }

  void _showEditDialog(LocalEntity entity) {
    final priceController = TextEditingController(
      text: entity.data['price']?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: entity.data['stock']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: entity.data['category']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${LocaleKeys.editProduct.tr()}: ${entity.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'السعر'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'المخزون'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          FilledButton(
            onPressed: () {
              final data = {
                'price':
                    double.tryParse(priceController.text) ??
                    entity.data['price'],
                'stock':
                    int.tryParse(stockController.text) ?? entity.data['stock'],
                'category': categoryController.text.isNotEmpty
                    ? categoryController.text
                    : entity.data['category'],
              };
              _editProduct(entity, data);
              Navigator.pop(context);
            },
            child: Text(LocaleKeys.save.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.addProduct.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: LocaleKeys.productName.tr(),
              ),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'السعر'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'المخزون'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                _addLog('⚠️ ${LocaleKeys.fieldRequired.tr()}', isError: true);
                return;
              }

              final entity = LocalEntity(
                id: _generateId(),
                name: nameController.text,
                createdAt: DateTime.now(),
                data: {
                  'price': double.tryParse(priceController.text) ?? 0,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'category': categoryController.text.isNotEmpty
                      ? categoryController.text
                      : 'عام',
                },
                isSynced: _isOnline,
                hasPendingChanges: !_isOnline,
              );

              setState(() {
                _localStore.add(entity);
                _selectedEntity = entity;
              });

              _addLog(
                '➕ ${LocaleKeys.addedSuccessfully.tr()}: ${entity.name}',
                isSuccess: true,
              );
              _enqueue(entity, OperationType.create);

              Navigator.pop(context);
            },
            child: Text(LocaleKeys.add.tr()),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 3. واجهة المستخدم - تصميم احترافي
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stats = _getSyncStats();

    return Scaffold(
      backgroundColor: colors.bgPage,
      appBar: _buildAppBar(stats),
      body: SafeArea(
        child: Column(
          children: [
            _ConnectivityBar(
              isOnline: _isOnline,
              onToggle: _toggleConnectivity,
            ),
            _StatsBar(stats: stats),
            Expanded(child: _buildMainContent()),
            _LogView(logs: _logs),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(SyncStatistics stats) {
    final colors = context.colors;
    final text = context.textTheme;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.testSyncQueueTitle.tr(), style: text.headlineLarge),
          Text(
            '${_localStore.length} ${LocaleKeys.products.tr()} · ${stats.pendingTotal} ${LocaleKeys.pendingQueue.tr()} · ${stats.failed} ${LocaleKeys.failedQueue.tr()}',
            style: text.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
      backgroundColor: colors.bgCard,
      elevation: 0,
      actions: [
        if (stats.hasFailedItems)
          IconButton(
            onPressed: _retryFailed,
            icon: Stack(
              children: [
                const Icon(Icons.refresh_rounded),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.statusErrorFg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${stats.failed}',
                      style: text.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: LocaleKeys.retry.tr(),
          ),
        if (stats.pendingTotal > 0 || stats.hasFailedItems)
          IconButton(
            onPressed: _clearAllQueues,
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: LocaleKeys.clearAll.tr(),
          ),
      ],
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1300;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLocalEntitiesList()),
                const SizedBox(width: 12),
                Expanded(child: _buildPendingQueueView()),
                const SizedBox(width: 12),
                Expanded(child: _buildFailedQueueView()),
                const SizedBox(width: 12),
                Expanded(child: _buildServerView()),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              children: [
                SizedBox(height: 300, child: _buildLocalEntitiesList()),
                const SizedBox(height: 12),
                SizedBox(height: 260, child: _buildPendingQueueView()),
                const SizedBox(height: 12),
                SizedBox(height: 260, child: _buildFailedQueueView()),
                const SizedBox(height: 12),
                SizedBox(height: 300, child: _buildServerView()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalEntitiesList() {
    return _LocalEntitiesList(
      entities: _localStore,
      selectedEntity: _selectedEntity,
      onSelect: _showEntityDetails,
      onDelete: _deleteProduct,
      onAdd: _showAddDialog,
    );
  }

  Widget _buildPendingQueueView() {
    return _PendingQueueView(
      queue: _pendingQueue,
      isProcessing: _isProcessing,
      onClear: _clearPendingQueue,
    );
  }

  Widget _buildFailedQueueView() {
    return _FailedQueueView(
      queue: _failedQueue,
      onRetryAll: _retryFailed,
      onClear: _clearFailedQueue,
    );
  }

  Widget _buildServerView() {
    return _ServerView(serverEntities: _serverStore);
  }
}

// ============================================================================
// 4. المكونات - تصميم احترافي
// ============================================================================

/// شريط حالة الاتصال
class _ConnectivityBar extends StatelessWidget {
  const _ConnectivityBar({required this.isOnline, required this.onToggle});

  final bool isOnline;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOnline ? colors.statusSuccessBg : colors.statusErrorBg,
          border: Border(
            bottom: BorderSide(
              color: isOnline
                  ? colors.statusSuccessFg.withValues(alpha: 0.2)
                  : colors.statusErrorFg.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline ? colors.statusSuccessFg : colors.statusErrorFg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isOnline
                        ? colors.statusSuccessFg.withValues(alpha: 0.4)
                        : colors.statusErrorFg.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOnline
                    ? '🟢 ${LocaleKeys.connectionOnline.tr()}'
                    : '🔴 ${LocaleKeys.connectionOffline.tr()}',
                style: text.bodyMedium?.copyWith(
                  color: isOnline
                      ? colors.statusSuccessFg
                      : colors.statusErrorFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline
                    ? colors.statusSuccessFg.withValues(alpha: 0.1)
                    : colors.statusErrorFg.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOnline
                    ? LocaleKeys.tapToDisconnect.tr()
                    : LocaleKeys.tapToReconnect.tr(),
                style: text.bodySmall?.copyWith(
                  color: isOnline
                      ? colors.statusSuccessFg.withValues(alpha: 0.8)
                      : colors.statusErrorFg.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// إحصائيات المزامنة
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.stats});

  final SyncStatistics stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(bottom: BorderSide(color: colors.dividerSubtle)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _StatItem(
            label: LocaleKeys.syncStatusPending.tr(),
            count: stats.pending,
            color: colors.textSecondary,
          ),
          _StatItem(
            label: LocaleKeys.syncStatusProcessing.tr(),
            count: stats.processing,
            color: colors.statusWarningFg,
          ),
          _StatItem(
            label: LocaleKeys.syncStatusOffline.tr(),
            count: stats.offline,
            color: colors.textMuted,
          ),
          _StatItem(
            label: LocaleKeys.syncStatusFailed.tr(),
            count: stats.failed,
            color: colors.statusErrorFg,
          ),
          _StatItem(
            label: LocaleKeys.syncStatusSynced.tr(),
            count: stats.syncedCount,
            color: colors.statusSuccessFg,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: text.bodySmall?.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

/// قائمة المنتجات المحلية
class _LocalEntitiesList extends StatelessWidget {
  const _LocalEntitiesList({
    required this.entities,
    required this.selectedEntity,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  final List<LocalEntity> entities;
  final LocalEntity? selectedEntity;
  final Function(LocalEntity) onSelect;
  final Function(LocalEntity) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return _CardContainer(
      icon: Icons.storage_rounded,
      title: LocaleKeys.localStorage.tr(),
      subtitle: '${entities.length} ${LocaleKeys.items.tr()}',
      child: Column(
        children: [
          Expanded(
            child: entities.isEmpty
                ? Center(
                    child: Text(
                      LocaleKeys.noItems.tr(),
                      style: text.bodyMedium?.copyWith(color: colors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: entities.length,
                    itemBuilder: (context, index) {
                      final entity = entities[index];
                      final isSelected = entity == selectedEntity;

                      return _EntityCard(
                        entity: entity,
                        isSelected: isSelected,
                        onTap: () => onSelect(entity),
                        onDelete: () => onDelete(entity),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(LocaleKeys.addProduct.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة المنتج
class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.entity,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final LocalEntity entity;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? colors.primary.withValues(alpha: 0.08) : null,
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: entity.isSynced
                ? colors.statusSuccessBg
                : colors.statusWarningBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            entity.isSynced
                ? Icons.cloud_done_rounded
                : entity.hasPendingChanges
                ? Icons.cloud_queue_rounded
                : Icons.cloud_off_rounded,
            color: entity.isSynced
                ? colors.statusSuccessFg
                : colors.statusWarningFg,
          ),
        ),
        title: Text(
          entity.name,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${LocaleKeys.productPrice.tr()}: ${entity.data['price']} · ${LocaleKeys.productStock.tr()}: ${entity.data['stock']}',
          style: text.bodySmall?.copyWith(color: colors.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_rounded, color: colors.statusErrorFg),
          onPressed: onDelete,
          tooltip: LocaleKeys.delete.tr(),
        ),
        isThreeLine: false,
        dense: true,
        horizontalTitleGap: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

/// طابور المعلَّقات — العمليات التي ستُنفَّذ فور توفر الاتصال، تتفرّغ تلقائياً بعد النجاح
class _PendingQueueView extends StatelessWidget {
  const _PendingQueueView({
    required this.queue,
    required this.isProcessing,
    required this.onClear,
  });

  final List<PendingSyncItem> queue;
  final bool isProcessing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return _CardContainer(
      icon: Icons.queue_rounded,
      title: LocaleKeys.pendingQueue.tr(),
      subtitle: '${queue.length} ${LocaleKeys.items.tr()}',
      trailing: isProcessing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.statusWarningFg,
              ),
            )
          : null,
      actions: [
        if (queue.isNotEmpty)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: LocaleKeys.clearQueue.tr(),
          ),
      ],
      child: queue.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: colors.statusSuccessFg.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.syncQueueEmpty.tr(),
                    style: text.bodyMedium?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: queue.length,
              itemBuilder: (context, index) => _PendingItemCard(item: queue[index]),
            ),
    );
  }
}

/// طابور الأخطاء — عمليات فشل تنفيذها وتحتاج تدخلاً (إعادة محاولة أو تجاهل)
class _FailedQueueView extends StatelessWidget {
  const _FailedQueueView({
    required this.queue,
    required this.onRetryAll,
    required this.onClear,
  });

  final List<FailedSyncItem> queue;
  final VoidCallback onRetryAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return _CardContainer(
      icon: Icons.error_outline_rounded,
      title: LocaleKeys.failedQueue.tr(),
      subtitle: '${queue.length} ${LocaleKeys.items.tr()}',
      actions: [
        if (queue.isNotEmpty) ...[
          IconButton(
            onPressed: onRetryAll,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: LocaleKeys.retry.tr(),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: LocaleKeys.clearQueue.tr(),
          ),
        ],
      ],
      child: queue.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 48,
                    color: colors.statusSuccessFg.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.noFailedItems.tr(),
                    style: text.bodyMedium?.copyWith(color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: queue.length,
              itemBuilder: (context, index) => _FailedItemCard(item: queue[index]),
            ),
    );
  }
}

/// عنصر في طابور المعلَّقات
class _PendingItemCard extends StatelessWidget {
  const _PendingItemCard({required this.item});

  final PendingSyncItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    final statusColors = {
      PendingItemStatus.pending: colors.textSecondary,
      PendingItemStatus.processing: colors.statusWarningFg,
      PendingItemStatus.offline: colors.textMuted,
    };

    final statusIcons = {
      PendingItemStatus.pending: Icons.hourglass_empty_rounded,
      PendingItemStatus.processing: Icons.sync_rounded,
      PendingItemStatus.offline: Icons.wifi_off_rounded,
    };

    final statusLabels = {
      PendingItemStatus.pending: LocaleKeys.syncStatusPending.tr(),
      PendingItemStatus.processing: LocaleKeys.syncStatusProcessing.tr(),
      PendingItemStatus.offline: LocaleKeys.syncStatusOffline.tr(),
    };

    final typeLabels = {
      OperationType.create: LocaleKeys.add.tr(),
      OperationType.update: LocaleKeys.editProduct.tr(),
      OperationType.delete: LocaleKeys.delete.tr(),
    };

    final statusColor = statusColors[item.status] ?? colors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Icon(statusIcons[item.status], size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${typeLabels[item.type]}',
                      style: text.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.entityName,
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (item.attempts > 0)
                  Text(
                    '${LocaleKeys.attempts.tr()}: ${item.attempts}',
                    style: text.labelSmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusLabels[item.status] ?? '',
              style: text.labelSmall?.copyWith(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر في طابور الأخطاء
class _FailedItemCard extends StatelessWidget {
  const _FailedItemCard({required this.item});

  final FailedSyncItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    final typeLabels = {
      OperationType.create: LocaleKeys.add.tr(),
      OperationType.update: LocaleKeys.editProduct.tr(),
      OperationType.delete: LocaleKeys.delete.tr(),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.statusErrorBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.statusErrorFg.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_rounded, size: 16, color: colors.statusErrorFg),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${typeLabels[item.type]}',
                      style: text.labelSmall?.copyWith(
                        color: colors.statusErrorFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.entityName,
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  item.error,
                  style: text.labelSmall?.copyWith(
                    color: colors.statusErrorFg,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${LocaleKeys.attempts.tr()}: ${item.attempts}',
                  style: text.labelSmall?.copyWith(
                    color: colors.textMuted,
                    fontSize: 9,
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

/// عرض السيرفر
class _ServerView extends StatelessWidget {
  const _ServerView({required this.serverEntities});

  final List<ServerEntity> serverEntities;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return _CardContainer(
      icon: Icons.cloud_rounded,
      title: LocaleKeys.serverState.tr(),
      subtitle: '${serverEntities.length} ${LocaleKeys.items.tr()}',
      child: serverEntities.isEmpty
          ? Center(
              child: Text(
                LocaleKeys.noItems.tr(),
                style: text.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: serverEntities.length,
              itemBuilder: (context, index) {
                final entity = serverEntities[index];
                return _ServerCard(entity: entity);
              },
            ),
    );
  }
}

/// بطاقة السيرفر
class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.entity});

  final ServerEntity entity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.statusSuccessBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.cloud_done_rounded,
            color: colors.statusSuccessFg,
            size: 16,
          ),
        ),
        title: Text(
          entity.name,
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'v${entity.version} · ${entity.data['price']}',
          style: text.bodySmall?.copyWith(
            color: colors.textMuted,
            fontSize: 10,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.statusSuccessBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            LocaleKeys.syncStatusSynced.tr(),
            style: text.labelSmall?.copyWith(
              color: colors.statusSuccessFg,
              fontSize: 8,
            ),
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}

/// حاوية البطاقات
class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: colors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: text.titleSmall?.copyWith(color: colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(color: colors.textMuted),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ...actions,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// سجل الأحداث
class _LogView extends StatelessWidget {
  const _LogView({required this.logs});

  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;

    return Container(
      height: 120,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              LocaleKeys.eventLog.tr(),
              style: text.titleSmall?.copyWith(color: colors.textPrimary),
            ),
          ),
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      LocaleKeys.noEventsYet.tr(),
                      style: text.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final time = log['time'] as DateTime;
                      final message = log['message'] as String;
                      final isError = log['isError'] as bool? ?? false;
                      final isSuccess = log['isSuccess'] as bool? ?? false;
                      final isInfo = log['isInfo'] as bool? ?? false;

                      final color = isError
                          ? colors.statusErrorFg
                          : isSuccess
                          ? colors.statusSuccessFg
                          : isInfo
                          ? colors.textSecondary
                          : colors.textMuted;

                      final icon = isError
                          ? Icons.error_outline_rounded
                          : isSuccess
                          ? Icons.check_circle_outline_rounded
                          : isInfo
                          ? Icons.info_outline_rounded
                          : null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Text(
                              '[${_hhmmss(time)}]',
                              style: text.bodySmall?.copyWith(
                                color: colors.textMuted,
                                fontFamily: 'monospace',
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (icon != null) ...[
                              Icon(icon, size: 12, color: color),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                message,
                                style: text.bodySmall?.copyWith(
                                  color: color,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _hhmmss(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';
