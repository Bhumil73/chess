import '../../domain/entities/board.dart';
import '../../domain/entities/move.dart';
import '../../domain/ports/move_generator.dart';

class SimpleMoveGenerator implements MoveGenerator {
  @override
  List<ChessMove> generateMoves(Board board, bool isWhite) {
    final moves = <ChessMove>[];
    final myPrefix = isWhite ? 'w' : 'b';
    final oppPrefix = isWhite ? 'b' : 'w';
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board.pieceAt(r, c);
        if (p.isEmpty) continue;
        if (!p.startsWith(myPrefix)) continue;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = r + dr, nc = c + dc;
            if (nr < 0 || nr > 7 || nc < 0 || nc > 7) continue;
            final target = board.pieceAt(nr, nc);
            if (target.isEmpty || target.startsWith(oppPrefix)) {
              moves.add(ChessMove(r, c, nr, nc));
            }
          }
        }
      }
    }
    return moves;
  }
}

