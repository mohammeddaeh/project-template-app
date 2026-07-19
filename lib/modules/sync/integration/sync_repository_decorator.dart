import 'package:get_it/get_it.dart';

abstract class SyncRepositoryDecorator {
  Future<void> decorate(GetIt getIt);
}
