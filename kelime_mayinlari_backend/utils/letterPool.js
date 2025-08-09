// Harf sayıları ve puanları tabloya göre:
// Harf sayıları ve puanları tabloya göre:
const letterPoolConfig = [
  { letter: 'A', count: 12, score: 1 },
  { letter: 'B', count: 2, score: 3 },
  { letter: 'C', count: 2, score: 4 },
  { letter: 'Ç', count: 2, score: 4 },
  { letter: 'D', count: 2, score: 3 },
  { letter: 'E', count: 8, score: 1 },
  { letter: 'F', count: 1, score: 7 },
  { letter: 'G', count: 1, score: 5 },
  { letter: 'Ğ', count: 1, score: 8 },
  { letter: 'H', count: 1, score: 5 },
  { letter: 'I', count: 4, score: 2 },
  { letter: 'İ', count: 7, score: 1 },
  { letter: 'J', count: 1, score: 10 },
  { letter: 'K', count: 7, score: 1 },
  { letter: 'L', count: 7, score: 1 },
  { letter: 'M', count: 4, score: 2 },
  { letter: 'N', count: 5, score: 1 },
  { letter: 'O', count: 3, score: 2 },
  { letter: 'Ö', count: 1, score: 7 },
  { letter: 'P', count: 1, score: 5 },
  { letter: 'R', count: 6, score: 1 },
  { letter: 'S', count: 3, score: 2 },
  { letter: 'Ş', count: 2, score: 4 },
  { letter: 'T', count: 5, score: 1 },
  { letter: 'U', count: 3, score: 2 },
  { letter: 'Ü', count: 2, score: 3 },
  { letter: 'V', count: 1, score: 7 },
  { letter: 'Y', count: 2, score: 3 },
  { letter: 'Z', count: 2, score: 4 },
  { letter: 'JOKER', count: 2, score: 0 }
];

// 🎲 Havuz oluştur (karıştırılmış):
function createLetterPool() {
  let pool = [];
  letterPoolConfig.forEach(item => {
    pool.push(...Array(item.count).fill(item.letter));
  });
  return shuffle(pool);
}

// 🔀 Karıştırma fonksiyonu:
function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

// 🎯 Havuzdan rastgele harf çekme:
function drawLetters(pool, count) {
  const drawn = [];
  for (let i = 0; i < count; i++) {
    if (pool.length === 0) break;
    const index = Math.floor(Math.random() * pool.length);
    drawn.push(pool.splice(index, 1)[0]); // Çekilen harfi havuzdan çıkarıyoruz
  }
  return { drawn, pool };
}

module.exports = { createLetterPool, drawLetters, letterPoolConfig };
  
  // 🎲 Havuz oluştur (karıştırılmış):
  function createLetterPool() {
    let pool = [];
    letterPoolConfig.forEach(item => {
      pool.push(...Array(item.count).fill(item.letter));
    });
    return shuffle(pool);
  }
  
  // 🔀 Karıştırma fonksiyonu:
  function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
  }
  


  function drawLetters(pool, count) {
    const drawn = [];
    let totalJokersDrawn = 0;
  
    while (drawn.length < count && pool.length > 0) {
      const index = Math.floor(Math.random() * pool.length);
      const letter = pool[index];
  
      // Joker limiti kontrolü (maksimum 2 tane sistem genelinde)
      if (letter === 'JOKER') {
        if (totalJokersDrawn >= 2) {
          // Havuzda sadece JOKER kalmışsa çık
          if (pool.every(l => l === 'JOKER')) break;
          // Aksi halde başka harf aramaya devam et
          pool.splice(index, 1); // bu jokeri havuzdan çıkar ama ekleme
          continue;
        }
        totalJokersDrawn++;
      }
  
      drawn.push(letter);
      pool.splice(index, 1);
    }
  
    return { drawn, pool };
  }
  
  
  
  
  module.exports = { createLetterPool, drawLetters, letterPoolConfig };
  