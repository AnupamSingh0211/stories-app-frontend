import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story_model.dart';
import 'story_repository.dart';

final storytimeContentProvider = FutureProvider<StorytimeContent>((ref) {
  return const StoryRepository().fetchStorytimeContent();
});
