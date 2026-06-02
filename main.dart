import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const RunnerBridgeApp());

class RunnerBridgeApp extends StatelessWidget {
  const RunnerBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monster Bridge Run',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const GameScreen(),
    );
  }
}

class Thing {
  Thing({required this.x, required this.kind});
  double x;
  final int kind; // 0 coin, 1 rock, 2 hand, 3 rope, 4 bridge gap
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random random = Random();
  Timer? timer;
  double runnerY = 0;
  double velocityY = 0;
  double monsterDistance = 120;
  bool sliding = false;
  bool gameOver = false;
  int score = 0;
  int coins = 0;
  double speed = 4.5;
  int frame = 0;
  final List<Thing> things = [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _start() {
    timer?.cancel();
    things.clear();
    runnerY = 0;
    velocityY = 0;
    monsterDistance = 120;
    sliding = false;
    gameOver = false;
    score = 0;
    coins = 0;
    speed = 4.5;
    frame = 0;
    timer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick());
    setState(() {});
  }

  void _tick() {
    if (gameOver) return;
    frame++;
    score++;
    speed = min(10.5, speed + 0.002);

    velocityY += 0.95;
    runnerY += velocityY;
    if (runnerY > 0) {
      runnerY = 0;
      velocityY = 0;
    }

    for (final t in things) {
      t.x -= speed;
    }
    things.removeWhere((t) => t.x < -80);

    if (frame % 32 == 0) {
      final roll = random.nextInt(100);
      final kind = roll < 38 ? 0 : roll < 58 ? 1 : roll < 78 ? 2 : roll < 91 ? 3 : 4;
      things.add(Thing(x: 430 + random.nextDouble() * 80, kind: kind));
    }

    _collisions();
    setState(() {});
  }

  void _collisions() {
    const runnerX = 92.0;
    for (final t in List<Thing>.from(things)) {
      final close = (t.x - runnerX).abs() < 34;
      if (!close) continue;
      if (t.kind == 0) {
        coins++;
        score += 50;
        things.remove(t);
      } else if (t.kind == 1 && runnerY > -42) {
        _hit();
        things.remove(t);
      } else if (t.kind == 2 && !sliding) {
        _hit();
        things.remove(t);
      } else if (t.kind == 3 && runnerY > -48) {
        _hit();
        things.remove(t);
      } else if (t.kind == 4 && runnerY > -58) {
        _hit();
        things.remove(t);
      }
    }
  }

  void _hit() {
    monsterDistance -= 42;
    if (monsterDistance <= 0) {
      gameOver = true;
      timer?.cancel();
    }
  }

  void _jump() {
    if (gameOver) return;
    if (runnerY == 0) velocityY = -18;
  }

  void _slide() {
    if (gameOver) return;
    setState(() => sliding = true);
    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) setState(() => sliding = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final ground = h * 0.68;
          final scale = w / 430;
          return Stack(
            children: [
              const _SkyAndSea(),
              ..._buildPlatforms(w, ground),
              ...things.map((t) => _thingWidget(t, ground, scale)),
              Positioned(
                left: 28,
                top: ground - 48 + runnerY,
                child: Transform.scale(
                  scaleY: sliding ? 0.62 : 1,
                  alignment: Alignment.bottomCenter,
                  child: const Text('🏃', style: TextStyle(fontSize: 54)),
                ),
              ),
              Positioned(
                left: max(0, 26 - (120 - monsterDistance)),
                top: ground - 52,
                child: const Text('👹', style: TextStyle(fontSize: 58)),
              ),
              _hud(),
              Positioned(
                left: 16,
                right: 16,
                bottom: 22,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _jump,
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('JUMP / اقفز', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _slide,
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('SLIDE / انزلق', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (gameOver) _gameOverCard(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPlatforms(double w, double ground) {
    final offset = (frame * speed) % 120;
    return List.generate(6, (i) {
      final x = i * 120.0 - offset;
      final isRope = i % 3 == 1;
      return Positioned(
        left: x,
        top: ground + 18,
        child: Container(
          width: isRope ? 95 : 118,
          height: isRope ? 8 : 18,
          decoration: BoxDecoration(
            color: isRope ? const Color(0xFF9E6B37) : const Color(0xFF7B4A26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isRope ? null : const Center(child: Text('━━━━', style: TextStyle(color: Colors.white24))),
        ),
      );
    });
  }

  Widget _thingWidget(Thing t, double ground, double scale) {
    String emoji;
    double top;
    double size;
    switch (t.kind) {
      case 0:
        emoji = '🪙';
        top = ground - 95;
        size = 34;
        break;
      case 1:
        emoji = '🪨';
        top = ground - 28;
        size = 38;
        break;
      case 2:
        emoji = '🤚';
        top = ground - 95;
        size = 46;
        break;
      case 3:
        emoji = '🪢';
        top = ground - 62;
        size = 44;
        break;
      default:
        emoji = '🌊';
        top = ground - 5;
        size = 48;
    }
    return Positioned(left: t.x * scale, top: top, child: Text(emoji, style: TextStyle(fontSize: size)));
  }

  Widget _hud() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pill('Score: $score'),
            _pill('Gold: $coins 🪙'),
            _pill('Monster: ${max(0, monsterDistance).round()}'),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );

  Widget _gameOverCard() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('الوحش مسكك!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Score: $score   Gold: $coins', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 18),
              FilledButton(onPressed: _start, child: const Text('العب تاني')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkyAndSea extends StatelessWidget {
  const _SkyAndSea();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4B7BE5), Color(0xFF93D7F5), Color(0xFF0B6FA4)],
            ),
          ),
        ),
        Positioned(top: 70, left: 32, child: _cloud()),
        Positioned(top: 130, right: 45, child: _cloud()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 190,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF05769E), Color(0xFF013B5C)]),
            ),
            child: const Center(child: Text('≈  ≈  ≈  ≈  بحر  ≈  ≈  ≈', style: TextStyle(color: Colors.white70, fontSize: 24))),
          ),
        ),
      ],
    );
  }

  Widget _cloud() => Container(
        width: 120,
        height: 42,
        decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(40)),
      );
}
