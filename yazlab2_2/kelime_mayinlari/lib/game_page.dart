import 'package:flutter/material.dart';
import 'api_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final int gridSize = 15;
  List<List<String?>> board = List.generate(15, (_) => List.filled(15, null));
  List<List<bool>> revealedCells = List.generate(15, (_) => List.filled(15, false));
  List<List<bool>> revealedRewards = List.generate(15, (_) => List.filled(15, false));
  List<List<bool>> revealedMines = List.generate(15, (_) => List.filled(15, false));

  List<String> playerLetters = []; // Başlangıçta boş!
  Map<String, dynamic> selectedLetters = {};
  String? selectedLetter;
  bool isHorizontal = true;
  bool firstMoveDone = false;
  int? playerId; // 👈 Oyuncunun kendi ID'si
  int? gameId;
  int? currentTurnId;
  int? player1Id;
  int? player2Id;
  String player1Name = '';
  String player2Name = '';
  int player1Score = 0;
  int player2Score = 0;
  int remainingLetters = 0;
  String? blockZone;
  List<String> frozenLettersOpponent = [];
  int? extraTurnUserId;
  
  @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        gameId = args['gameId'];
        fetchGameDetails();
    });
  }

  // Matris pozisyonlarına özel bonus türleri ataması
final Map<String, String> bonusTiles = {
  '0,2': 'K3', '0,12': 'K3', '2,14': 'K3',
  '2,0': 'K3', '14,12': 'K3',
  '12,0': 'K3', '14,2': 'K3', '12,14': 'K3',

  '1,1': 'H3', '1,13': 'H3', '4,4': 'H3', '4,10': 'H3',
  '10,4': 'H3', '10,10': 'H3', '13,1': 'H3', '13,13': 'H3',


  '0,5': 'H2', '0,9': 'H2', '1,6': 'H2', '1,8': 'H2', '5,0': 'H2',
  '5,5': 'H2', '5,9': 'H2', '5,14': 'H2', '6,1': 'H2', '6,6': 'H2',
  '6,8': 'H2', '6,13': 'H2',

  '8,1': 'H2', '8,6': 'H2', '8,8': 'H2', '8,13': 'H2', '9,0': 'H2',
  '9,5': 'H2', '9,9': 'H2', '9,14': 'H2', '13,6': 'H2', '13,8': 'H2',
  '14,5': 'H2', '14,9': 'H2',

  '3,3': 'K2', '2,7': 'K2', '3,11': 'K2', '7,2': 'K2',
  '7,12': 'K2', '11,3': 'K2', '11,11': 'K2',
  '12,7': 'K2', 


  '7,7': 'STAR'
};
String _getRewardDisplayName(String type) {
  switch (type) {
    case 'bolge_yasagi':
      return 'Bölge Yasağı';
    case 'harf_yasagi':
      return 'Harf Yasağı';
    case 'ekstra_hamle_jokeri':
      return 'Ekstra Hamle Jokeri';
    default:
      return type;
  }
}

Color _getBonusColor(String bonusType) {
  switch (bonusType) {
    case 'H2':
      return Colors.lightBlue.shade100;
    case 'H3':
      return Colors.pink.shade100;
    case 'K2':
      return Colors.lightGreen.shade100;
    case 'K3':
      return Colors.brown.shade200;
    case 'STAR':
      return Colors.orange.shade300;
    default:
      return Colors.white;
  }
}

List<Map<String, dynamic>> mines = [];
List<Map<String, dynamic>> playerRewards = [];

final Map<String, int> letterScores = {
  'A': 1, 'B': 3, 'C': 4, 'Ç': 4, 'D': 3, 'E': 1,
  'F': 7, 'G': 5, 'Ğ': 8, 'H': 5, 'I': 2, 'İ': 1,
  'J': 10, 'K': 1, 'L': 1, 'M': 2, 'N': 1, 'O': 2,
  'Ö': 7, 'P': 5, 'R': 1, 'S': 2, 'Ş': 4, 'T': 1,
  'U': 2, 'Ü': 3, 'V': 7, 'Y': 3, 'Z': 4,
};

