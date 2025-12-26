// Extend Board with state for castling and en passant.
import 'move.dart';

class Board {
  final List<List<String>> squares;
  bool whiteKingMoved = false;
  bool whiteKingsideRookMoved = false;
  bool whiteQueensideRookMoved = false;
  bool blackKingMoved = false;
  bool blackKingsideRookMoved = false;
  bool blackQueensideRookMoved = false;
  int? enPassantFile; // file (0-7) where en passant capture is possible on next move

  Board(this.squares);

  Board.empty() : squares = List.generate(8, (_) => List.generate(8, (_) => ''));

  Board.clone(Board other)
      : squares = other.squares.map((r) => List<String>.from(r)).toList() {
    whiteKingMoved = other.whiteKingMoved;
    whiteKingsideRookMoved = other.whiteKingsideRookMoved;
    whiteQueensideRookMoved = other.whiteQueensideRookMoved;
    blackKingMoved = other.blackKingMoved;
    blackKingsideRookMoved = other.blackKingsideRookMoved;
    blackQueensideRookMoved = other.blackQueensideRookMoved;
    enPassantFile = other.enPassantFile;
  }

  String pieceAt(int r, int c) => squares[r][c];

  void setPiece(int r, int c, String p) => squares[r][c] = p;

  void applyMove(ChessMove m) {
    final p = pieceAt(m.fromRank, m.fromFile);
    setPiece(m.toRank, m.toFile, p);
    setPiece(m.fromRank, m.fromFile, '');
  }
}
