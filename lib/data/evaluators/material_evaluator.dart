import '../../domain/entities/board.dart';
import '../../domain/ports/evaluator.dart';

class MaterialEvaluator implements Evaluator {
  static const values = {
    'P': 100,
    'N': 320,
    'B': 330,
    'R': 500,
    'Q': 900,
    'K': 20000,
  };

  @override
  int evaluate(Board board) {
    var score = 0;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board.pieceAt(r, c);
        if (p.isEmpty) continue;
        final color = p[0];
        final type = p.length > 1 ? p[1] : ' ';
        final val = values[type] ?? 0;
        score += (color == 'w') ? val : -val;
      }
    }
    return score;
  }
}

