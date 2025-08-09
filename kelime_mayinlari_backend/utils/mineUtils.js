// utils/mineUtils.js

const mineTypes = [
  { type: 'puanBolunmesi', count: 5 },
  { type: 'puanTransferi', count: 4 },
  { type: 'harfKaybi', count: 3 },
  { type: 'ekstraHamleEngeli', count: 2 },
  { type: 'kelimeIptali', count: 2 },
  { type: 'bolgeYasagi', count: 2 },
  { type: 'harfYasagi', count: 3 },
  { type: 'ekstraHamleJokeri', count: 2 },
];

function generateMines() {
  return [
    { row: 0, col: 3, type: 'harf_yasagi' },
    { row: 0, col: 14, type: 'puan_transferi' },
    { row: 1, col: 10, type: 'kelime_iptali' },
    { row: 2, col: 5, type: 'harf_kaybi' },
    { row: 3, col: 1, type: 'puan_transferi' },
    { row: 3, col: 12, type: 'puan_transferi' },
    { row: 4, col: 8, type: 'puan_bolunmesi' },
    { row: 5, col: 6, type: 'hamle_engeli' },
    { row: 5, col: 11, type: 'ekstra_hamle_jokeri' },
    { row: 6, col: 3, type: 'harf_kaybi' },
    { row: 7, col: 9, type: 'puan_bolunmesi' },
    { row: 7, col: 14, type: 'bolge_yasagi' },     
    { row: 8, col: 3, type: 'puan_bolunmesi' },
    { row: 9, col: 5, type: 'harf_yasagi' },     
    { row: 9, col: 10, type: 'bolge_yasagi' },
    { row: 10, col: 4, type: 'puan_bolunmesi' },
    { row: 10, col: 13, type: 'harf_kaybi' },
    { row: 11, col: 7, type: 'puan_transferi' },
    { row: 12, col: 10, type: 'hamle_engeli' },
    { row: 13, col: 5, type: 'harf_yasagi' },
    { row: 13, col: 12, type: 'puan_bolunmesi' },
    { row: 14, col: 2, type: 'kelime_iptali' },
    { row: 14, col: 7, type: 'ekstra_hamle_jokeri' },    
  ];
}

module.exports = { generateMines };