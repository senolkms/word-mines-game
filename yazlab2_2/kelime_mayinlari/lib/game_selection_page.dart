import 'package:flutter/material.dart';
import 'api_service.dart';

void showGameSelection(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Oyun Süresi Seçiniz',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Hızlı Oyun', style: TextStyle(fontSize: 18, color: Colors.green)),
            const SizedBox(height: 10),
            _buildOptionButton(context, '2 Dakika', 2),
            _buildOptionButton(context, '5 Dakika', 5),
            const Divider(height: 30, thickness: 1),
            const Text('Genişletilmiş Oyun', style: TextStyle(fontSize: 18, color: Colors.orange)),
            const SizedBox(height: 10),
            _buildOptionButton(context, '12 Saat', 720),
            _buildOptionButton(context, '24 Saat', 1440),
          ],
        ),
      );
    },
  );
}

Widget _buildOptionButton(BuildContext context, String label, int durationInMinutes) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        Navigator.pop(context); // BottomSheet kapatılır

        final response = await ApiService().startGame(durationInMinutes);
        final message = response['message'] ?? 'Bir hata oluştu.';

        // ✅ Güvenli context kontrolü
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }

        if (response['game'] != null && response['game']['status'] == 'active') {
          if (context.mounted) {
            Navigator.pushNamed(
              context,
              '/game',
              arguments: {'gameId': response['game']['id']},
            );
          }
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 16)),
    ),
  );
}
