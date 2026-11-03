import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/platform/storage/adapters/in_memory_storage_adapter.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/features/settings/presentation/cubits/theme_preset_cubit.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';

void main() {
  test('every preset id is unique — the id is what storage keeps', () {
    final ids = AppThemePresets.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('an unknown or missing stored id falls back, never throws', () {
    expect(AppThemePresets.byId(null), AppThemePresets.fallback);
    expect(AppThemePresets.byId('removed-preset'), AppThemePresets.fallback);
  });

  test('choosing a preset persists its id and emits it', () async {
    final storage = InMemoryStorageAdapter();
    final cubit = ThemePresetCubit(storage);
    final preset = AppThemePresets.all.last;

    await cubit.setPreset(preset);

    expect(cubit.state, preset);
    expect(
      await storage.readString(PersistenceKeys.selectedThemePresetKey),
      preset.id,
    );
    await cubit.close();
  });
}
