import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'login_page.dart';
import 'game_selection_page.dart';
import 'active_games_page.dart';
import 'finished_game_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> profileFuture;

  final String baseUrl = 'http://192.168.53.67:3000'; // Gerekirse kendi backend adresinle değiştir

  @override
  void initState() {
    super.initState();
    profileFuture = fetchProfile();
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token bulunamadı.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Profil API yanıtı: ${response.body}');
      throw Exception('Profil verisi alınamadı.');
      
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFe0f7fa),
    appBar: AppBar(
      backgroundColor: Colors.deepPurple,
      title: const Text('Ana Sayfa'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, size: 28, color:Color.fromARGB(255, 255, 0, 0)),
          onPressed: () => logout(context),
          tooltip: 'Çıkış Yap',
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final profile = snapshot.data!;
        final username = profile['username'] ?? 'Bilinmiyor';
        final successRate = profile['successRate'] ?? 0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildProfileCard(username, successRate),
                const SizedBox(height: 30),
                _buildMenuButton(
                  label: '🎮 Yeni Oyun',
                  color: Colors.green,
                  onTap: () => showGameSelection(context),
                ),
                _buildMenuButton(
                  label: '🔥 Aktif Oyunlar',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ActiveGamesPage()),
                    );
                  },
                ),
                _buildMenuButton(
                  label: '🏁 Biten Oyunlar',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FinishedGamesPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildProfileCard(String username, int successRate) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blueAccent,
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 40),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Başarı Yüzdesi: %$successRate',
            style: const TextStyle(fontSize: 16, color: Colors.green),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMenuButton({
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: const Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
}