int calculateTotalPreviewScore() {
  int totalScore = 0;

  final Set<String> visited = {};

  for (var entry in selectedLetters.entries) {
    final parts = entry.key.split(',');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    // YATAY kelimeyi kontrol et:
    int startCol = col;
    while (startCol > 0 && (board[row][startCol - 1] != null || selectedLetters.containsKey('$row,${startCol - 1}'))) {
      startCol--;
    }

    List<String> horizontalPositions = [];
    int currentCol = startCol;
    while (currentCol < 15 && (board[row][currentCol] != null || selectedLetters.containsKey('$row,$currentCol'))) {
      horizontalPositions.add('$row,$currentCol');
      currentCol++;
    }

    bool hasNewLetterInHorizontal = horizontalPositions.any((pos) => selectedLetters.containsKey(pos));
    if (horizontalPositions.length > 1 && hasNewLetterInHorizontal) {
      final key = horizontalPositions.join('-');
      if (!visited.contains(key)) {
        totalScore += _calculateWordScore(horizontalPositions);
        visited.add(key);
      }
    }

    // DİKEY kelimeyi kontrol et:
    int startRow = row;
    while (startRow > 0 && (board[startRow - 1][col] != null || selectedLetters.containsKey('${startRow - 1},$col'))) {
      startRow--;
    }

    List<String> verticalPositions = [];
    int currentRow = startRow;
    while (currentRow < 15 && (board[currentRow][col] != null || selectedLetters.containsKey('$currentRow,$col'))) {
      verticalPositions.add('$currentRow,$col');
      currentRow++;
    }

    bool hasNewLetterInVertical = verticalPositions.any((pos) => selectedLetters.containsKey(pos));
    if (verticalPositions.length > 1 && hasNewLetterInVertical) {
      final key = verticalPositions.join('-');
      if (!visited.contains(key)) {
        totalScore += _calculateWordScore(verticalPositions);
        visited.add(key);
      }
    }
  }

  return totalScore;
}

int _calculateWordScore(List<String> positions) {
  int score = 0;
  int wordMultiplier = 1;

  for (final pos in positions) {
    final parts = pos.split(',');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);
    final key = '$row,$col';

    String letter;
    bool isJoker = false;

    if (selectedLetters.containsKey(key)) {
      // Yeni konan harf
      final value = selectedLetters[key];
      if (value is Map<String, dynamic>) {
        letter = value['letter'];
        isJoker = value['isJoker'] ?? false;
      } else {
        letter = value;
      }

      int letterScore = isJoker ? 0 : (letterScores[letter.toUpperCase()] ?? 0);
      final bonus = bonusTiles[key];

      // Harf bonusu
      if (bonus == 'H2') letterScore *= 2;
      if (bonus == 'H3') letterScore *= 3;

      // Kelime bonusu
      if (bonus == 'K2') wordMultiplier *= 2;
      if (bonus == 'K3') wordMultiplier *= 3;
      if (bonus == 'STAR') wordMultiplier *= 2;

      score += letterScore;
    } else {
      // Önceden tahtada olan harf (bonus uygulanmaz)
      letter = board[row][col]!;
      int letterScore = letterScores[letter.toUpperCase()] ?? 0;
      score += letterScore;
    }
  }

  return score * wordMultiplier;
}






  Future<void> fetchGameDetails() async {
  try {
    final gameData = await ApiService().getGameDetails(gameId!);
    
    setState(() {
      // 🟢 boardState null mu kontrolü:
      final boardData = gameData['boardState'];
      if (boardData != null) {
        board = List<List<String?>>.from(
          (boardData as List).map((row) => List<String?>.from(row)),
        );
      } else {
        board = List.generate(15, (_) => List.filled(15, null));
      }

      firstMoveDone = board.any((row) => row.any((cell) => cell != null));

      // 🟢 playerLetters null kontrolü:
      final letters = gameData['isPlayer1']
          ? gameData['player1Letters']
          : gameData['player2Letters'];

      if (letters != null) {
        playerLetters = List<String>.from(letters);
      } else {
        playerLetters = [];
      }

      currentTurnId = gameData['currentTurnId'];
      player1Id = gameData['player1Id'];
      player2Id = gameData['player2Id'];
      player1Name = gameData['player1'];                
      player2Name = gameData['player2'];
      player1Score = gameData['player1Score'] ?? 0;
      player2Score = gameData['player2Score'] ?? 0;
      remainingLetters = gameData['remainingLettersCount'] ?? 0;
      playerRewards = List<Map<String, dynamic>>.from(gameData['playerRewards'] ?? []);
      mines = List<Map<String, dynamic>>.from(gameData['mines']);

    // ✅ Yeni backend verilerini de alıyoruz:
      blockZone = gameData['blockZone'];
      frozenLettersOpponent = List<String>.from(gameData['frozenLettersOpponent'] ?? []);
      extraTurnUserId = gameData['extraTurnUserId'];
      if (gameData['status'] == 'finished') {
        String winnerName = gameData['winnerId'] == player1Id ? player1Name : player2Name;
        bool isCurrentPlayerWinner = gameData['winnerId'] == currentTurnId;

        Future.delayed(Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Oyun Bitti'),
              content: Text(
                isCurrentPlayerWinner
                    ? 'Tebrikler, kazandınız!'
                    : 'Oyun sona erdi. Kazanan: $winnerName',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // dialog kapansın
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                    );
                  },
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        });
      }

    }); 
  } catch (e) {
    print('Oyun detayları alınamadı: $e');
  }
}


