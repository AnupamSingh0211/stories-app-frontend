import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dharma_app/features/auth/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('appAuthServiceProvider', () {
    test('uses backend dev OTP auth when enabled for development APKs', () {
      dotenv.testLoad(
        fileInput: '''
APP_ENV=development
DEV_AUTH_OTP_ENABLED=true
BACKEND_BASE_URL=http://192.168.29.180:5000
''',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(appAuthServiceProvider),
        isA<DevBackendOtpAuthService>(),
      );
    });

    test('does not enable backend dev OTP auth in production', () {
      dotenv.testLoad(
        fileInput: '''
APP_ENV=production
DEV_AUTH_OTP_ENABLED=true
BACKEND_BASE_URL=https://api.example.com
''',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(appAuthServiceProvider),
        isA<SupabaseAppAuthService>(),
      );
    });
  });

  group('DevBackendOtpAuthService', () {
    test(
      'requestOtp does not call backend in temporary dev auth mode',
      () async {
        dotenv.testLoad(
          fileInput: '''
APP_ENV=development
DEV_AUTH_OTP_ENABLED=true
BACKEND_BASE_URL=http://dev-api.example.test
''',
        );
        final container = ProviderContainer();
        addTearDown(container.dispose);
        var backendCalls = 0;
        final authServiceProvider = Provider(
          (ref) => DevBackendOtpAuthService(
            ref,
            client: MockClient((request) async {
              backendCalls++;
              return http.Response('{}', 500);
            }),
          ),
        );
        final authService = container.read(authServiceProvider);

        await authService.requestOtp('+911234567890');

        expect(backendCalls, 0);
      },
    );

    test('verifyOtp sends phone and hardcoded OTP to backend', () async {
      dotenv.testLoad(
        fileInput: '''
APP_ENV=development
DEV_AUTH_OTP_ENABLED=true
BACKEND_BASE_URL=http://dev-api.example.test
''',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final requests = <http.Request>[];
      final authServiceProvider = Provider(
        (ref) => DevBackendOtpAuthService(
          ref,
          client: MockClient((request) async {
            requests.add(request);
            return http.Response(
              '''
{
  "success": true,
  "data": {
    "userId": "e40881ba-c08b-4112-8562-7940db45d096",
    "accessToken": "signed-dev-jwt"
  }
}
''',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final authService = container.read(authServiceProvider);

      final identity = await authService.verifyOtp(
        phoneNumber: '+911234567890',
        otp: '123456',
      );

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/api/v1/auth/dev/verify-otp');
      expect(requests.single.body, contains('"phoneNumber":"+911234567890"'));
      expect(requests.single.body, contains('"otp":"123456"'));
      expect(identity.userId, 'e40881ba-c08b-4112-8562-7940db45d096');
      expect(identity.accessToken, 'signed-dev-jwt');
    });

    test('verifyOtp reports backend connectivity failures clearly', () async {
      dotenv.testLoad(
        fileInput: '''
APP_ENV=development
DEV_AUTH_OTP_ENABLED=true
BACKEND_BASE_URL=http://dev-api.example.test
''',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final authServiceProvider = Provider(
        (ref) => DevBackendOtpAuthService(
          ref,
          client: MockClient((request) async {
            throw http.ClientException('offline');
          }),
        ),
      );
      final authService = container.read(authServiceProvider);

      await expectLater(
        authService.verifyOtp(phoneNumber: '+911234567890', otp: '123456'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains('authentication backend'),
          ),
        ),
      );
    });

    test('verifyOtp times out instead of staying pending forever', () async {
      dotenv.testLoad(
        fileInput: '''
APP_ENV=development
DEV_AUTH_OTP_ENABLED=true
BACKEND_BASE_URL=http://dev-api.example.test
''',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final authServiceProvider = Provider(
        (ref) => DevBackendOtpAuthService(
          ref,
          requestTimeout: const Duration(milliseconds: 1),
          client: MockClient((request) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            return http.Response('{}', 200);
          }),
        ),
      );
      final authService = container.read(authServiceProvider);

      await expectLater(
        authService.verifyOtp(phoneNumber: '+911234567890', otp: '123456'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    });
  });
}
