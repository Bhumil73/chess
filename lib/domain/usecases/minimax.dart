import '../entities/board.dart';
import '../entities/move.dart';
import '../ports/move_generator.dart';
import '../ports/evaluator.dart';

class MinimaxResult {
  final ChessMove? move;
  final int score;
  MinimaxResult(this.move, this.score);
}

class Minimax {
  final MoveGenerator generator;
  final Evaluator evaluator;
  Minimax({required this.generator, required this.evaluator});

  MinimaxResult findBestMove(Board board, bool isWhiteToMove, int depth) {
    ChessMove? best;
    if (isWhiteToMove) {
      var bestScore = -999999;
      for (var m in generator.generateMoves(board, true)) {
        final b2 = Board.clone(board);
        b2.applyMove(m);
        final score = _search(b2, depth - 1, false, -1000000, 1000000);
        if (score > bestScore) {
          bestScore = score;
          best = m;
        }
      }
      return MinimaxResult(best, bestScore);
    } else {
      var bestScore = 999999;
      for (var m in generator.generateMoves(board, false)) {
        final b2 = Board.clone(board);
        b2.applyMove(m);
        final score = _search(b2, depth - 1, true, -1000000, 1000000);
        if (score < bestScore) {
          bestScore = score;
          best = m;
        }
      }
      return MinimaxResult(best, bestScore);
    }
  }

  int _search(Board board, int depth, bool isWhiteToMove, int alpha, int beta) {
    if (depth == 0) return evaluator.evaluate(board);
    final moves = generator.generateMoves(board, isWhiteToMove);
    if (moves.isEmpty) return evaluator.evaluate(board);

    if (isWhiteToMove) {
      var value = -999999;
      for (var m in moves) {
        final b2 = Board.clone(board);
        b2.applyMove(m);
        final child = _search(b2, depth - 1, false, alpha, beta);
        if (child > value) value = child;
        if (value > alpha) alpha = value;
        if (alpha >= beta) break;
      }
      return value;
    } else {
      var value = 999999;
      for (var m in moves) {
        final b2 = Board.clone(board);
        b2.applyMove(m);
        final child = _search(b2, depth - 1, true, alpha, beta);
        if (child < value) value = child;
        if (value < beta) beta = value;
        if (alpha >= beta) break;
      }
      return value;
    }
  }
}

