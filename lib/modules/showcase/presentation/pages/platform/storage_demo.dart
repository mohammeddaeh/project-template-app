import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/infra/network/interceptors/request_cache_interceptor.dart';
import 'package:app_template/core/platform/config/app_settings.dart';
import 'package:app_template/core/platform/storage/adapters/in_memory_storage_adapter.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// [StorageService] driven by hand — on the template's own
/// [InMemoryStorageAdapter], so every call is the real interface and the
/// app's own store (the one in DI) is never touched.
class StorageDemo extends StatefulWidget {
  const StorageDemo({super.key});

  @override
  State<StorageDemo> createState() => _StorageDemoState();
}

enum _Kind {
  string('String'),
  boolean('bool'),
  integer('int'),
  decimal('double'),
  list('List<String>');

  const _Kind(this.code);

  final String code;

  String get writer => switch (this) {
    string => 'writeString',
    boolean => 'writeBool',
    integer => 'writeInt',
    decimal => 'writeDouble',
    list => 'writeStringList',
  };

  String get reader => writer.replaceFirst('write', 'read');
}

/// The keys a project ships with, each with the type its readers expect.
const _known = <String, (String, _Kind)>{
  PersistenceKeys.welcomeSeen: ('welcomeSeen', _Kind.boolean),
  PersistenceKeys.notificationsEnabled: ('notificationsEnabled', _Kind.boolean),
  PersistenceKeys.selectedFontKey: ('selectedFontKey', _Kind.string),
  PersistenceKeys.selectedThemePresetKey: (
    'selectedThemePresetKey',
    _Kind.string,
  ),
  PersistenceKeys.navLastTabIndex: ('navLastTabIndex', _Kind.integer),
  PersistenceKeys.deviceId: ('deviceId', _Kind.string),
  PersistenceKeys.dataOrigin: ('dataOrigin', _Kind.string),
};

/// What the HTTP cache prefixes its keys with (`RequestCacheInterceptor`).
const _cachePrefix = '__http_cache__';

class _StorageDemoState extends State<StorageDemo> {
  final StorageService _storage = InMemoryStorageAdapter();

  /// The type each key was written with — the store itself does not say.
  final _types = <String, _Kind>{};
  Map<String, String> _contents = const {};

  // The playground.
  String? _key = PersistenceKeys.navLastTabIndex; // null = a custom key
  _Kind _kind = _Kind.integer;
  final _customKey = TextEditingController(text: 'my_feature_flag');
  final _value = TextEditingController(text: '2');
  String? _lastCall;
  String? _lastResult;
  bool _lastFailed = false;

  // The settings screen.
  bool _notifications = false;
  bool _welcomeSeen = false;
  String _font = AppFonts.available.first.key;
  int _tab = 0;
  List<String> _restored = const [];

  String get _rawKey => _key ?? _customKey.text.trim();

  String get _keyCode =>
      _key == null ? "'$_rawKey'" : 'PersistenceKeys.${_known[_key]!.$1}';

  @override
  void dispose() {
    _customKey.dispose();
    _value.dispose();
    super.dispose();
  }

  // ── Store access ──────────────────────────────────────────────────────────

  Future<Object?> _read(String key, _Kind kind) => switch (kind) {
    _Kind.string => _storage.readString(key),
    _Kind.boolean => _storage.readBool(key),
    _Kind.integer => _storage.readInt(key),
    _Kind.decimal => _storage.readDouble(key),
    _Kind.list => _storage.readStringList(key),
  };

  Future<void> _write(String key, _Kind kind, Object value) async {
    switch (kind) {
      case _Kind.string:
        await _storage.writeString(key, value as String);
      case _Kind.boolean:
        await _storage.writeBool(key, value: value as bool);
      case _Kind.integer:
        await _storage.writeInt(key, value as int);
      case _Kind.decimal:
        await _storage.writeDouble(key, value as double);
      case _Kind.list:
        await _storage.writeStringList(key, value as List<String>);
    }
    _types[key] = kind;
  }

