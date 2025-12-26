import '../../domain/entities/board.dart';
import '../../domain/entities/move.dart';
import '../../domain/ports/move_generator.dart';

/// Full(ish) legal move generator: per-piece moves with check filtering.
/// Assumptions: board.squares entries like 'wP', 'bK'. No castling/en passant.
/// Promotions: pawn promotes to Queen automatically on final rank.
class LegalMoveGenerator implements MoveGenerator {
  @override
  List<ChessMove> generateMoves(Board board, bool isWhite) {
    final moves = <ChessMove>[];
    final my = isWhite ? 'w' : 'b';
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board.pieceAt(r, c);
        if (p.isEmpty || p[0] != my) continue;
        final type = p[1];
        switch (type) {
          case 'P':
            _pawnMoves(board, isWhite, r, c, moves);
            break;
          case 'N':
            _knightMoves(board, isWhite, r, c, moves);
            break;
          case 'B':
            _sliderMoves(board, isWhite, r, c, moves, const [
              [1, 1], [1, -1], [-1, 1], [-1, -1]
            ]);
            break;
          case 'R':
            _sliderMoves(board, isWhite, r, c, moves, const [
              [1, 0], [-1, 0], [0, 1], [0, -1]
            ]);
            break;
          case 'Q':
            _sliderMoves(board, isWhite, r, c, moves, const [
              [1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]
            ]);
            break;
          case 'K':
            _kingMoves(board, isWhite, r, c, moves);
            break;
        }
      }
    }
    // Filter out moves that leave king in check
    return moves.where((m) {
      final b2 = Board.clone(board);
      _applyMoveInternal(b2, m, isWhite);
      return !_isKingInCheck(b2, isWhite);
    }).toList();
  }

  void _pawnMoves(Board board, bool isWhite, int r, int c, List<ChessMove> out) {
    final dir = isWhite ? 1 : -1;
    final startRank = isWhite ? 1 : 6;
    // Forward one
    final r1 = r + dir;
    if (_inBounds(r1, c) && board.pieceAt(r1, c).isEmpty) {
      final isPromo = (isWhite && r1 == 7) || (!isWhite && r1 == 0);
      if (isPromo) {
        for (final promo in const ['Q', 'R', 'B', 'N']) {
          out.add(ChessMove(r, c, r1, c, promotion: promo));
        }
      } else {
        out.add(ChessMove(r, c, r1, c));
      }
      // Forward two from start
      final r2 = r + 2 * dir;
      if (r == startRank && board.pieceAt(r2, c).isEmpty) {
        out.add(ChessMove(r, c, r2, c));
      }
    }
    // Captures
    for (final dc in const [1, -1]) {
      final rr = r + dir;
      final cc = c + dc;
      if (_inBounds(rr, cc)) {
        final t = board.pieceAt(rr, cc);
        if (t.isNotEmpty && t[0] != (isWhite ? 'w' : 'b') && !_isOpponentKing(t)) {
          final isPromo = (isWhite && rr == 7) || (!isWhite && rr == 0);
          if (isPromo) {
            for (final promo in const ['Q', 'R', 'B', 'N']) {
              out.add(ChessMove(r, c, rr, cc, promotion: promo));
            }
          } else {
            out.add(ChessMove(r, c, rr, cc));
          }
        }
      }
    }
    // En passant captures
    if (board.enPassantFile != null) {
      final targetFile = board.enPassantFile!;
      final rr = r + dir;
      if ((c - targetFile).abs() == 1 && rr == (isWhite ? 5 : 2)) {
        out.add(ChessMove(r, c, rr, targetFile, isEnPassant: true));
      }
    }
    // Promotions handled on apply (auto to Queen)
  }

  void _knightMoves(Board board, bool isWhite, int r, int c, List<ChessMove> out) {
    const jumps = [
      [2, 1], [2, -1], [-2, 1], [-2, -1],
      [1, 2], [1, -2], [-1, 2], [-1, -2]
    ];
    for (final j in jumps) {
      final rr = r + j[0], cc = c + j[1];
      if (!_inBounds(rr, cc)) continue;
      final t = board.pieceAt(rr, cc);
      if (t.isEmpty || (t[0] != (isWhite ? 'w' : 'b') && !_isOpponentKing(t))) {
        out.add(ChessMove(r, c, rr, cc));
      }
    }
  }

  void _sliderMoves(Board board, bool isWhite, int r, int c, List<ChessMove> out, List<List<int>> dirs) {
    for (final d in dirs) {
      var rr = r + d[0], cc = c + d[1];
      while (_inBounds(rr, cc)) {
        final t = board.pieceAt(rr, cc);
        if (t.isEmpty) {
          out.add(ChessMove(r, c, rr, cc));
        } else {
          if (t[0] != (isWhite ? 'w' : 'b') && !_isOpponentKing(t)) {
            out.add(ChessMove(r, c, rr, cc));
          }
          break; // blocked
        }
        rr += d[0];
        cc += d[1];
      }
    }
  }

  void _kingMoves(Board board, bool isWhite, int r, int c, List<ChessMove> out) {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = r + dr, cc = c + dc;
        if (!_inBounds(rr, cc)) continue;
        final t = board.pieceAt(rr, cc);
        if (t.isEmpty || (t[0] != (isWhite ? 'w' : 'b') && !_isOpponentKing(t))) {
          out.add(ChessMove(r, c, rr, cc));
        }
      }
    }
    // Castling: check rook/king moved flags and empty/unattacked squares
    if (isWhite && !board.whiteKingMoved) {
      // King side: squares (0,5) and (0,6) must be empty and not under attack
      if (!board.whiteKingsideRookMoved && board.pieceAt(0, 5).isEmpty && board.pieceAt(0, 6).isEmpty) {
        // king cannot be in check, and cannot pass through check
        if (!_isKingInCheck(board, true)) {
          final b1 = Board.clone(board);
          b1.applyMove(ChessMove(0, 4, 0, 5));
          if (!_isKingInCheck(b1, true)) {
            out.add(ChessMove(0, 4, 0, 6, isCastle: true));
          }
        }
      }
      // Queen side: squares (0,1)-(0,3) empty
      if (!board.whiteQueensideRookMoved && board.pieceAt(0, 1).isEmpty && board.pieceAt(0, 2).isEmpty && board.pieceAt(0, 3).isEmpty) {
        if (!_isKingInCheck(board, true)) {
          final b1 = Board.clone(board);
          b1.applyMove(ChessMove(0, 4, 0, 3));
          if (!_isKingInCheck(b1, true)) {
            out.add(ChessMove(0, 4, 0, 2, isCastle: true));
          }
        }
      }
    } else if (!isWhite && !board.blackKingMoved) {
      // King side: squares (7,5) and (7,6)
      if (!board.blackKingsideRookMoved && board.pieceAt(7, 5).isEmpty && board.pieceAt(7, 6).isEmpty) {
        if (!_isKingInCheck(board, false)) {
          final b1 = Board.clone(board);
          b1.applyMove(ChessMove(7, 4, 7, 5));
          if (!_isKingInCheck(b1, false)) {
            out.add(ChessMove(7, 4, 7, 6, isCastle: true));
          }
        }
      }
      // Queen side: squares (7,1)-(7,3)
      if (!board.blackQueensideRookMoved && board.pieceAt(7, 1).isEmpty && board.pieceAt(7, 2).isEmpty && board.pieceAt(7, 3).isEmpty) {
        if (!_isKingInCheck(board, false)) {
          final b1 = Board.clone(board);
          b1.applyMove(ChessMove(7, 4, 7, 3));
          if (!_isKingInCheck(b1, false)) {
            out.add(ChessMove(7, 4, 7, 2, isCastle: true));
          }
        }
      }
    }
  }

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  void _applyMoveInternal(Board b, ChessMove m, bool isWhite) {
    final moving = b.pieceAt(m.fromRank, m.fromFile);
    // Promotion: if pawn reaches last rank, turn into Queen
    final isPawn = moving.length > 1 && moving[1] == 'P';
    final lastRank = isWhite ? 7 : 0;
    if (isPawn && m.toRank == lastRank) {
      final promo = m.promotion ?? 'Q';
      b.setPiece(m.toRank, m.toFile, (isWhite ? 'w' : 'b') + promo);
      b.setPiece(m.fromRank, m.fromFile, '');
    } else {
      // En passant capture
      if (m.isEnPassant) {
        b.setPiece(m.toRank, m.toFile, moving);
        b.setPiece(m.fromRank, m.fromFile, '');
        // remove captured pawn behind the target square
        final capRank = isWhite ? m.toRank - 1 : m.toRank + 1;
        b.setPiece(capRank, m.toFile, '');
      } else if (m.isCastle) {
        // Move king
        b.applyMove(ChessMove(m.fromRank, m.fromFile, m.toRank, m.toFile));
        // Move rook accordingly
        if (isWhite && m.toRank == 0 && m.toFile == 6) {
          // white king side: rook 0,7 -> 0,5
          b.applyMove(ChessMove(0, 7, 0, 5));
        } else if (isWhite && m.toRank == 0 && m.toFile == 2) {
          // white queen side: rook 0,0 -> 0,3
          b.applyMove(ChessMove(0, 0, 0, 3));
        } else if (!isWhite && m.toRank == 7 && m.toFile == 6) {
          // black king side: rook 7,7 -> 7,5
          b.applyMove(ChessMove(7, 7, 7, 5));
        } else if (!isWhite && m.toRank == 7 && m.toFile == 2) {
          // black queen side: rook 7,0 -> 7,3
          b.applyMove(ChessMove(7, 0, 7, 3));
        }
      } else {
        b.applyMove(m);
      }
    }
    // Update castling/en passant state
    if (moving == 'wK') b.whiteKingMoved = true;
    if (moving == 'bK') b.blackKingMoved = true;
    if (moving == 'wR' && m.fromRank == 0 && m.fromFile == 0) b.whiteQueensideRookMoved = true;
    if (moving == 'wR' && m.fromRank == 0 && m.fromFile == 7) b.whiteKingsideRookMoved = true;
    if (moving == 'bR' && m.fromRank == 7 && m.fromFile == 0) b.blackQueensideRookMoved = true;
    if (moving == 'bR' && m.fromRank == 7 && m.fromFile == 7) b.blackKingsideRookMoved = true;
    // Set en-passant file if a double pawn push occurred
    if (isPawn && (m.toRank - m.fromRank).abs() == 2) {
      b.enPassantFile = m.fromFile;
    } else {
      b.enPassantFile = null;
    }
  }

  bool _isKingInCheck(Board b, bool isWhite) {
    final my = isWhite ? 'w' : 'b';
    final opp = isWhite ? 'b' : 'w';
    // locate king
    int kr = -1, kc = -1;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = b.pieceAt(r, c);
        if (p == '${my}K') { kr = r; kc = c; break; }
      }
    }
    if (kr == -1) return true; // king missing -> treat as in check (illegal)
    // Check attacks from all opponent pieces
    // Pawns
    final pawnDir = isWhite ? -1 : 1; // opponent pawns move opposite
    for (final dc in const [1, -1]) {
      final rr = kr + pawnDir, cc = kc + dc;
      if (_inBounds(rr, cc) && b.pieceAt(rr, cc) == opp + 'P') return true;
    }
    // Knights
    const jumps = [
      [2, 1], [2, -1], [-2, 1], [-2, -1],
      [1, 2], [1, -2], [-1, 2], [-1, -2]
    ];
    for (final j in jumps) {
      final rr = kr + j[0], cc = kc + j[1];
      if (_inBounds(rr, cc) && b.pieceAt(rr, cc) == opp + 'N') return true;
    }
    // Bishops/Queens (diagonals)
    if (_rayThreat(b, kr, kc, opp, const [
      [1, 1], [1, -1], [-1, 1], [-1, -1]
    ], {'B', 'Q'})) return true;
    // Rooks/Queens (orthogonals)
    if (_rayThreat(b, kr, kc, opp, const [
      [1, 0], [-1, 0], [0, 1], [0, -1]
    ], {'R', 'Q'})) return true;
    // King (adjacent)
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = kr + dr, cc = kc + dc;
        if (_inBounds(rr, cc) && b.pieceAt(rr, cc) == opp + 'K') return true;
      }
    }
    return false;
  }

  bool _rayThreat(Board b, int kr, int kc, String opp, List<List<int>> dirs, Set<String> types) {
    for (final d in dirs) {
      var rr = kr + d[0], cc = kc + d[1];
      while (_inBounds(rr, cc)) {
        final t = b.pieceAt(rr, cc);
        if (t.isNotEmpty) {
          if (t[0] == opp && types.contains(t[1])) return true;
          break;
        }
        rr += d[0];
        cc += d[1];
      }
    }
    return false;
  }

  // Expose check detection for consumers (e.g., checkmate logic)
  bool isInCheck(Board board, bool isWhite) => _isKingInCheck(board, isWhite);

  bool _isOpponentKing(String piece) => piece.endsWith('K');
}
