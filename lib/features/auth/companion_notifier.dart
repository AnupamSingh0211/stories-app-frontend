import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'companion_model.dart';

part 'companion_notifier.g.dart';

@Riverpod(keepAlive: true)
class CompanionNotifier extends _$CompanionNotifier {
  @override
  CompanionModel? build() {
    return null;
  }

  void selectCompanion(CompanionModel companion) {
    state = companion;
  }

  bool get hasSelected => state != null;
}
