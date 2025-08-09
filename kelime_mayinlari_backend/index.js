const express = require('express');
const { PrismaClient } = require('@prisma/client');
const app = express();
const prisma = new PrismaClient();
const PORT = 3000;

app.use(express.json());
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Token gerekli.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = verifyToken(token);  // verifyToken zaten yazılmıştı
    req.user = decoded;                 // user bilgisi req.user'a ekleniyor
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Geçersiz token.' });
  }
}
// Kullanıcı ekleme (CREATE)
app.post('/users', async (req, res) => {
  const { username, email, password } = req.body;
  try {
    const newUser = await prisma.user.create({
      data: { username, email, password }
    });
    res.json(newUser);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Kullanıcıları listeleme (READ)
app.listen(PORT, () => {
  console.log(`Sunucu http://localhost:${PORT} adresinde çalışıyor`);
});

app.get('/users', async (req, res) => {
    try {
      const users = await prisma.user.findMany();
      res.json(users);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

// Kullanıcıyı güncelleme (UPDATE)
app.put('/users/:id', async (req, res) => {
    const userId = parseInt(req.params.id);
    const { username, email, password } = req.body;
  
    try {
      const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: { username, email, password }
      });
      res.json(updatedUser);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Kullanıcıyı silme (DELETE)
app.delete('/users/:id', async (req, res) => {
    const userId = parseInt(req.params.id);
  
    try {
      await prisma.user.delete({
        where: { id: userId }
      });
      res.json({ message: 'Kullanıcı silindi.' });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });


  const { hashPassword, comparePasswords } = require('./utils/passwordUtils');

  // Kullanıcı kaydı (REGISTER)
  app.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
  
    // E-mail formatı kontrolü
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Geçerli bir e-posta adresi giriniz.' });
    }
  
    // Şifre kontrolü
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(password)) {
      return res.status(400).json({ error: 'Şifre en az 8 karakter olmalı, büyük/küçük harf ve rakam içermelidir.' });
    }
  
    try {
      // E-mail ve username zaten var mı?
      const existingUser = await prisma.user.findFirst({
        where: { OR: [{ username }, { email }] }
      });
  
      if (existingUser) {
        return res.status(400).json({ error: 'Bu kullanıcı adı veya e-posta zaten kullanılıyor.' });
      }
  
      // Şifreyi hashle
      const hashedPassword = await hashPassword(password);
  
      const newUser = await prisma.user.create({
        data: { username, email, password: hashedPassword }
      });
  
      res.json({ message: 'Kayıt başarılı!', userId: newUser.id });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  
  const { generateToken } = require('./utils/tokenUtils');

  // Kullanıcı girişi (LOGIN)
  app.post('/login', async (req, res) => {
    const { username, password } = req.body;
  
    try {
      const user = await prisma.user.findUnique({
        where: { username }
      });
  
      if (!user) {
        return res.status(400).json({ error: 'Kullanıcı bulunamadı.' });
      }
  
      const isPasswordValid = await comparePasswords(password, user.password);
  
      if (!isPasswordValid) {
        return res.status(400).json({ error: 'Şifre yanlış.' });
      }
  
      const token = generateToken(user.id);  // Token ürettik!
      res.json({ message: 'Giriş başarılı!', token,userId: user.id });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  
  const { verifyToken } = require('./utils/tokenUtils');

  // Token kontrolü için middleware:
  function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
  
    if (!token) return res.status(401).json({ error: 'Token gerekli!' });
  
    try {
      const decoded = verifyToken(token);
      req.user = decoded;
      next();
    } catch (error) {
      res.status(403).json({ error: 'Geçersiz token!' });
    }
  }
  
  // Örnek korumalı route:
  app.get('/profile', authenticateToken, async (req, res) => {
    const userId = req.user.userId;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, username: true, email: true }  // Şifreyi göstermiyoruz!
    });
    res.json(user);
  });
  
  const jwt = require('jsonwebtoken');
  const { createLetterPool, drawLetters } = require('./utils/letterPool');
  const { generateMines } = require('./utils/mineUtils');

// Oyun başlatma (eşleştirme)
app.post('/start-game', async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Token eksik.' });
  }

  const token = authHeader.split(' ')[1];
  let userId;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    userId = decoded.userId;
  } catch (error) {
    return res.status(401).json({ error: 'Geçersiz token.' });
  }

  const { duration } = req.body;

  try {
    const waitingGame = await prisma.game.findFirst({
      where: {
        duration: duration,
        status: 'waiting',
        NOT: { player1Id: userId },
      },
    });

    if (waitingGame) {
      const isPlayer1Turn = Math.random() < 0.5;

      // 🎉 Yeni havuz oluştur:
      let letterPool = createLetterPool();
      const { drawn: player1Letters, pool: poolAfterP1 } = drawLetters(letterPool, 7);
      const { drawn: player2Letters, pool: poolAfterP2 } = drawLetters(poolAfterP1, 7);

      const updatedGame = await prisma.game.update({
        where: { id: waitingGame.id },
        data: {
          player2Id: userId,
          status: 'active',
          currentTurnId: isPlayer1Turn ? waitingGame.player1Id : userId,
          letterPool: poolAfterP2,                 // Kalan harf havuzu
          player1Letters: player1Letters,         // 1. oyuncunun harfleri
          player2Letters: player2Letters,         // 2. oyuncunun harfleri
        },
      });
      return res.json({ message: 'Eşleşme tamamlandı!', game: updatedGame });
    } else {
      // 🆕 Yeni oyun oluşturuluyor:
      let letterPool = createLetterPool();
      const { drawn: player1Letters, pool: poolAfterP1 } = drawLetters(letterPool, 7);
      const mines = generateMines();

      const newGame = await prisma.game.create({
        data: {
          duration: duration,
          player1Id: userId,
          currentTurnId: userId,
          letterPool: poolAfterP1,
          player1Letters: player1Letters,
          mines: mines,
        },
      });
      return res.json({ message: 'Oyun oluşturuldu, eşleşme bekleniyor.', game: newGame });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
//Aktif oyunlar
app.get('/active-games', async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Token eksik.' });
  }

  const token = authHeader.split(' ')[1];
  
  let userId;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    userId = decoded.userId;
  } catch (error) {
    return res.status(401).json({ error: 'Geçersiz token.' });
  }

  try {
    const activeGames = await prisma.game.findMany({
      where: {
        status: 'active',
        OR: [
          { player1Id: userId },
          { player2Id: userId },
        ],
      },
      select: {
        id: true,
        duration: true,
        currentTurnId: true,
        createdAt: true,
        player1Score: true,
        player2Score: true,
        player1Id: true,
        player2Id: true,
        lastMoveTime: true, // BUNU SEÇMEYİ UNUTMA
        player1: {
          select: {
            id: true,
            username: true,
          },
        },
        player2: {
          select: {
            id: true,
            username: true,
          },
        },
      },
    });

    const formattedGames = activeGames.map(game => ({
      ...game,
      lastMoveTime: game.lastMoveTime ? game.lastMoveTime.toISOString() : null,
    }));

    res.json({ games: formattedGames });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});



//kelime bilgisi alma kısmı


function findWordsOnBoard(board, placedLetters) {
  const words = [];

  placedLetters.forEach(({ row, col }) => {
    // Yatay kelime bul:
    let startCol = col;
    while (startCol > 0 && board[row][startCol - 1]) startCol--;
    const positionsH = [];
    let wordH = '';
    for (let c = startCol; c < 15 && board[row][c]; c++) {
      wordH += board[row][c];
      positionsH.push({ row, col: c });
    }
    if (wordH.length > 1) {
      words.push({ word: wordH, positions: positionsH });
    }

    // Dikey kelime bul:
    let startRow = row;
    while (startRow > 0 && board[startRow - 1][col]) startRow--;
    const positionsV = [];
    let wordV = '';
    for (let r = startRow; r < 15 && board[r][col]; r++) {
      wordV += board[r][col];
      positionsV.push({ row: r, col });
    }
    if (wordV.length > 1) {
      words.push({ word: wordV, positions: positionsV });
    }
  });

  // Aynı kelimeyi iki kez eklememek için:
  const uniqueWords = [];
  const seen = new Set();
  for (const { word, positions } of words) {
    if (!seen.has(word)) {
      uniqueWords.push({ word, positions });
      seen.add(word);
    }
  }

  return uniqueWords;
}


const bonusTiles = require('./utils/bonusTiles'); 
const wordList = require('./utils/wordList');  


function normalizeWord(word) {
  return word.toLocaleUpperCase('tr-TR');
}
app.post('/submit-word', authenticate, async (req, res) => {
  const { gameId, letters } = req.body;
  const userId = req.user.userId;

  if (!gameId || !letters || letters.length === 0) {
    return res.status(400).json({ error: 'Eksik veri gönderildi.' });
  }

  try {
    const game = await prisma.game.findUnique({ where: { id: gameId } });
    if (!game) return res.status(404).json({ error: 'Oyun bulunamadı.' });

    const isExtraTurn = game.extraTurnUserId === userId;

    if (game.currentTurnId !== userId && !isExtraTurn) {
      return res.status(403).json({ error: 'Sıra sizde değil.' });
    }

    let playerLetters = userId === game.player1Id ? game.player1Letters : game.player2Letters;
    let letterPool = game.letterPool || [];
    let mines = game.mines || [];

    // ✅ Bölge yasağı kontrolü
    if (game.blockZone && userId === game.player2Id && game.blockZone === 'right') {
      const invalidMove = letters.some(({ col }) => col < 7);
      if (invalidMove) {
        return res.status(400).json({ error: 'Bu bölgede hamle yapamazsınız (bölge yasağı aktif).' });
      }
    }
    if (game.blockZone && userId === game.player1Id && game.blockZone === 'left') {
      const invalidMove = letters.some(({ col }) => col > 7);
      if (invalidMove) {
        return res.status(400).json({ error: 'Bu bölgede hamle yapamazsınız (bölge yasağı aktif).' });
      }
    }

    // ✅ Harf yasağı kontrolü
    if (Array.isArray(game.frozenLettersOpponent) && game.frozenLettersOpponent.length > 0) {
      const frozen = game.frozenLettersOpponent.map(l => l.toUpperCase());
      const triedFrozen = letters.some(({ letter }) => frozen.includes(letter.toUpperCase()));
      if (triedFrozen) {
        return res.status(400).json({ error: 'Bu turda bazı harfleri kullanamazsınız (harf yasağı aktif).' });
      }

      await prisma.game.update({
        where: { id: gameId },
        data: { frozenLettersOpponent: [] }
      });
    }

    // ✅ Harf kontrolü
    for (const { letter, isJoker } of letters) {
      if (!isJoker) {
        const index = playerLetters.indexOf(letter);
        if (index === -1) {
          return res.status(400).json({ error: `Harf '${letter}' elinizde yok!` });
        }
      }
    }

    let board = game.boardState || Array(15).fill().map(() => Array(15).fill(null));
    letters.forEach(({ row, col, letter }) => {
      board[row][col] = letter.toUpperCase();
    });

    const foundWords = findWordsOnBoard(board, letters);
    const invalidWords = foundWords
      .map(w => normalizeWord(w.word))
      .filter(word => !wordList.includes(word));

    if (invalidWords.length > 0) {
      return res.status(400).json({ error: `Geçersiz kelime(ler): ${invalidWords.join(', ')}` });
    }

    let totalScore = 0;
    let hasKelimeIptali = false;
    let hasPuanTransferi = false;
    let puanTransferiScore = 0;
    let hasHarfKaybi = false;
    let hasHamleEngeli = false;

    const triggeredMines = [];
    const triggeredRewards = [];

    letters.forEach(({ row, col }) => {
      const mine = mines.find(m => m.row === row && m.col === col);
      if (mine) triggeredMines.push(mine);

      if (mine && ['bolge_yasagi', 'harf_yasagi', 'ekstra_hamle_jokeri'].includes(mine.type)) {
        triggeredRewards.push(mine.type);
      }
    });

    foundWords.forEach(({ word, positions }) => {
      let baseScore = 0;
      let wordMultiplier = 1;

      positions.forEach(({ row, col }) => {
        const letterObj = letters.find(l => l.row === row && l.col === col);
        const isJoker = letterObj?.isJoker ?? false;
        const letter = board[row][col];
        const key = `${row},${col}`;
        const bonus = bonusTiles[key];

        let letterScore = isJoker ? 0 : getLetterScore(letter);

        if (!hasHamleEngeli) {
          if (bonus === 'H2') letterScore *= 2;
          if (bonus === 'H3') letterScore *= 3;
          if (bonus === 'K2') wordMultiplier *= 2;
          if (bonus === 'K3') wordMultiplier *= 3;
          if (bonus === 'STAR') wordMultiplier *= 2;
        }

        baseScore += letterScore;
      });

      totalScore += baseScore * wordMultiplier;
    });

    triggeredMines.forEach(mine => {
      switch (mine.type) {
        case 'puan_bolunmesi':
          totalScore = Math.floor(totalScore * 0.3);
          break;
        case 'puan_transferi':
          hasPuanTransferi = true;
          puanTransferiScore = totalScore;
          totalScore = 0;
          break;
        case 'harf_kaybi':
          hasHarfKaybi = true;
          break;
        case 'hamle_engeli':
          hasHamleEngeli = true;
          break;
        case 'kelime_iptali':
          hasKelimeIptali = true;
          break;
      }
    });
    
    if (hasHarfKaybi) {
      // Elindeki kalan harfleri havuza ekle
      letterPool.push(...playerLetters.filter(l => l !== 'JOKER'));
      playerLetters = [];
    
      const { drawn, pool: updatedPool } = drawLetters(letterPool, 7);
      playerLetters.push(...drawn);
      letterPool = updatedPool;
    }

    if (hasKelimeIptali) totalScore = 0;

    if (hasPuanTransferi && puanTransferiScore > 0) {
      const updatedData = {};
    
      if (userId === game.player1Id) {
        updatedData.player2Score = (game.player2Score || 0) + puanTransferiScore;
      } else {
        updatedData.player1Score = (game.player1Score || 0) + puanTransferiScore;
      }
    
      await prisma.game.update({
        where: { id: gameId },
        data: updatedData,
      });
    }

    if (!hasHamleEngeli && totalScore > 0) {
      const updatedData = {};
    
      if (userId === game.player1Id) {
        updatedData.player1Score = (game.player1Score || 0) + totalScore;
      } else {
        updatedData.player2Score = (game.player2Score || 0) + totalScore;
      }
    
      await prisma.game.update({
        where: { id: gameId },
        data: updatedData,
      });
    }
    //olay mahalli
    letters.forEach(({ letter, isJoker }) => {
      const index = playerLetters.indexOf(isJoker ? 'JOKER' : letter);
      if (index !== -1) playerLetters.splice(index, 1);
    });

    const missing = Math.max(0, 7 - playerLetters.length);
    if (missing > 0 && letterPool.length > 0) {
      const { drawn, pool: updatedPool } = drawLetters(letterPool, missing);
      playerLetters.push(...drawn);
      letterPool = updatedPool;
    }
    //kelime bitince oyun bitirme
    const isHandEmpty = playerLetters.filter(l => l !== 'JOKER').length === 0;
    const isPoolEmpty = letterPool.filter(l => l !== 'JOKER').length === 0;

    if (isHandEmpty && isPoolEmpty) {
      const player1Score = game.player1Score || 0;
      const player2Score = game.player2Score || 0;
    
      let winnerId = null;
      if (player1Score > player2Score) winnerId = game.player1Id;
      else if (player2Score > player1Score) winnerId = game.player2Id;
      // eşitse null bırakılabilir veya 'beraberlik' gibi ele alınabilir
    
      await prisma.game.update({
        where: { id: gameId },
        data: {
          status: 'finished',
          winnerId,
          endedAt: new Date(),
        },
      });
    
      await updateSuccessRates(prisma, {
        player1Id: game.player1Id,
        player2Id: game.player2Id,
        winnerId, // artık gerçekten kazanan
      });
    }
    

    if (triggeredRewards.length > 0) {
      const rewardsField = userId === game.player1Id ? 'player1Rewards' : 'player2Rewards';
      let currentRewards = userId === game.player1Id ? (game.player1Rewards || []) : (game.player2Rewards || []);

      triggeredRewards.forEach(type => {
        currentRewards.push({ type, used: false });
      });

      await prisma.game.update({
        where: { id: gameId },
        data: { [rewardsField]: currentRewards },
      });
    }

    if (isExtraTurn) {
      await prisma.game.update({
        where: { id: gameId },
        data: {
          extraTurnUserId: null,
          boardState: board,
          letterPool,
          player1Letters: userId === game.player1Id ? playerLetters : game.player1Letters,
          player2Letters: userId === game.player2Id ? playerLetters : game.player2Letters,
          mines: game.mines,
          blockZone: null,
          lastMoveTime: new Date(),
        },
      });
    } else {
      const nextTurnId = userId === game.player1Id ? game.player2Id : game.player1Id;
      await prisma.game.update({
        where: { id: gameId },
        data: {
          currentTurnId: nextTurnId,
          boardState: board,
          letterPool,
          player1Letters: userId === game.player1Id ? playerLetters : game.player1Letters,
          player2Letters: userId === game.player2Id ? playerLetters : game.player2Letters,
          mines: game.mines,
          blockZone: null,
          lastMoveTime: new Date(),
        },
      });
    }

    res.json({
      message: 'Kelime başarıyla işlendi',
      words: foundWords.map(w => w.word),
      score: totalScore,
      triggeredMines: triggeredMines.map(m => m.type),
      triggeredRewards,
    });

  } catch (error) {
    console.error('submit-word hatası:', error);
    res.status(500).json({ error: error.message });
  }
});




async function applyRewardEffect(rewardType, game, userId) {
  const opponentId = userId === game.player1Id ? game.player2Id : game.player1Id;
  let updatedData = {};

  switch (rewardType) {
    case 'bolge_yasagi':
      updatedData = { blockZone: 'right' }; // Rakibin sağ tarafına harf koyması engellenecek
      break;

    case 'harf_yasagi':
      if (opponentId) {
        const opponentLetters = opponentId === game.player1Id ? game.player1Letters || [] : game.player2Letters || [];
        const frozenLetters = opponentLetters.slice(0, 2); // İlk 2 harfi dondur
        updatedData = { frozenLettersOpponent: frozenLetters };
      } else {
        throw new Error('Rakip bulunamadı.');
      }
      break;

    case 'ekstra_hamle_jokeri':
      updatedData = { extraTurnUserId: userId }; // Bu kullanıcıya ekstra hamle hakkı ver
      break;

    default:
      throw new Error('Geçersiz ödül tipi!');
  }

  await prisma.game.update({
    where: { id: game.id },
    data: updatedData
  });

  return updatedData;
}

app.post('/use-reward', authenticate, async (req, res) => {
  const { gameId, rewardType } = req.body;
  const userId = req.user.userId;

  try {
    const game = await prisma.game.findUnique({ where: { id: gameId } });
    if (!game) return res.status(404).json({ error: 'Oyun bulunamadı.' });

    let playerRewards = userId === game.player1Id ? (game.player1Rewards || []) : (game.player2Rewards || []);
    const rewardIndex = playerRewards.findIndex(r => r.type === rewardType && !r.used);

    if (rewardIndex === -1) {
      return res.status(400).json({ error: 'Bu ödülü kullanamazsınız veya zaten kullanıldı.' });
    }

    // Ödül işlevini uygula:
    const rewardResult = await applyRewardEffect(rewardType, game, userId);
    
    // Ödülü kullanılmış işaretle:
    playerRewards[rewardIndex].used = true;
    playerRewards[rewardIndex].active = true;
    await prisma.game.update({
      where: { id: gameId },
      data: {
        player1Rewards: userId === game.player1Id ? playerRewards : game.player1Rewards,
        player2Rewards: userId === game.player2Id ? playerRewards : game.player2Rewards,
      },
    });

    res.json({ message: 'Ödül kullanıldı!', rewardType, rewardResult });

  } catch (error) {
    console.error('use-reward hatası:', error);
    res.status(500).json({ error: error.message });
  }
});




function getLetterScore(letter) {
  const scores = {
    'A': 1, 'B': 3, 'C': 4, 'Ç': 4, 'D': 3, 'E': 1,
    'F': 7, 'G': 5, 'Ğ': 8, 'H': 5, 'I': 2, 'İ': 1,
    'J': 10, 'K': 1, 'L': 1, 'M': 2, 'N': 1, 'O': 2,
    'Ö': 7, 'P': 5, 'R': 1, 'S': 2, 'Ş': 4, 'T': 1,
    'U': 2, 'Ü': 3, 'V': 7, 'Y': 3, 'Z': 4, 'JOKER': 0
  };
  return scores[letter.toUpperCase()] || 0;
}

app.get('/game/:id', authenticate, async (req, res) => {
  const gameId = parseInt(req.params.id);
  const userId = req.user.userId;

  try {
    const game = await prisma.game.findUnique({
      where: { id: gameId },
      include: { player1: true, player2: true }
    });

    if (!game) {
      return res.status(404).json({ error: 'Oyun bulunamadı.' });
    }

    // Kullanıcı bu oyunun bir parçası mı kontrolü:
    if (game.player1Id !== userId && game.player2Id !== userId) {
      return res.status(403).json({ error: 'Bu oyuna erişim izniniz yok.' });
    }

    res.json({
      gameId: game.id,
      boardState: game.boardState,
      currentTurnId: game.currentTurnId,
      player1: game.player1.username,
      player2: game.player2?.username ?? 'Bekleniyor...',
      status: game.status
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Oyun detayları (tahta durumu) getirme:
app.get('/game-details/:gameId', authenticate, async (req, res) => {
  const gameId = parseInt(req.params.gameId);
  const userId = req.user.userId;

  try {
    let game = await prisma.game.findUnique({
      where: { id: gameId },
      select: {
        id: true,
        player1Id: true,
        player2Id: true,
        currentTurnId: true,
        player1Letters: true,
        player2Letters: true,
        letterPool: true,
        boardState: true,
        mines: true,
        player1Rewards: true,
        player2Rewards: true,
        player1Score: true,
        player2Score: true,
        blockZone: true,
        frozenLettersOpponent: true,
        extraTurnUserId: true,
        duration: true,
        lastMoveTime: true,
        status: true,
        winnerId: true,
        player1: { select: { id: true, username: true } },
        player2: { select: { id: true, username: true } },
      },
    });

    if (!game) return res.status(404).json({ error: 'Oyun bulunamadı.' });

    // ✅ Zaman aşımı kontrolü (sadece aktif oyunlarda)
    if (game.status === 'active' && game.lastMoveTime) {
      const now = new Date();
      const lastMove = new Date(game.lastMoveTime);
      const diffMinutes = (now - lastMove) / (1000 * 60);

      if (diffMinutes > game.duration) {
        const opponentId = game.currentTurnId === game.player1Id ? game.player2Id : game.player1Id;

        await prisma.game.update({
          where: { id: gameId },
          data: {
            status: 'finished',
            winnerId: opponentId,
            endedAt: new Date(),
          },
        });

        await updateSuccessRates(prisma, {
          player1Id: game.player1Id,
          player2Id: game.player2Id,
          winnerId: userId
        });

        // Oyunu tekrar çekelim çünkü yukarıda update ettik
        game = await prisma.game.findUnique({
          where: { id: gameId },
          select: {
            id: true,
            player1Id: true,
            player2Id: true,
            currentTurnId: true,
            player1Letters: true,
            player2Letters: true,
            letterPool: true,
            boardState: true,
            mines: true,
            player1Rewards: true,
            player2Rewards: true,
            player1Score: true,
            player2Score: true,
            blockZone: true,
            frozenLettersOpponent: true,
            extraTurnUserId: true,
            duration: true,
            lastMoveTime: true,
            status: true,
            winnerId: true,
            player1: { select: { id: true, username: true } },
            player2: { select: { id: true, username: true } },
          },
        });
      }
    }

    const formattedMines = game.mines.map(mine => ({
      row: mine.row,
      col: mine.col,
      type: mine.type,
    }));

    const playerRewards = userId === game.player1Id
      ? (game.player1Rewards || [])
      : (game.player2Rewards || []);

    res.json({
      ...game,
      isPlayer1: game.player1Id === userId,
      player1: game.player1.username,
      player2: game.player2 ? game.player2.username : 'Bekleniyor...',
      player1Score: game.player1Score,
      player2Score: game.player2Id ? game.player2Score : 0,
      remainingLettersCount: game.letterPool ? game.letterPool.length : 0,
      mines: formattedMines,
      playerRewards: playerRewards,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


app.post('/pass-turn', authenticate, async (req, res) => {
  const { gameId } = req.body;
  const userId = req.user.userId;

  try {
    const game = await prisma.game.findUnique({ where: { id: gameId } });

    if (!game) return res.status(404).json({ error: 'Oyun bulunamadı.' });

    if (game.currentTurnId !== userId) {
      return res.status(403).json({ error: 'Sıra sizde değil.' });
    }

    const nextTurnId = userId === game.player1Id ? game.player2Id : game.player1Id;

    await prisma.game.update({
      where: { id: gameId },
      data: {
        currentTurnId: nextTurnId,
        lastMoveTime: new Date(),
      },
    });

    res.json({ message: 'Sıra başarıyla pas geçildi.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});


app.post('/surrender', authenticate, async (req, res) => {
  const { gameId } = req.body;
  const userId = req.user.userId;

  try {
    const game = await prisma.game.findUnique({ where: { id: gameId } });

    if (!game) return res.status(404).json({ error: 'Oyun bulunamadı.' });

    if (game.status === 'finished') {
      return res.status(400).json({ error: 'Oyun zaten bitmiş.' });
    }
    if (userId !== game.player1Id && userId !== game.player2Id) {
      return res.status(403).json({ error: 'Bu oyunda yetkiniz yok.' });
    }


    const opponentId = userId === game.player1Id ? game.player2Id : game.player1Id;

    await prisma.game.update({
      where: { id: gameId },
      data: {
        status: 'finished',
        winnerId: opponentId,
        endedAt: new Date(),
      },
    });
    await updateSuccessRates(prisma, {
      player1Id: game.player1Id,
      player2Id: game.player2Id,
      winnerId: opponentId
    });
    

    res.json({ message: 'Teslim oldunuz. Oyun sona erdi.',winnerId: opponentId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

app.get('/finished-games', authenticate, async (req, res) => {
  const userId = req.user.userId;

  try {
    const finishedGames = await prisma.game.findMany({
      where: {
        status: 'finished',
        OR: [
          { player1Id: userId },
          { player2Id: userId },
        ],
      },
      select: {
        id: true,
        player1Id: true,
        player2Id: true,
        player1Score: true,
        player2Score: true,
        winnerId: true,
        player1: { select: { username: true } },
        player2: { select: { username: true } },
      },
    });

    const gamesWithWinner = finishedGames.map(game => {
      let winner = 'Berabere';
      if (game.player1Score > game.player2Score) {
        winner = game.player1.username;
      } else if (game.player2Score > game.player1Score) {
        winner = game.player2.username;
      }
      return { ...game, winner };
    });

    res.json({ games: gamesWithWinner });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


async function updateSuccessRates(prisma, game) {
  const player1Id = game.player1Id;
  const player2Id = game.player2Id;
  const winnerId = game.winnerId;

  const player1 = await prisma.user.findUnique({ where: { id: player1Id } });
  const player2 = await prisma.user.findUnique({ where: { id: player2Id } });

  const totalGamesP1 = (player1.gamesPlayed || 0) + 1;
  const totalGamesP2 = (player2.gamesPlayed || 0) + 1;

  const winsP1 = winnerId === player1Id ? (player1.gamesWon || 0) + 1 : (player1.gamesWon || 0);
  const winsP2 = winnerId === player2Id ? (player2.gamesWon || 0) + 1 : (player2.gamesWon || 0);

  const rateP1 = Math.round((winsP1 / totalGamesP1) * 100);
  const rateP2 = Math.round((winsP2 / totalGamesP2) * 100);

  await prisma.user.update({
    where: { id: player1Id },
    data: {
      gamesPlayed: totalGamesP1,
      gamesWon: winsP1,
      successRate: rateP1,
    }
  });

  await prisma.user.update({
    where: { id: player2Id },
    data: {
      gamesPlayed: totalGamesP2,
      gamesWon: winsP2,
      successRate: rateP2,
    }
  });
}




app.get('/me', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      select: {
        username: true,
        successRate: true,
      },
    });

    if (!user) return res.status(404).json({ error: 'Kullanıcı bulunamadı.' });

    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});
