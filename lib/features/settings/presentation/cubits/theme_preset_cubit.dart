import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';

class ThemePresetCubit extends SafeCubit<AppThemePreset> {
  ThemePresetCubit(this._storage, {AppThemePreset? initial})
    : super(initial ?? AppThemePresets.fallback);

  final StorageService _storage;

  Future<void> setPreset(AppThemePreset preset) async {
    await _storage.writeString(
      PersistenceKeys.selectedThemePresetKey,
      preset.id,
    );
    emit(preset);
  }
}
