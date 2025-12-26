// Enhance provider: use LegalMoveGenerator, add selection and tap-to-move API.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/move.dart';
import '../../domain/usecases/minimax.dart';
import '../../data/move_generators/legal_move_generator.dart';
import '../../data/evaluators/material_evaluator.dart';

class BoardProvider extends ChangeNotifier {
  Board board;
  bool whiteToMove;
  // Game mode: vs AI or vs Player
  GameMode mode = GameMode.vsAI;
  // In vsAI: does human control white?
  bool humanControlsWhite = true;
  // UI selection
  int? selectedR;
  int? selectedC;
  List<ChessMove> legalMovesForSelected = const [];
  bool isCheckmate = false;
  String? checkmateWinner; // 'White' or 'Black'
  bool isStalemate = false;
  bool isDraw = false;
  String? drawReason; // e.g., 'Stalemate', 'Insufficient material'
  bool whiteInCheck = false;
  bool blackInCheck = false;

  BoardProvider({Board? initial})
      : board = initial ?? _startingBoard(),
        whiteToMove = true {
    _loadMode();
  }

  Future<void> computeAndApplyBestMove({int depth = 3}) async {
    if (isCheckmate) return;
    // Clear selection during AI move
    selectedR = null; selectedC = null; legalMovesForSelected = const [];
    notifyListeners();

    final payload = {
      'squares': board.squares,
      'isWhite': whiteToMove,
      'depth': depth,
    };
    final result = await compute<Map<String, dynamic>, Map<String, dynamic>>(
        _runSearch, payload);
    if (result['move'] != null) {
      final m = result['move'] as List<dynamic>;
      // Slightly longer pause so AI moves feel more natural
      await Future.delayed(const Duration(milliseconds: 380));
      _applyMove(ChessMove(m[0] as int, m[1] as int, m[2] as int, m[3] as int));
    }
  }

  void tapSquare(int r, int c) {
    if (isCheckmate) return;
    if (isDraw || isStalemate) return;
    // Prevent input during AI computing or when it's AI's turn in vsAI mode
    if (mode == GameMode.vsAI) {
      final isHumanTurn = (whiteToMove && humanControlsWhite) || (!whiteToMove && !humanControlsWhite);
      if (!isHumanTurn) return;
    }
    // If nothing selected, select if own piece
    final piece = board.pieceAt(r, c);
    final my = whiteToMove ? 'w' : 'b';
    if (selectedR == null || selectedC == null) {
      if (piece.isNotEmpty && piece[0] == my) {
        selectedR = r; selectedC = c;
        legalMovesForSelected = LegalMoveGenerator().generateMoves(board, whiteToMove)
            .where((m) => m.fromRank == r && m.fromFile == c).toList();
        notifyListeners();
      }
      return;
    }
    // If selected, try move
    final move = legalMovesForSelected.firstWhere(
      (m) => m.toRank == r && m.toFile == c,
      orElse: () => ChessMove(-1, -1, -1, -1),
    );
    if (move.fromRank != -1) {
      _applyMove(move);
      // If vs AI, after human move let AI play automatically
      if (mode == GameMode.vsAI) {
         // Fire-and-forget AI at default depth 3
         computeAndApplyBestMove(depth: 3);
       }
      return;
    }
    // Otherwise, reselect if tapping own piece
    if (piece.isNotEmpty && piece[0] == my) {
      selectedR = r; selectedC = c;
      legalMovesForSelected = LegalMoveGenerator().generateMoves(board, whiteToMove)
          .where((m) => m.fromRank == r && m.fromFile == c).toList();
      notifyListeners();
    } else {
      // clear selection
      selectedR = null; selectedC = null; legalMovesForSelected = const [];
      notifyListeners();
    }
  }

  void reset() {
    board = _startingBoard();
    whiteToMove = true;
    selectedR = null; selectedC = null; legalMovesForSelected = const [];
    isCheckmate = false;
    checkmateWinner = null;
    isStalemate = false;
    isDraw = false;
    drawReason = null;
    whiteInCheck = false;
    blackInCheck = false;
    notifyListeners();
  }
  // When starting as black vs AI, trigger AI's first move automatically.
  Future<void> startGameAutoIfAIToMove() async {
    // If vs AI and human controls black, AI should start
    final aiStarts = mode == GameMode.vsAI && !humanControlsWhite;
    if (aiStarts) {
      await computeAndApplyBestMove(depth: 3);
    }
  }

