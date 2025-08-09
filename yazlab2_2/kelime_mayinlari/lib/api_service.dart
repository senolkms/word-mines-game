import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint için
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.53.67:3000';  // ✅ DOĞRU!
  
  // Token alma
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('API İsteği gönderiliyor: $username, $password');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      debugPrint('Gelen cevap durumu: ${response.statusCode}');
      debugPrint('Gelen cevap body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

      if (data['userId'] != null) {
        await prefs.setInt('userId', data['userId']);
      }

      }

      return data;
    } catch (e) {
      debugPrint('HATA OLDU: $e');
      return {'error': 'Bağlantı hatası veya backend çalışmıyor!'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    print('Register Status: ${response.statusCode}');
    print('Register Response: ${response.body}');

    return jsonDecode(response.body);
  } catch (e) {
    return {'error': 'Bağlantı hatası veya backend çalışmıyor!'};
  }
}
Future<Map<String, dynamic>> startGame(int duration) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.post(
    Uri.parse('$baseUrl/start-game'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Token ile userId backendden çekilecek
    },
    body: jsonEncode({'duration': duration}),
  );

  print('Game Start Response: ${response.body}');
  return jsonDecode(response.body);
}

Future<List<dynamic>> getActiveGames() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/active-games'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['games'];
  } else {
    throw Exception('Aktif oyunları getirirken hata oluştu');
  }
}
 Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
// ✔️ Kelime gönderme (word submit)
  Future<Map<String, dynamic>> sendWord({
    required int gameId,
    required List<Map<String, dynamic>> letters,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'error': 'Token bulunamadı.'};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/submit-word'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'gameId': gameId, 'letters': letters}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      return {'error': data['error'] ?? 'Bilinmeyen hata'};
    }
  }
   // ✔️ Oyun detaylarını çekme (kelime tahtasını almak için)
  Future<Map<String, dynamic>> getGameDetails(int gameId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/game-details/$gameId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Oyun detayları getirilemedi: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> useReward({
  required int gameId,
  required String rewardType,
}) async {
  final token = await _getToken();
  if (token == null) {
    return {'error': 'Token bulunamadı.'};
  }

  final response = await http.post(
    Uri.parse('$baseUrl/use-reward'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'gameId': gameId, 'rewardType': rewardType}),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return data;
  } else {
    return {'error': data['error'] ?? 'Bilinmeyen hata'};
  }
}

// ✅ PAS GEÇMEK
  Future<Map<String, dynamic>> passTurn(int gameId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/pass-turn'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'gameId': gameId}),
    );

    return jsonDecode(response.body);
  }

  // ✅ TESLİM OLMAK
  Future<Map<String, dynamic>> resignGame(int gameId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/surrender'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'gameId': gameId}),
    );

    return jsonDecode(response.body);
  }
  
  Future<List<dynamic>> getFinishedGames() async {
  final token = await _getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/finished-games'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['games'] ?? [];
  } else {
    throw Exception('Biten oyunlar getirilemedi: ${response.body}');
  }
}
Future<Map<String, dynamic>> getProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/me'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Profil verisi alınamadı.');
  }
}
Future<int?> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userId');
}


}


