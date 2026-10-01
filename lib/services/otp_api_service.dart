import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Calls the Twilio OTP Express API (otp-api).
///
/// Set in `.env`:
///   OTP_API_BASE_URL=http://127.0.0.1:5002
///
/// Android emulator use: http://10.0.2.2:5002
class OtpApiService {
  OtpApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                dotenv.env['OTP_API_BASE_URL'] ??
                'http://127.0.0.1:5002')
            .replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String channel = 'sms',
  }) async {
    final response = await _client.post(
      _uri('/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'channel': channel}),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _client.post(
      _uri('/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    return _decode(response);
  }

  static bool isConfigured() {
    final url = dotenv.env['OTP_API_BASE_URL']?.trim();
    return url != null && url.isNotEmpty;
  }

  static bool isVerifySuccess(Map<String, dynamic> body) {
    if (body['success'] != true) return false;
    final data = body['data'];
    if (data is! Map) return false;
    final map = Map<String, dynamic>.from(data);
    return map['valid'] == true || map['status']?.toString() == 'approved';
  }

  static String errorMessage(
    Object error, {
    String fallback = 'Request failed',
  }) {
    if (error is OtpApiException) {
      final msg = error.message.trim();
      return msg.isNotEmpty ? msg : fallback;
    }
    final text = error.toString().trim();
    return text.isNotEmpty ? text : fallback;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message']?.toString() ??
        'Request failed (${response.statusCode})';
    throw OtpApiException(message, statusCode: response.statusCode, body: body);
  }
}

class OtpApiException implements Exception {
  OtpApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? body;

  @override
  String toString() => message;
}
