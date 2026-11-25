import '../models/registered_mug.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MugRegistrationService {
  final AuthService auth;
  final ApiService _api;

  MugRegistrationService(this.auth, {ApiService? api})
      : _api = api ?? ApiService();

  Future<List<RegisteredMug>> getMyRegisteredMugs() async {
    final result = await _call(ApiEndpoints.listMugsMethod);
    final data = result['data'];
    if (data is! List) {
      throw const ApiException('The server did not return a valid mug list.');
    }
    return List<RegisteredMug>.unmodifiable(data.map(_parseMug));
  }

  Future<RegisteredMug> registerMug(String serialNo) async {
    final result = await _call(
      ApiEndpoints.registerMugMethod,
      body: {'serial_no': _serial(serialNo)},
    );
    return _parseMug(result['data']);
  }

  Future<void> unregisterMug(String serialNo) async {
    await _call(
      ApiEndpoints.unregisterMugMethod,
      body: {'serial_no': _serial(serialNo)},
    );
  }

  Future<Map<String, dynamic>> _call(
    String method, {
    Map<String, String>? body,
  }) async {
    final session = auth.session;
    if (session == null || !session.isValid) {
      throw const ApiException('Please log in first.', 401, 'AUTHENTICATION_REQUIRED');
    }
    final result = await _api.authenticatedRequest(
      method, session: session, body: body,
    );
    if (!identical(session, auth.session)) {
      throw const ApiException('Your account changed. Please try again.');
    }
    return result;
  }

  RegisteredMug _parseMug(Object? data) {
    if (data is Map<String, dynamic>) {
      try {
        return RegisteredMug.fromJson(data);
      } on FormatException {
        throw const ApiException('The server returned invalid mug details.');
      }
    }
    throw const ApiException('The server returned invalid mug details.');
  }

  String _serial(String input) {
    final serial = input.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:/-]{0,139}$').hasMatch(serial)) {
      throw const ApiException(
        'Please enter a valid Garam Mug serial number.',
        null,
        'INVALID_REQUEST',
      );
    }
    return serial;
  }
}
