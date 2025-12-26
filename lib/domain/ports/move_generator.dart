import '../entities/board.dart';
import '../entities/move.dart';

abstract class MoveGenerator {
  List<ChessMove> generateMoves(Board board, bool isWhite);
}

