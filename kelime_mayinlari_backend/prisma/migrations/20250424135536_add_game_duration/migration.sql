/*
  Warnings:

  - Added the required column `duration` to the `Game` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "Game" DROP CONSTRAINT "Game_player2Id_fkey";

-- AlterTable
ALTER TABLE "Game" ADD COLUMN     "duration" INTEGER NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'waiting',
ALTER COLUMN "player2Id" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "Game" ADD CONSTRAINT "Game_player2Id_fkey" FOREIGN KEY ("player2Id") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
