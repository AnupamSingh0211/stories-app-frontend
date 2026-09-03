import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend_api_client.dart';

class NotificationTokenRepository {
  const NotificationTokenRepository({required BackendApiClient apiClient})
    : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<void> registerAndroidToken({
    required String token,
    String appVersion = '1.0.0',
    String locale = 'en-IN',
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return;
    }

    await _apiClient.postObject(
      '/api/v1/user-notification-tokens',
      authenticated: true,
      body: stripClientOwnershipFields({
        'token': trimmedToken,
        'platform': 'android',
        'app_version': appVersion,
        'locale': locale,
      }),
    );
  }
}

final notificationTokenRepositoryProvider =
    Provider<NotificationTokenRepository>((ref) {
      return NotificationTokenRepository(
        apiClient: ref.watch(backendApiClientProvider),
      );
    });

Future<bool> syncAndroidNotificationToken({
  required NotificationTokenRepository repository,
  required String token,
}) async {
  try {
    await repository.registerAndroidToken(token: token);
    debugPrint('NotificationTokenRepository: FCM token synced to backend.');
    return true;
  } on BackendApiException catch (error) {
    debugPrint(
      'NotificationTokenRepository: backend token sync failed. $error',
    );
  } catch (error) {
    debugPrint('NotificationTokenRepository: token sync failed. $error');
  }

  return false;
}
