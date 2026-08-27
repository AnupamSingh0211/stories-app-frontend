import 'dart:async';

import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/favorite_stories_provider.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const story = StoryModel(
    id: 'story-1',
    title: 'Kanha Ki Sunheri Subah',
    thumbnailUrl: 'https://example.test/story.webp',
    category: 'Krishna Stories',
    durationMinutes: 3,
  );
  const storyCard = StoryCardModel(
    id: 'card-1',
    title: 'Krishna Stories',
    thumbnailUrl: 'https://example.test/card.webp',
    heroBannerUrl: 'https://example.test/card-hero.webp',
    category: 'Story',
    sortOrder: 1,
  );

  test(
    'addStory rolls back local state when repository insert fails',
    () async {
      final notifier = FavoriteStoriesNotifier(
        const _FailingFavoriteStoryRepository(addMessage: 'Insert failed.'),
        profileId: '11111111-1111-4111-8111-111111111111',
      );

      await expectLater(
        notifier.addStory(story),
        throwsA(
          isA<StoryRepositoryException>().having(
            (error) => error.message,
            'message',
            'Insert failed.',
          ),
        ),
      );

      expect(notifier.state, isEmpty);
    },
  );

  test(
    'removeStory rolls back local state when repository delete fails',
    () async {
      final notifier = FavoriteStoriesNotifier(
        const _FailingFavoriteStoryRepository(removeMessage: 'Delete failed.'),
        profileId: '11111111-1111-4111-8111-111111111111',
      );
      notifier.state = const [story];

      await expectLater(
        notifier.removeStory(story.id),
        throwsA(
          isA<StoryRepositoryException>().having(
            (error) => error.message,
            'message',
            'Delete failed.',
          ),
        ),
      );

      expect(notifier.state, const [story]);
    },
  );

  test(
    'duplicate addStory while pending does not duplicate local state',
    () async {
      final repository = _PendingFavoriteStoryRepository();
      final notifier = FavoriteStoriesNotifier(
        repository,
        profileId: '11111111-1111-4111-8111-111111111111',
      );

      final firstAdd = notifier.addStory(story);
      final secondAdd = notifier.addStory(story);

      expect(notifier.state, const [story]);
      expect(repository.addCalls, 1);

      repository.completeAdd();
      await Future.wait([firstAdd, secondAdd]);

      expect(notifier.state, const [story]);
      expect(repository.addCalls, 1);
    },
  );

  test(
    'addStoryCard rolls back local state when repository insert fails',
    () async {
      final notifier = FavoriteStoryCardsNotifier(
        const _FailingFavoriteStoryRepository(
          addCardMessage: 'Card insert failed.',
        ),
        profileId: '11111111-1111-4111-8111-111111111111',
      );

      await expectLater(
        notifier.addStoryCard(storyCard),
        throwsA(
          isA<StoryRepositoryException>().having(
            (error) => error.message,
            'message',
            'Card insert failed.',
          ),
        ),
      );

      expect(notifier.state, isEmpty);
    },
  );

  test(
    'duplicate addStoryCard while pending does not duplicate local state',
    () async {
      final repository = _PendingFavoriteStoryRepository();
      final notifier = FavoriteStoryCardsNotifier(
        repository,
        profileId: '11111111-1111-4111-8111-111111111111',
      );

      final firstAdd = notifier.addStoryCard(storyCard);
      final secondAdd = notifier.addStoryCard(storyCard);

      expect(notifier.state, const [storyCard]);
      expect(repository.addCardCalls, 1);

      repository.completeCardAdd();
      await Future.wait([firstAdd, secondAdd]);

      expect(notifier.state, const [storyCard]);
      expect(repository.addCardCalls, 1);
    },
  );
}

class _FailingFavoriteStoryRepository extends StoryRepository {
  const _FailingFavoriteStoryRepository({
    this.addMessage,
    this.removeMessage,
    this.addCardMessage,
  });

  final String? addMessage;
  final String? removeMessage;
  final String? addCardMessage;

  @override
  Future<void> addFavoriteStory(String storyId, {String? profileId}) async {
    throw StoryRepositoryException(addMessage ?? 'Favorite add failed.');
  }

  @override
  Future<void> removeFavoriteStory(String storyId, {String? profileId}) async {
    throw StoryRepositoryException(removeMessage ?? 'Favorite remove failed.');
  }

  @override
  Future<void> addFavoriteStoryCard(
    String storyCardId, {
    String? profileId,
  }) async {
    throw StoryRepositoryException(
      addCardMessage ?? 'Favorite story card add failed.',
    );
  }
}

class _PendingFavoriteStoryRepository extends StoryRepository {
  final Completer<void> _addCompleter = Completer<void>();
  final Completer<void> _addCardCompleter = Completer<void>();
  int addCalls = 0;
  int addCardCalls = 0;

  @override
  Future<void> addFavoriteStory(String storyId, {String? profileId}) {
    addCalls++;
    return _addCompleter.future;
  }

  void completeAdd() {
    _addCompleter.complete();
  }

  @override
  Future<void> addFavoriteStoryCard(String storyCardId, {String? profileId}) {
    addCardCalls++;
    return _addCardCompleter.future;
  }

  void completeCardAdd() {
    _addCardCompleter.complete();
  }
}
