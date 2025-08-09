import 'package:flutter/material.dart';
import 'api_service.dart';

class FinishedGamesPage extends StatefulWidget {
  const FinishedGamesPage({super.key});

  @override
  State<FinishedGamesPage> createState() => _FinishedGamesPageState();
}

class _FinishedGamesPageState extends State<FinishedGamesPage> {
  late Future<List<dynamic>> finishedGames;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final id = await ApiService().getCurrentUserId();
    final games = await ApiService().getFinishedGames();

    setState(() {
      currentUserId = id;
      finishedGames = Future.value(games); // 🟡 Önemli detay!
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biten Oyunlarım')),
      body: currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
              future: finishedGames,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(child: Text('Biten oyun yok.'));
                } else {
                  final games = snapshot.data!;
                  return ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final player1 = game['player1']?['username'] ?? 'Bilinmiyor';
                      final player2 = game['player2']?['username'] ?? 'Bilinmiyor';
                      final player1Score = game['player1Score'] ?? 0;
                      final player2Score = game['player2Score'] ?? 0;
                      final player1Id = game['player1Id'];
                      final winnerId = game['winnerId'];

                      final isWin = winnerId == currentUserId;
                      //final isLose = winnerId != null && winnerId != currentUserId;

                      String winner;
                      Icon trailingIcon;

                      if (winnerId == null) {
                        winner = 'Berabere';
                        trailingIcon = const Icon(Icons.remove_circle, color: Colors.grey);
                      } else if (isWin) {
                        winner = 'Siz';
                        trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
                      } else {
                        winner = winnerId == player1Id ? player1 : player2;
                        trailingIcon = const Icon(Icons.cancel, color: Colors.red);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: ListTile(
                          title: Text('$player1 ($player1Score) vs $player2 ($player2Score)'),
                          subtitle: Text('Kazanan: $winner'),
                          trailing: trailingIcon,
                        ),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}