  /// Re-reads every key the store holds — after each call, so the table is
  /// what the store says, not what this page remembers writing.
  Future<void> _refresh() async {
    final next = <String, String>{};
    for (final key in _storage.keys()) {
      final kind = _types[key] ?? _Kind.string;
      next[key] = '${_show(await _read(key, kind))}  ·  ${kind.code}';
    }
    _types.removeWhere((k, _) => !next.containsKey(k));
    if (mounted) setState(() => _contents = next);
  }

  static String _show(Object? v) => switch (v) {
    null => 'null',
    String() => "'$v'",
    List() => '[${v.map((e) => "'$e'").join(', ')}]',
    _ => '$v',
  };

  Object? _parse(String text) => switch (_kind) {
    _Kind.string => text,
    _Kind.boolean => bool.tryParse(text.trim()),
    _Kind.integer => int.tryParse(text.trim()),
    _Kind.decimal => double.tryParse(text.trim()),
    _Kind.list => [
      for (final s in text.split(','))
        if (s.trim().isNotEmpty) s.trim(),
    ],
  };

  Future<void> _run(String call, Future<Object?> Function() body) async {
    setState(() {
      _lastCall = call;
      _lastResult = null;
    });
    try {
      final result = await body();
      _lastFailed = false;
      _lastResult = result is _Silent ? null : '→ ${_show(result)}';
    } catch (e) {
      // A read with the wrong type throws in every adapter — the type is part
      // of the key's contract. Shown, not hidden.
      _lastFailed = true;
      _lastResult = '✕ $e';
    }
    await _refresh();
  }

  Future<void> _onWrite() async {
    final key = _rawKey;
    if (key.isEmpty) return;
    final value = _parse(_value.text);
    if (value == null) {
      setState(() {
        _lastCall = null;
        _lastFailed = true;
        _lastResult = LocaleKeys.showcaseStorageBadValue.tr(args: [_kind.code]);
      });
      return;
    }
    final arg = _kind == _Kind.boolean ? 'value: $value' : _show(value);
    await _run('await storage.${_kind.writer}($_keyCode, $arg);', () async {
      await _write(key, _kind, value);
      return const _Silent();
    });
  }