  void setMode(GameMode newMode) async {
    mode = newMode;
    // Clear selection; leave board as-is
    selectedR = null; selectedC = null; legalMovesForSelected = const [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game_mode', mode == GameMode.vsAI ? 'ai' : 'player');
  }

  void setHumanColor({required bool controlsWhite}) {
    humanControlsWhite = controlsWhite;
    selectedR = null; selectedC = null; legalMovesForSelected = const [];
    notifyListeners();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString('game_mode');
    if (m == 'player') {
      mode = GameMode.vsPlayer;
    } else {
      mode = GameMode.vsAI;
    }
    notifyListeners();
  }

  void _applyMove(ChessMove m) {
    // Reject any move that isn't legal (includes king-in-check filtering)
    final legal = LegalMoveGenerator().generateMoves(board, whiteToMove);
    final isLegal = legal.any((lm) =>
        lm.fromRank == m.fromRank &&
        lm.fromFile == m.fromFile &&
        lm.toRank == m.toRank &&
        lm.toFile == m.toFile &&
        (lm.promotion == m.promotion || (lm.promotion == null && m.promotion == null)) &&
        lm.isEnPassant == m.isEnPassant &&
        lm.isCastle == m.isCastle);
    if (!isLegal) {
      return; // ignore illegal attempt
    }
    final moving = board.pieceAt(m.fromRank, m.fromFile);
    final isPawn = moving.length > 1 && moving[1] == 'P';
    final lastRank = whiteToMove ? 7 : 0;
    if (isPawn && m.toRank == lastRank) {
      board.setPiece(m.toRank, m.toFile, (whiteToMove ? 'w' : 'b') + 'Q');
      board.setPiece(m.fromRank, m.fromFile, '');
    } else {
      board.applyMove(m);
    }
    whiteToMove = !whiteToMove;
    selectedR = null; selectedC = null; legalMovesForSelected = const [];
    _evaluateCheckmate();
    _evaluateStalemateOrDraw();
    _updateCheckStatus();
    notifyListeners();
  }

  void _evaluateCheckmate() {
    final gen = LegalMoveGenerator();
    final moves = gen.generateMoves(board, whiteToMove);
    final inCheck = gen.isInCheck(board, whiteToMove);
    if (inCheck && moves.isEmpty) {
      isCheckmate = true;
      checkmateWinner = whiteToMove ? 'Black' : 'White';
    }
  }

  void _evaluateStalemateOrDraw() {
    if (isCheckmate) return;
    final gen = LegalMoveGenerator();
    final moves = gen.generateMoves(board, whiteToMove);
    final inCheck = gen.isInCheck(board, whiteToMove);
    if (!inCheck && moves.isEmpty) {
      isStalemate = true;
      isDraw = true;
      drawReason = 'Stalemate';
      return;
    }
    if (_isInsufficientMaterial()) {
      isDraw = true;
      drawReason = 'Insufficient material';
    }
  }

  void _updateCheckStatus() {
    final gen = LegalMoveGenerator();
    whiteInCheck = gen.isInCheck(board, true);
    blackInCheck = gen.isInCheck(board, false);
  }

  bool _isInsufficientMaterial() {
    // Basic cases: K vs K; K+minor vs K; K+B vs K+B with same color bishops.
    final pieces = <String>[];
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board.pieceAt(r, c);
        if (p.isNotEmpty) pieces.add(p);
      }
    }
    // Only kings
    if (pieces.every((p) => p.endsWith('K'))) return true;

    // Count pieces
    final minors = pieces.where((p) => p.endsWith('B') || p.endsWith('N')).toList();
    final others = pieces.where((p) => !(p.endsWith('K') || p.endsWith('B') || p.endsWith('N'))).toList();

    // If any rooks, queens, pawns remain, not insufficient
    if (others.isNotEmpty) return false;

    // King + single minor vs King
    if (pieces.length == 3 && minors.length == 1) return true;

    // King + bishop vs King + bishop with same colored bishops
    if (pieces.length == 4 && minors.length == 2 && minors.every((m) => m.endsWith('B'))) {
      // Determine bishop square colors
      int? color1;
      int? color2;
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          final p = board.pieceAt(r, c);
          if (p.endsWith('B')) {
            final color = (r + c) % 2; // 0 light, 1 dark
            if (color1 == null) {
              color1 = color;
            } else {
              color2 = color;
            }
          }
        }
      }
      if (color1 != null && color2 != null && color1 == color2) {
        return true;
      }
    }

    return false;
  }

  static Map<String, dynamic> _runSearch(Map<String, dynamic> payload) {
    final squares = (payload['squares'] as List<dynamic>)
        .map((r) => (r as List<dynamic>).map((e) => e as String).toList())
        .toList();
    final board = Board(squares.cast<List<String>>());
    final isWhite = payload['isWhite'] as bool;
    final depth = payload['depth'] as int;

    final mm = Minimax(
      generator: LegalMoveGenerator(),
      evaluator: MaterialEvaluator(),
    );
    final res = mm.findBestMove(Board.clone(board), isWhite, depth);
    if (res.move == null) return {'move': null, 'score': res.score};
    final m = res.move!;
    return {
      'move': [m.fromRank, m.fromFile, m.toRank, m.toFile],
      'score': res.score,
    };
  }

  static Board _startingBoard() {
    final b = Board.empty();
    // Place full starting position
    for (var c = 0; c < 8; c++) { b.setPiece(1, c, 'wP'); b.setPiece(6, c, 'bP'); }
    b.setPiece(0, 0, 'wR'); b.setPiece(0, 7, 'wR');
    b.setPiece(7, 0, 'bR'); b.setPiece(7, 7, 'bR');
    b.setPiece(0, 1, 'wN'); b.setPiece(0, 6, 'wN');
    b.setPiece(7, 1, 'bN'); b.setPiece(7, 6, 'bN');
    b.setPiece(0, 2, 'wB'); b.setPiece(0, 5, 'wB');
    b.setPiece(7, 2, 'bB'); b.setPiece(7, 5, 'bB');
    b.setPiece(0, 3, 'wQ'); b.setPiece(7, 3, 'bQ');
    b.setPiece(0, 4, 'wK'); b.setPiece(7, 4, 'bK');
    return b;
  }
}

enum GameMode { vsAI, vsPlayer }
