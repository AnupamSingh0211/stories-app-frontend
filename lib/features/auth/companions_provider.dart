import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'companion_model.dart';
import 'companion_repository.dart';

part 'companions_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<CompanionModel>> companions(CompanionsRef ref) {
  return const CompanionRepository().fetchCompanions();
}
