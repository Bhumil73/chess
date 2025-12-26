import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/board_provider.dart';
import 'presentation/pages/landing_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BoardProvider(),
      child: MaterialApp(
        home: const LandingPage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BoardProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chess - Clean Architecture')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Turn: ' + (prov.whiteToMove ? 'White' : 'Black') +
                  (prov.mode == GameMode.vsAI
                      ? ((prov.whiteToMove && prov.humanControlsWhite) || (!prov.whiteToMove && !prov.humanControlsWhite)
                          ? ' (You)'
                          : ' (AI)')
                      : ''),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Mode:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('vs AI'),
                  selected: prov.mode == GameMode.vsAI,
                  onSelected: (sel) {
                    if (sel) Provider.of<BoardProvider>(context, listen: false).setMode(GameMode.vsAI);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('vs Player'),
                  selected: prov.mode == GameMode.vsPlayer,
                  onSelected: (sel) {
                    if (sel) Provider.of<BoardProvider>(context, listen: false).setMode(GameMode.vsPlayer);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemBuilder: (ctx, idx) {
                final r = idx ~/ 8;
                final c = idx % 8;
                final p = prov.board.pieceAt(r, c);
                final isSelected = prov.selectedR == r && prov.selectedC == c;
                final isLegalTarget = prov.legalMovesForSelected.any((m) => m.toRank == r && m.toFile == c);
                final baseColor = ((r + c) % 2 == 0) ? Colors.brown[200]! : Colors.brown[400]!;
                final bgColor = isSelected ? Colors.yellowAccent : (isLegalTarget ? Colors.greenAccent : baseColor);
                return GestureDetector(
                  onTap: () {
                    if (prov.mode == GameMode.vsAI) {
                      final isHumanTurn = (prov.whiteToMove && prov.humanControlsWhite) || (!prov.whiteToMove && !prov.humanControlsWhite);
                      if (!isHumanTurn) return;
                    }
                    prov.tapSquare(r, c);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    color: bgColor,
                    child: Center(child: Text(_unicodeForPiece(p), style: const TextStyle(fontSize: 24))),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (prov.mode == GameMode.vsAI)
                  ElevatedButton(
                    onPressed: () => prov.computeAndApplyBestMove(depth: 3),
                    child: const Text('AI Move (depth 3)'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<BoardProvider>(context, listen: false).reset();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          )
        ],
      ),
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
