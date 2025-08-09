const fs = require('fs');
const path = require('path');

const wordList = fs
  .readFileSync(path.join(__dirname, 'wordList.txt'), 'utf-8')
  .split('\n')
  .map(word => word.trim().toLocaleUpperCase('tr-TR'))  // ← TR çözümü burada!
  .filter(Boolean);

module.exports = wordList;