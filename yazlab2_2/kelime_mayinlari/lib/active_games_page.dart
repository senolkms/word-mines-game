import 'package:flutter/material.dart';
import 'api_service.dart';

class ActiveGamesPage extends StatefulWidget {
  const ActiveGamesPage({super.key});

  @override
  State<ActiveGamesPage> createState() => _ActiveGamesPageState();
}

class _ActiveGamesPageState extends State<ActiveGamesPage> {
  late Future<List<dynamic>> activeGames;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  void fetchGames() {
    activeGames = ApiService().getActiveGames();
  }

  String timeAgo(DateTime lastMoveTime) {
    final now = DateTime.now();
    final difference = now.difference(lastMoveTime);
    
    if (difference.inSeconds < 60) return '${difference.inSeconds + 7} saniye önce';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dakika önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    return '${difference.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktif Oyunlarım')),
      body: FutureBuilder<List<dynamic>>(
        future: activeGames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('Aktif oyun yok.'));
          } else {
            final games = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  fetchGames();
                });
              },
              child: ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final player1 = game['player1']?['username'] ?? 'Bilinmiyor';
                  final player2 = game['player2']?['username'] ?? 'Bekleniyor';
                  final player1Score = game['player1Score'] ?? 0;
                  final player2Score = game['player2Score'] ?? 0;
                  final player1Id = game['player1Id'];
                  final currentTurn = game['currentTurnId'];
                  final isPlayer1Turn = currentTurn == game['player1Id'];
                  
                  final rawTime = game['lastMoveTime'];
                  DateTime? lastMoveTime;

                  if (rawTime != null &&
                      rawTime.toString().isNotEmpty &&
                      rawTime.toString().toLowerCase() != 'null') {
                    lastMoveTime = DateTime.tryParse(rawTime);
                  }

                  final displayTime = lastMoveTime != null
                      ? timeAgo(lastMoveTime)
                      : 'Zaman bilinmiyor';

                  final duration = game['duration'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          isPlayer1Turn
                              ? player1[0].toUpperCase()
                              : player2[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('$player1 ($player1Score) vs $player2 ($player2Score)'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Sıra: ${currentTurn == player1Id ? player1 : player2}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('Son hamle: $displayTime'),
                          Text('Oyun süresi: $duration dakika'),
                        ],
                      ),
                      trailing: const Icon(Icons.play_arrow, size: 32, color: Colors.green),
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          '/game',
                          arguments: {'gameId': game['id']},
                        );

                        setState(() {
                          fetchGames();
                        });
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
  );
  }
}