Widget? getMineIcon(int row, int col) {
    if (!revealedMines[row][col]) return null;

    final mine = mines.firstWhere(
      (m) => m['row'] == row && m['col'] == col,
      orElse: () => {},
    );

    if (mine.isEmpty) return null;

    final type = mine['type'];
    final imagePath = 'assets/images/${type}.png';

    return Image.asset(
      imagePath,
      width: 20,
      height: 20,
    );
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Alanı'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 30, color: Color.fromARGB(255, 0, 255, 94)),
            onPressed: () async {
              List<Map<String, dynamic>> letterData = selectedLetters.entries
                  .where((entry) => entry.value != null)
                  .map((entry) {
                var parts = entry.key.split(',');
                return {
                  'row': int.parse(parts[0]),
                  'col': int.parse(parts[1]),
                  'letter': entry.value,
                };
              }).toList();

              if (letterData.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hiç harf seçilmedi!')),
                );
                return;
              }

              final result = await ApiService().sendWord(
                gameId: gameId!,
                letters: selectedLetters.entries.map((entry) {
                  final parts = entry.key.split(',');
                  final value = entry.value;

                  if (value is Map<String, dynamic>) {
                    return {
                      'row': int.parse(parts[0]),
                      'col': int.parse(parts[1]),
                      'letter': value['letter'],
                      'isJoker': value['isJoker'] ?? false,
                    };
                  } else {
                    return {
                      'row': int.parse(parts[0]),
                      'col': int.parse(parts[1]),
                      'letter': value,
                      'isJoker': false,
                    };
                  }
                }).toList(),
              );


              if (result.containsKey('error')) {
                print('HATA: ${result['error']}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: ${result['error']}')),
                );
              } else {
                print('Başarılı gönderildi: $result');
                setState(() {
                  selectedLetters.clear();
                  playerLetters = result['newLetters'] != null
                    ? List<String>.from(result['newLetters'])
                    : playerLetters; // Alttaki harfler güncellendi
                 if (result['updatedBoard'] != null) {
                    board = List<List<String?>>.from(
                      (result['updatedBoard'] as List).map((row) => List<String?>.from(row)),
                    );
                  }
                });
                await fetchGameDetails(); // Tahtayı güncelle
              
               // 🎉 ÖDÜL KAZANILDI MI?
                if (result.containsKey('triggeredRewards') && result['triggeredRewards'].isNotEmpty) {
                  String rewardsText = result['triggeredRewards'].map((e) => _getRewardDisplayName(e)).join(', ');
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tebrikler!'),
                        content: Text('Ödül kazandınız: $rewardsText'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Harika!'),
                          ),
                        ],
                      ),
                    );
                  } else if (result.containsKey('triggeredMines') && result['triggeredMines'].isNotEmpty) {
                    // Sadece ödül yoksa mayın göster
                    String minesText = result['triggeredMines'].join(', ');
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Mayına Denk Geldin!'),
                        content: Text('Etkinleşen Mayınlar: $minesText'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    );
                  }
            }
          }),
          PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 28, color: Color.fromARGB(255, 0, 247, 255)),
            onSelected: (value) async {
              if (value == 'pass') {
                final result = await ApiService().passTurn(gameId!);
                if (result.containsKey('error')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: ${result['error']}')),
                  );
                } else {
                  await fetchGameDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sıra pas geçildi.')),
                  );
                }
              } else if (value == 'surrender') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Teslim Ol'),
                    content: const Text('Bu oyundan çekilmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hayır')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final result = await ApiService().resignGame(gameId!);
                  if (result.containsKey('error')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: ${result['error']}')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Oyundan çekildiniz.')),
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pass',
                child: Text('Pas Geç'),
              ),
              const PopupMenuItem(
                value: 'surrender',
                child: Text('Teslim Ol'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
  child: Column(
    children: [
      // ✅ Üst Bilgi Alanı: Harf havuzu, skorlar
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Column(
          children: [
            Text(
              'Kalan Harf Havuzu: $remainingLetters',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(player1Name, style: const TextStyle(fontSize: 16)),
                    Text('$player1Score Puan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text(player2Name, style: const TextStyle(fontSize: 16)),
                    Text('$player2Score Puan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // ✅ Ödül Butonları
      if (playerRewards.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎁 Kazanılan Ödüller:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: playerRewards
                    .where((reward) => reward['used'] == false)
                    .map((reward) => ElevatedButton.icon(
                          onPressed: () async {
                            final result = await ApiService().useReward(
                              gameId: gameId!,
                              rewardType: reward['type'],
                            );

                            if (result.containsKey('error')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: ${result['error']}')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Ödül kullanıldı: ${_getRewardDisplayName(reward['type'])}'),
                                ),
                              );
                              await fetchGameDetails();
                            }
                          },
                          icon: const Icon(Icons.workspace_premium, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          label: Text(_getRewardDisplayName(reward['type'])),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

      // ✅ Oyun Alanı - GridView büyütüldü
      Expanded(
        flex: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 15,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              int row = index ~/ gridSize;
              int col = index % gridSize;
              return _buildGridItem(context, row, col);
            },
          ),
        ),
      ),

      // ✅ Geçici Puan
      if (selectedLetters.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Geçici Puan: ${calculateTotalPreviewScore()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),

      // ✅ Harf Butonları - Alta sabitlendi
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: playerLetters.map((letter) {
              final isFrozen = frozenLettersOpponent.contains(letter);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: isFrozen
                      ? null
                      : () {
                          setState(() {
                            selectedLetter = letter;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedLetter == letter ? Colors.green : Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isFrozen ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  ),
),);
  }
  Widget _buildGridItem(BuildContext context, int row, int col) {
    String key = '$row,$col';
    String? letter;
    bool isJoker = false;

    if (selectedLetters.containsKey(key)) {
      final val = selectedLetters[key];
      if (val is Map<String, dynamic>) {
        letter = val['letter'];
        isJoker = val['isJoker'] ?? false;
      } else if (val is String) {
        letter = val;
      }
    } else {
      letter = board[row][col];
    }

  String? bonusType = bonusTiles[key];

  return GestureDetector(
    onTap: () {
      if (selectedLetter != null && board[row][col] == null) {
        if (!firstMoveDone && (row != 7 || col != 7)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlk harf ortadan başlamalı!')),
          );
          return;
        }
        if (firstMoveDone && !_isAdjacent(row, col)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni harf, mevcut harflere bitişik olmalı!')),
          );
          return;
        }
        _placeLetter(row, col);
      }
    },
    child: Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: bonusType != null ? _getBonusColor(bonusType) : Colors.white,
      ),
      child: Center(
        child: getMineIcon(row, col) ??
            Text(
              letter ?? bonusType ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isJoker ? Colors.deepPurple : Colors.black,
              ),
            ),
      ),
    ),
  );
  
}
void revealMine(int row, int col) {
    setState(() {
      revealedMines[row][col] = true;
    });
  }

  void revealReward(int row, int col) {
    setState(() {
      revealedRewards[row][col] = true;
    });
  }


//komşuluk kontrolü
bool _isAdjacent(int row, int col) {
  final neighbors = [
    [row - 1, col], // üst
    [row + 1, col], // alt
    [row, col - 1], // sol
    [row, col + 1], // sağ
  ];

  for (var neighbor in neighbors) {
    int r = neighbor[0];
    int c = neighbor[1];

    if (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
      if (board[r][c] != null || selectedLetters['$r,$c'] != null) {
        return true; // Bir komşuda harf var!
      }
    }
  }
  return false;
}

void _placeLetter(int startRow, int startCol) async {
  String key = '$startRow,$startCol';

  if (selectedLetter != null && board[startRow][startCol] == null && selectedLetters[key] == null) {
    if (!firstMoveDone && (startRow != 7 || startCol != 7)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlk harf ortadan başlamalı!')),
      );
      return;
    }
    if (firstMoveDone && !_isAdjacent(startRow, startCol)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni harf, mevcut harflere bitişik olmalı!')),
      );
      return;
    }
    if (blockZone == 'right' && startCol < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bölgeye harf koyamazsınız!')),
      );
      return;
    }
    if (blockZone == 'left' && startCol > 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bölgeye harf koyamazsınız!')),
      );
      return;
    }

    Map<String, dynamic> data;

    if (selectedLetter == 'JOKER') {
      final chosenLetter = await showJokerSelectionDialog(context);
      if (chosenLetter == null) return;

      data = {
        'letter': chosenLetter,
        'isJoker': true,
      };
    } else {
      data = {
        'letter': selectedLetter!,
        'isJoker': false,
      };
    }

    setState(() {
      selectedLetters[key] = data;
      playerLetters.remove(selectedLetter);
      selectedLetter = null;
      firstMoveDone = true;
    });
  }
}

Future<String?> showJokerSelectionDialog(BuildContext context) async {
  final List<String> turkishAlphabet = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
    'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
    'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
  ];

  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('JOKER HARF SEÇİMİ'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: turkishAlphabet.map((letter) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, letter); // Seçilen harfi geri döner
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(letter, style: const TextStyle(fontSize: 18)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      );
    },
  );
}

}
