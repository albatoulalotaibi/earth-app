import 'dart:convert';

/// Lightweight HTTP client abstraction.
///
/// When the backend team delivers their API, inject the real [baseUrl]
/// via [AppConstants] and use this service in your repository
/// implementations.
///
/// For now this class is a placeholder that shows the pattern.
/// You can later swap it for `http`, `dio`, or any other HTTP package.
class ApiService {
  final String baseUrl;
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? _authToken;

  ApiService({required this.baseUrl});

  /// Set the auth token (e.g. after login).
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear the auth token (e.g. on logout).
  void clearAuthToken() {
    _authToken = null;
  }

  /// Build headers including auth token if present.
  Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ── HTTP helpers (implement with http/dio when needed) ─────────────

  /// Placeholder GET request.
  Future<Map<String, dynamic>> get(String endpoint) async {
    // TODO: Replace with real HTTP GET when backend is available
    // final response = await http.get(
    //   Uri.parse('$baseUrl$endpoint'),
    //   headers: _headers,
    // );
    // return jsonDecode(response.body);
    throw UnimplementedError(
      'Real HTTP not yet implemented. Use mock repositories.',
    );
  }

  /// Placeholder POST request.
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // TODO: Replace with real HTTP POST when backend is available
    throw UnimplementedError(
      'Real HTTP not yet implemented. Use mock repositories.',
    );
  }

  /// Placeholder PUT request.
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    throw UnimplementedError(
      'Real HTTP not yet implemented. Use mock repositories.',
    );
  }

  /// Placeholder DELETE request.
  Future<Map<String, dynamic>> delete(String endpoint) async {
    throw UnimplementedError(
      'Real HTTP not yet implemented. Use mock repositories.',
    );
  }
}
