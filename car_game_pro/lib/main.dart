import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CarGameApp());
}

class CarGameApp extends StatelessWidget {
  const CarGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Car Racer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D084),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF07120F),
        useMaterial3: true,
      ),
      home: const GameHomeScreen(),
    );
  }
}

class GameHomeScreen extends StatelessWidget {
  const GameHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF102C27), Color(0xFF07120F), Color(0xFF050807)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D084).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00D084).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled,
                        size: 58,
                        color: Color(0xFF00D084),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'SUPER CAR RACER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dodge the traffic. Stay on the road.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      key: const ValueKey('start-game'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00D084),
                        foregroundColor: const Color(0xFF03120C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 18,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const GamePlayScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('START GAME'),
                    ),
                    const SizedBox(height: 28),
                    const _ControlHint(
                      icon: Icons.keyboard_alt_outlined,
                      label: 'Move with  ←  →  or  A / D',
                    ),
                    const SizedBox(height: 10),
                    const _ControlHint(
                      icon: Icons.touch_app_outlined,
                      label: 'On mobile, use the on-screen buttons',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }
}

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  static const _tickInterval = Duration(milliseconds: 32);
  static const _playerHeightFactor = 0.14;
  static const _playerBottomFactor = 0.18;
  static const _obstacleHeightFactor = 0.12;

  final FocusNode _focusNode = FocusNode(debugLabel: 'game controls');
  final Stopwatch _clock = Stopwatch();
  final Random _random = Random();
  final List<_Obstacle> _obstacles = [];

  Timer? _timer;
  int _lane = 1;
  int _score = 0;
  int _highScore = 0;
  double _roadOffset = 0;
  double _spawnElapsed = 0;
  Duration _lastTick = Duration.zero;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _resetGame();
    unawaited(_loadHighScore());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetGame() {
    _timer?.cancel();
    _obstacles.clear();
    _lane = 1;
    _score = 0;
    _roadOffset = 0;
    _spawnElapsed = 0;
    _isRunning = true;
    _clock
      ..reset()
      ..start();
    _lastTick = Duration.zero;
    _timer = Timer.periodic(_tickInterval, _onTick);
  }

  void _startGame() {
    setState(_resetGame);
    _focusNode.requestFocus();
  }

  void _onTick(Timer timer) {
    if (!_isRunning) return;

    final now = _clock.elapsed;
    final delta = ((now - _lastTick).inMicroseconds / 1000000)
        .clamp(0.0, 0.1)
        .toDouble();
    _lastTick = now;
    var collided = false;

    setState(() {
      _roadOffset = (_roadOffset + delta * 180) % 48;
      _spawnElapsed += delta;

      final speed = 0.34 + min(_score * 0.008, 0.32);
      for (final obstacle in _obstacles) {
        obstacle.progress += delta * speed;
        if (obstacle.lane == _lane &&
            obstacle.progress < 1 - _playerBottomFactor &&
            obstacle.progress + _obstacleHeightFactor >
                1 - _playerBottomFactor - _playerHeightFactor) {
          collided = true;
        }
      }

      final spawnInterval = max(0.58, 1.2 - _score * 0.008);
      if (_spawnElapsed >= spawnInterval) {
        _spawnElapsed -= spawnInterval;
        _obstacles.add(_Obstacle(lane: _random.nextInt(3)));
      }

      for (final obstacle in _obstacles) {
        if (!obstacle.scored && obstacle.progress > 0.9) {
          obstacle.scored = true;
          _score++;
        }
      }
      _obstacles.removeWhere((obstacle) => obstacle.progress > 1.15);
    });

    if (collided) _endGame();
  }

  void _movePlayer(int direction) {
    if (!_isRunning) return;
    final nextLane = (_lane + direction).clamp(0, 2);
    if (nextLane == _lane) return;
    setState(() => _lane = nextLane);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _movePlayer(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _movePlayer(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _endGame() {
    if (!_isRunning) return;
    _timer?.cancel();
    _clock.stop();
    setState(() {
      _isRunning = false;
      if (_score > _highScore) _highScore = _score;
    });
    if (_score > 0) unawaited(_saveHighScore(_score));
  }

  Future<void> _loadHighScore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedScore = preferences.getInt('high_score') ?? 0;
      if (mounted) setState(() => _highScore = savedScore);
    } catch (error, stackTrace) {
      _reportStorageError(
        'Could not load the saved high score.',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _saveHighScore(int score) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setInt('high_score', score);
      if (!saved && mounted) {
        _showStorageMessage('Could not save your high score.');
      }
    } catch (error, stackTrace) {
      _reportStorageError('Could not save the high score.', error, stackTrace);
    }
  }

  void _reportStorageError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'high score storage',
      ),
    );
    if (mounted) _showStorageMessage(message);
  }

  void _showStorageMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final roadWidth = min(520.0, constraints.maxWidth - 24);
              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10251C), Color(0xFF07120F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: roadWidth,
                      height: constraints.maxHeight,
                      child: LayoutBuilder(
                        builder: (context, roadConstraints) {
                          final laneWidth = roadConstraints.maxWidth / 3;
                          final playerHeight =
                              roadConstraints.maxHeight * _playerHeightFactor;
                          final obstacleHeight =
                              roadConstraints.maxHeight * _obstacleHeightFactor;
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF20292C),
                                    border: Border.symmetric(
                                      vertical: BorderSide(
                                        color: const Color(
                                          0xFF00D084,
                                        ).withValues(alpha: 0.65),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _RoadMarkingsPainter(_roadOffset),
                                ),
                              ),
                              for (final obstacle in _obstacles)
                                Positioned(
                                  key: ValueKey(
                                    'obstacle-${obstacle.lane}-${obstacle.progress}',
                                  ),
                                  top:
                                      obstacle.progress *
                                      roadConstraints.maxHeight,
                                  left:
                                      obstacle.lane * laneWidth +
                                      laneWidth * 0.2,
                                  width: laneWidth * 0.6,
                                  height: obstacleHeight,
                                  child: const _TrafficCar(),
                                ),
                              AnimatedPositioned(
                                key: ValueKey('player-lane-$_lane'),
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeOut,
                                bottom:
                                    roadConstraints.maxHeight *
                                    _playerBottomFactor,
                                left: _lane * laneWidth + laneWidth * 0.18,
                                width: laneWidth * 0.64,
                                height: playerHeight,
                                child: const _PlayerCar(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Back to menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 78,
                    right: 78,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScoreCard(label: 'SCORE', value: _score),
                        const SizedBox(width: 12),
                        _ScoreCard(label: 'BEST', value: _highScore),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MoveButton(
                          key: const ValueKey('move-left'),
                          label: 'LEFT',
                          icon: Icons.arrow_left_rounded,
                          onPressed: () => _movePlayer(-1),
                        ),
                        _MoveButton(
                          key: const ValueKey('move-right'),
                          label: 'RIGHT',
                          icon: Icons.arrow_right_rounded,
                          onPressed: () => _movePlayer(1),
                        ),
                      ],
                    ),
                  ),
                  if (!_isRunning)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.72),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sports_score_rounded,
                                    size: 62,
                                    color: Color(0xFF00D084),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'GAME OVER',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Score: $_score     Best: $_highScore',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    key: const ValueKey('play-again'),
                                    onPressed: _startGame,
                                    icon: const Icon(Icons.replay_rounded),
                                    label: const Text('PLAY AGAIN'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('BACK TO MENU'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Obstacle {
  _Obstacle({required this.lane});

  final int lane;
  double progress = 0;
  bool scored = false;
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD101916),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: Colors.white60,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xEE101916),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: Colors.white24),
      ),
    );
  }
}

class _PlayerCar extends StatelessWidget {
  const _PlayerCar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00D084),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7FFE4), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const FittedBox(
        child: Icon(
          Icons.directions_car_filled,
          color: Color(0xFF08251A),
          size: 52,
        ),
      ),
    );
  }
}

class _TrafficCar extends StatelessWidget {
  const _TrafficCar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF7043),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC1AD), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const FittedBox(
        child: Icon(
          Icons.local_taxi_rounded,
          color: Color(0xFF3B140A),
          size: 46,
        ),
      ),
    );
  }
}

class _RoadMarkingsPainter extends CustomPainter {
  const _RoadMarkingsPainter(this.offset);

  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.68)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var lane = 1; lane < 3; lane++) {
      final x = size.width * lane / 3;
      for (var y = -48.0 + offset; y < size.height; y += 48) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 23), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadMarkingsPainter oldDelegate) =>
      oldDelegate.offset != offset;
}
