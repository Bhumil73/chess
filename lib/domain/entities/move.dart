// Extend move to support special flags (castling, en passant, promotion)
class ChessMove {
  final int fromRank;
  final int fromFile;
  final int toRank;
  final int toFile;
  final bool isCastle;
  final bool isEnPassant;
  final String? promotion; // e.g., 'Q'

  ChessMove(this.fromRank, this.fromFile, this.toRank, this.toFile,
      {this.isCastle = false, this.isEnPassant = false, this.promotion});

  @override
  String toString() => '$fromRank,$fromFile -> $toRank,$toFile';
}
