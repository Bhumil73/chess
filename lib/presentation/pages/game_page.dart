import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import 'landing_page.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});
  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BoardProvider>(context);
    final humanWhitePerspective = prov.mode == GameMode.vsAI ? prov.humanControlsWhite : true;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Provider.of<BoardProvider>(context, listen: false).reset();
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9F4), // Off-white paper color
        appBar: AppBar(
          backgroundColor: const Color(0xFFFBF9F4),
          elevation: 0,
          title: Text(
            'Paper Chess',
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'serif',
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Provider.of<BoardProvider>(context, listen: false).reset();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
            },
          ),
        ),
        body: Column(
          children: [
            // Turn and Status Info Card - Compact
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F4),
                border: Border.all(color: Colors.black87, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Turn: ${prov.whiteToMove ? 'White' : 'Black'}${prov.mode == GameMode.vsAI
                        ? ((prov.whiteToMove && prov.humanControlsWhite) || (!prov.whiteToMove && !prov.humanControlsWhite)
                            ? ' (You)'
                            : ' (AI)')
                        : ''}',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (prov.whiteInCheck || prov.blackInCheck)
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Check!',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // 3D Chess Board - Takes most of the page
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back face (3D depth)
                        Positioned(
                          right: -2,
                          bottom: -3,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[500],
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(5, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Front face (chess board)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF9F4),
                            border: Border.all(
                              color: Colors.black87,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 4,
                                offset: const Offset(4, 5),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 2,
                                offset: const Offset(-2, -2),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: 64,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                              itemBuilder: (ctx, idx) {
                                final uiR = idx ~/ 8;
                                final uiC = idx % 8;
                                // Map UI coordinates to board coordinates based on human color perspective
                                final boardR = humanWhitePerspective ? 7 - uiR : uiR;
                                final boardC = humanWhitePerspective ? 7 - uiC : uiC;
                                final p = prov.board.pieceAt(boardR, boardC);
                                final isSelected = prov.selectedR == boardR && prov.selectedC == boardC;
                                final isLegalTarget = prov.legalMovesForSelected.any((m) => m.toRank == boardR && m.toFile == boardC);
                                final isWhiteKing = p == 'wK';
                                final isBlackKing = p == 'bK';
                                final kingInCheck = (isWhiteKing && prov.whiteInCheck) || (isBlackKing && prov.blackInCheck);
                                final baseColor = ((uiR + uiC) % 2 == 0) ? const Color(0xFFF5F1E8) : Colors.grey[400]!;
                                final bgColor = isSelected ? Colors.yellow[100]! : (isLegalTarget ? Colors.green[200]! : baseColor);
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeInOut,
                                  decoration: kingInCheck
                                      ? BoxDecoration(
                                          color: bgColor,
                                          border: Border.all(color: Colors.red, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ],
                                        )
                                      : BoxDecoration(color: bgColor),
                                  child: InkWell(
                                    onTap: () {
                                      if (prov.mode == GameMode.vsAI) {
                                        final isHumanTurn = (prov.whiteToMove && prov.humanControlsWhite) || (!prov.whiteToMove && !prov.humanControlsWhite);
                                        if (!isHumanTurn) return;
                                      }
                                      prov.tapSquare(boardR, boardC);
                                    },
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 180),
                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                      child: Text(
                                        _unicodeForPiece(p),
                                        key: ValueKey(p + boardR.toString() + boardC.toString()),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (prov.isCheckmate)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedOpacity(
                                    opacity: 1,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Checkmate!', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${prov.checkmateWinner ?? 'Winner'} wins',
                                              style: const TextStyle(fontSize: 20, color: Colors.white70),
                                            ),
                                            const SizedBox(height: 16),
                                            TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0, end: 1),
                                              duration: const Duration(milliseconds: 800),
                                              builder: (context, value, child) => Transform.scale(scale: 0.8 + 0.2 * value, child: child),
                                              child: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () => Provider.of<BoardProvider>(context, listen: false).reset(),
                                              child: const Text('Play Again'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Action Buttons - Compact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Commented out AI Move button
                  // if (prov.mode == GameMode.vsAI)
                  //   _build3DButton(
                  //     onPressed: () => prov.computeAndApplyBestMove(depth: 3),
                  //     label: 'AI Move',
                  //   ),
                  // if (prov.mode == GameMode.vsAI) const SizedBox(width: 12),
                  _build3DButton(
                    onPressed: () => Provider.of<BoardProvider>(context, listen: false).reset(),
                    label: 'Reset Game',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DButton({required VoidCallback onPressed, required String label}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Back face
        Positioned(
          right: -3,
          bottom: -4,
          child: Container(
            width: 120,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              border: Border.all(
                color: Colors.black87,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        // Front face
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black87,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _unicodeForPiece(String p) {
    switch (p) {
      case 'wK': return '♔';
      case 'wQ': return '♕';
      case 'wR': return '♖';
      case 'wB': return '♗';
      case 'wN': return '♘';
      case 'wP': return '♙';
      case 'bK': return '♚';
      case 'bQ': return '♛';
      case 'bR': return '♜';
      case 'bB': return '♝';
      case 'bN': return '♞';
      case 'bP': return '♟';
      default: return '';
    }
  }
}