  void _pickKey(String? key) {
    setState(() {
      _key = key;
      if (key != null) _kind = _known[key]!.$2;
    });
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> _setting<T extends Object>(
    String key,
    _Kind kind,
    T value,
    void Function(T) apply,
  ) async {
    setState(() => apply(value));
    await _write(key, kind, value);
    await _refresh();
  }

  Future<void> _restart() async {
    // A fresh screen starts from its defaults, then asks the store.
    setState(() {
      _notifications = false;
      _welcomeSeen = false;
      _font = AppFonts.available.first.key;
      _tab = 0;
      _restored = const [];
    });
    final notifications = await _storage.readBool(
      PersistenceKeys.notificationsEnabled,
    );
    final welcome = await _storage.readBool(PersistenceKeys.welcomeSeen);
    final font = await _storage.readString(PersistenceKeys.selectedFontKey);
    final tab = await _storage.readInt(PersistenceKeys.navLastTabIndex);
    if (!mounted) return;
    setState(() {
      _notifications = notifications ?? false;
      _welcomeSeen = welcome ?? false;
      _font = font ?? AppFonts.available.first.key;
      _tab = tab ?? 0;
      _restored = [
        'readBool(PersistenceKeys.notificationsEnabled) → ${_show(notifications)}',
        'readBool(PersistenceKeys.welcomeSeen) → ${_show(welcome)}',
        'readString(PersistenceKeys.selectedFontKey) → ${_show(font)}',
        'readInt(PersistenceKeys.navLastTabIndex) → ${_show(tab)}',
      ];
    });
  }

  // ── HTTP cache namespace ──────────────────────────────────────────────────

  Future<void> _cacheSome() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final page in [1, 2, 3]) {
      await _write(
        '$_cachePrefix/items?page=$page',
        _Kind.string,
        jsonEncode({
          'data': {'page': page},
          'cachedAt': now,
        }),
      );
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final cache = RequestCacheInterceptor(_storage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Note(LocaleKeys.showcaseStorageAdapterNote.tr()),
        DemoBlock(
          code: 'final StorageService storage = InMemoryStorageAdapter();',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Label(LocaleKeys.showcaseStorageKey.tr()),
              Directionality(
                textDirection: TextDirection.ltr,
                child: ChipRow<String?>(
                  items: [..._known.keys, null],
                  labelResolver: (k) => k == null
                      ? LocaleKeys.showcaseStorageCustomKey.tr()
                      : _known[k]!.$1,
                  selectedValue: _key,
                  scrollable: false,
                  onSelected: _pickKey,
                ),
              ),
              if (_key == null) ...[
                12.heightBox,
                CustomTextField(
                  controller: _customKey,
                  labelText: LocaleKeys.showcaseStorageKey.tr(),
                  ltr: true,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              12.heightBox,
              _Label(LocaleKeys.showcaseStorageType.tr()),
              Directionality(
                textDirection: TextDirection.ltr,
                child: ChipRow<_Kind>(
                  items: _Kind.values,
                  labelResolver: (k) => k.code,
                  selectedValue: _kind,
                  scrollable: false,
                  onSelected: (k) => setState(() => _kind = k ?? _kind),
                ),
              ),
              12.heightBox,
              CustomTextField(
                controller: _value,
                labelText: LocaleKeys.showcaseStorageValue.tr(),
                hint: 'true · 42 · 1.5 · a, b, c',
                ltr: true,
              ),
              12.heightBox,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton(
                    text: LocaleKeys.showcaseStorageWrite.tr(),
                    size: AppButtonSize.small,
                    leadingIcon: Icons.save_outlined,
                    onTap: _onWrite,
                  ),
                  AppButton(
                    text: LocaleKeys.showcaseStorageRead.tr(),
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.tonal,
                    onTap: () => _run(
                      'await storage.${_kind.reader}($_keyCode);',
                      () => _read(_rawKey, _kind),
                    ),
                  ),
                  AppButton(
                    text: 'containsKey',
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.tonal,
                    onTap: () => _run(
                      'storage.containsKey($_keyCode);',
                      () async => _storage.containsKey(_rawKey),
                    ),
                  ),
                  AppButton(
                    text: LocaleKeys.showcaseStorageDelete.tr(),
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.outlined,
                    onTap: () =>
                        _run('await storage.delete($_keyCode);', () async {
                          await _storage.delete(_rawKey);
                          return const _Silent();
                        }),
                  ),
                ],
              ),
              if (_lastCall != null || _lastResult != null) ...[
                12.heightBox,
                _CallBox(
                  call: _lastCall,
                  result: _lastResult,
                  failed: _lastFailed,
                ),
              ],
              16.heightBox,
              _Label(LocaleKeys.showcaseStorageContents.tr()),
              _ContentsTable(_contents),
            ],
          ),
        ),
        DemoBlock(
          code:
              'await storage.writeBool(\n'
              '  PersistenceKeys.notificationsEnabled, value: v);',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Note(LocaleKeys.showcaseStorageSettingsIntro.tr()),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(LocaleKeys.notifications.tr()),
                value: _notifications,
                onChanged: (v) => _setting(
                  PersistenceKeys.notificationsEnabled,
                  _Kind.boolean,
                  v,
                  (v) => _notifications = v,
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(LocaleKeys.showcaseStorageWelcomeSeen.tr()),
                value: _welcomeSeen,
                onChanged: (v) => _setting(
                  PersistenceKeys.welcomeSeen,
                  _Kind.boolean,
                  v,
                  (v) => _welcomeSeen = v,
                ),
              ),
              8.heightBox,
              _Label(LocaleKeys.showcaseStorageFont.tr()),
              ChipRow<AppFontOption>(
                items: AppFonts.available,
                labelResolver: (f) => context.locale.languageCode == 'ar'
                    ? f.arabicLabel
                    : f.latinLabel,
                selectedValue: AppFonts.byKey(_font),
                scrollable: false,
                onSelected: (f) {
                  if (f == null) return;
                  _setting(
                    PersistenceKeys.selectedFontKey,
                    _Kind.string,
                    f.key,
                    (v) => _font = v,
                  );
                },
              ),
              12.heightBox,
              _Label(LocaleKeys.showcaseStorageLastTab.tr()),
              ChipRow<int>(
                items: const [0, 1, 2, 3],
                labelResolver: (i) => '$i',
                selectedValue: _tab,
                scrollable: false,
                onSelected: (i) {
                  if (i == null) return;
                  _setting(
                    PersistenceKeys.navLastTabIndex,
                    _Kind.integer,
                    i,
                    (v) => _tab = v,
                  );
                },
              ),
              16.heightBox,
              AppButton(
                text: LocaleKeys.showcaseStorageRestart.tr(),
                variant: AppButtonVariant.tonal,
                leadingIcon: Icons.restart_alt,
                onTap: _restart,
              ),
              if (_restored.isNotEmpty) ...[
                12.heightBox,
                _CallBox(call: _restored.join('\n'), result: null),
              ],
            ],
          ),
        ),
        DemoBlock(
          code:
              'storage.keys().where((k) => k.startsWith(prefix))\n'
              '  → storage.delete(k)   // never storage.clear()',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Note(LocaleKeys.showcaseStorageCacheIntro.tr()),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      text: LocaleKeys.showcaseStorageCacheAdd.tr(),
                      size: AppButtonSize.small,
                      leadingIcon: Icons.add,
                      onTap: _cacheSome,
                    ),
                    AppButton(
                      text: "invalidate('/items', page: 2)",
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.tonal,
                      onTap: () => _run("await cache.invalidate('/items', "
                          "queryParameters: {'page': 2});", () async {
                        await cache.invalidate(
                          '/items',
                          queryParameters: {'page': 2},
                        );
                        return const _Silent();
                      }),
                    ),
                    AppButton(
                      text: 'invalidateAll()',
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.tonal,
                      onTap: () =>
                          _run('await cache.invalidateAll();', () async {
                            await cache.invalidateAll();
                            return const _Silent();
                          }),
                    ),
                    AppButton(
                      text: 'storage.clear()',
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.outlined,
                      leadingIcon: Icons.warning_amber_rounded,
                      onTap: () => _run('await storage.clear();', () async {
                        await _storage.clear();
                        return const _Silent();
                      }),
                    ),
                  ],
                ),
              ),
              12.heightBox,
              Text(
                LocaleKeys.showcaseStorageContentsAbove.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'AppSettings.enableLogging · AppSettings.enableBlocObserverLogger',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Note(LocaleKeys.showcaseStorageFlagsIntro.tr()),
              _CallBox(
                call:
                    'AppSettings.enableLogging = '
                    '${AppSettings.enableLogging}\n'
                    'AppSettings.enableBlocObserverLogger = '
                    '${AppSettings.enableBlocObserverLogger}',
                result: null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A call that returns nothing worth printing.
class _Silent {
  const _Silent();
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: context.colors.textMuted),
        8.widthBox,
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: context.textTheme.labelMedium),
  );
}

