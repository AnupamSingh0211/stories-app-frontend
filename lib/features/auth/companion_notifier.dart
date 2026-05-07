import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'companion_notifier.g.dart';

@riverpod
class CompanionNotifier extends _$CompanionNotifier {
  @override
  String build() {
    return '';
  }

  void selectCompanion(String name) {
    state = name;
  }

  bool get hasSelected => state.isNotEmpty;
}
