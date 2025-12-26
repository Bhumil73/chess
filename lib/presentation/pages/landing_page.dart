import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import 'game_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  bool _vsAiSelected = true;
  bool _humanIsWhite = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getPieceAt(int r, int c) {
    // Starting chess position
    if (r == 0) {
      return ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'][c];
    } else if (r == 1) {
      return '♙';
    } else if (r == 6) {
      return '♟';
    } else if (r == 7) {
      return ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'][c];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BoardProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 0,
        title: const Text(''),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBF9F4), // Off-white paper color
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hand-drawn style chess board with 3D effect
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, child) => Transform.scale(
                        scale: 0.8 + 0.2 * value,
                        child: Opacity(opacity: value, child: child),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Front face (chess board)
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF9F4),
                            ),
                            child: GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              crossAxisCount: 8,
                              children: List.generate(64, (idx) {
                                final r = idx ~/ 8;
                                final c = idx % 8;
                                final isLight = (r + c) % 2 == 0;
                                final piece = _getPieceAt(r, c);
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isLight ? const Color(0xFFF5F1E8) : Colors.grey[300],
                                    border: Border.all(
                                      color: Colors.grey[600]!,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      piece,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Hero(
                      tag: 'app-title',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          'Paper Chess',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 1.5,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Controls area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Game Mode Card with 3D cuboid effect
                          _build3DCuboidCard(
                            child: Column(
                              children: [
                                Text(
                                  'Choose Game Mode',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontFamily: 'serif',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ToggleButtons(
                                  borderRadius: BorderRadius.circular(6),
                                  fillColor: const Color(0xFFE8E4D8),
                                  selectedColor: Colors.black87,
                                  color: Colors.black54,
                                  borderColor: Colors.black87,
                                  selectedBorderColor: Colors.black87,
                                  disabledBorderColor: Colors.black26,
                                  isSelected: [_vsAiSelected, !_vsAiSelected],
                                  onPressed: (i) {
                                    setState(() {
                                      _vsAiSelected = (i == 0);
                                    });
                                  },
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Text('vs Computer', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Text('vs Player', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Color Selection Card with 3D cuboid effect
                          AnimatedOpacity(
                            opacity: _vsAiSelected ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: _vsAiSelected
                                ? _build3DCuboidCard(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Choose Your Color',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            fontFamily: 'serif',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ToggleButtons(
                                          borderRadius: BorderRadius.circular(6),
                                          fillColor: const Color(0xFFE8E4D8),
                                          selectedColor: Colors.black87,
                                          color: Colors.black54,
                                          borderColor: Colors.black87,
                                          selectedBorderColor: Colors.black87,
                                          disabledBorderColor: Colors.black26,
                                          isSelected: [_humanIsWhite, !_humanIsWhite],
                                          onPressed: (i) {
                                            setState(() {
                                              _humanIsWhite = (i == 0);
                                            });
                                          },
                                          children: const [
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              child: Text('White', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              child: Text('Black', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // 3D Cuboid Start Game button
                    _build3DCuboidButton(
                      onPressed: () async {
                        if (_vsAiSelected) {
                          prov.setMode(GameMode.vsAI);
                          prov.setHumanColor(controlsWhite: _humanIsWhite);
                        } else {
                          prov.setMode(GameMode.vsPlayer);
                        }
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GamePage()));
                        if (_vsAiSelected && !_humanIsWhite) {
                          await prov.startGameAutoIfAIToMove();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DCuboidCard({required Widget child}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Back face
        Positioned(
          right: -3,
          bottom: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 250),
            decoration: BoxDecoration(
              color: Colors.grey[500],
              border: Border.all(
                color: Colors.black87,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 20,
                  spreadRadius: 20,
                  offset: const Offset(4, 6),
                ),
              ],
            ),
          ),
        ),
        // Right edge
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 8,
            height: 80,
            color: Colors.grey[700],
          ),
        ),
        // Bottom edge
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 250,
            height: 8,
            color: Colors.grey[700],
          ),
        ),
        // Front face
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F4),
            border: Border.all(
              color: Colors.black87,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 14,
                spreadRadius: 20,
                offset: const Offset(3, 4),
              ),
              BoxShadow(
                color: Colors.white,
                blurRadius: 2,
                offset: const Offset(-2, -2),
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _build3DCuboidButton({required VoidCallback onPressed}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Back/bottom face
        Positioned(
          right: -5,
          bottom: -8,
          child: Container(
            width: 240,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              border: Border.all(
                color: Colors.black87,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 24,
                  spreadRadius: 20,
                  offset: const Offset(5, 7),
                ),
              ],
            ),
          ),
        ),
        // Right edge
        Positioned(
          right: -5,
          bottom: -8,
          child: Container(
            width: 8,
            height: 56,
            color: Colors.grey[800],
          ),
        ),
        // Bottom edge
        Positioned(
          right: -5,
          bottom: -8,
          child: Container(
            width: 240,
            height: 8,
            color: Colors.grey[800],
          ),
        ),
        // Front face (button)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black87,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                spreadRadius: 4,
                offset: const Offset(3, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 2,
                offset: const Offset(-2, -2),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: onPressed,
            child: const Text(
              'Start Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
