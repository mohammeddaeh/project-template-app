import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

class FontPreferenceCubit extends SafeCubit<AppFontOption> {
  FontPreferenceCubit(this._storage, {AppFontOption? initial})
      : super(initial ?? AppFonts.available.first);

  final StorageService _storage;

  Future<void> setFont(AppFontOption font) async {
    await _storage.writeString(PersistenceKeys.selectedFontKey, font.key);
    emit(font);
  }
}
