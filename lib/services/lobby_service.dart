import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/model/user_model.dart';
import 'package:app/services/helper_service.dart';
import 'package:app/exceptions/form_exceptions.dart';

class LobbyService {
  static const String createLobbyPath = 'lobbies/';

  static Future<User> createLobby({
    required String hostId,
    required String mode,
  }) async {
    final uri = HelperService.buildUri(createLobbyPath);
    final headers = HelperService.buildHeaders();
    final body = jsonEncode({
      'host_id': hostId,
      'mode': mode,
    });

    final response = await http.post(
      uri,
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 10));

    final statusType = (response.statusCode / 100).floor() * 100;
    switch (statusType) {
      case 200:
      // case 201:
      //   final json = jsonDecode(response.body);
      //
      //   return User(id: json['host'], username: '');
      case 400:
        final json = jsonDecode(response.body);
        throw handleFormErrors(json);
      default:
        throw FormGeneralException(message: 'Server error: ${response.statusCode}');
    }
  }
}
