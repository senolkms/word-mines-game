/*
  Warnings:

  - You are about to drop the column `player1Jokers` on the `Game` table. All the data in the column will be lost.
  - You are about to drop the column `player2Jokers` on the `Game` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Game" DROP COLUMN "player1Jokers",
DROP COLUMN "player2Jokers",
ADD COLUMN     "player1Rewards" JSONB,
ADD COLUMN     "player2Rewards" JSONB;