/// The call just made and what it returned, as code.
class _CallBox extends StatelessWidget {
  const _CallBox({
    required this.call,
    required this.result,
    this.failed = false,
  });

  final String? call;
  final String? result;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: 12.allPadding,
        decoration: BoxDecoration(
          color: colors.bgNeutral,
          borderRadius: AppRadius.smRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (call != null)
              Text(call!, style: style?.copyWith(color: colors.textSecondary)),
            if (result != null) ...[
              if (call != null) 4.heightBox,
              Text(
                result!,
                style: style?.copyWith(
                  color: failed ? colors.error : colors.statusSuccessFg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContentsTable extends StatelessWidget {
  const _ContentsTable(this.contents);

  final Map<String, String> contents;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (contents.isEmpty) {
      return Text(
        LocaleKeys.showcaseStorageEmpty.tr(),
        style: context.textTheme.bodySmall?.copyWith(color: colors.textMuted),
      );
    }
    final style = context.textTheme.bodySmall;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in contents.entries)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.dividerSubtle)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      e.key,
                      style: style?.copyWith(color: colors.primary),
                    ),
                  ),
                  8.widthBox,
                  Expanded(
                    flex: 6,
                    child: Text(
                      e.value,
                      style: style?.copyWith(color: colors.textSecondary),
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
