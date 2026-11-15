import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const CarGameApp());
}

class CarGameApp extends StatelessWidget {
  const CarGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cross-Device Car Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🚗 SUPER CAR RACER 3D',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Play on PC & Mobile (Itch.io Ready)',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GamePlayScreen()),
                  );
                },
                child: const Text('START GAME'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  double carX = 0.0; // গাড়ির লেফট-রাইট পজিশন (-1.0 থেকে 1.0)

  // কিবোর্ড কন্ট্রোল হ্যান্ডেল করার ফাংশন (পিসির জন্য)
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.keyA) {
          if (carX > -0.8) carX -= 0.1; // বামে যাওয়া
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                   event.logicalKey == LogicalKeyboardKey.keyD) {
          if (carX < 0.8) carX += 0.1; // ডানে যাওয়া
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Stack(
          children: [
            // ১. রোড ব্যাকগ্রাউন্ড ও মুভিং ফিল্ড
            Positioned.fill(
              child: Container(
                color: Colors.grey[800],
                child: Center(
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: const Border(
                        left: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                    ),
                    // সেন্ট্রাল রোড ডিভাইডার লাইন
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 4,
                        color: Colors.yellow,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ২. প্লেয়ার কার (গাড়ি)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: 50,
              left: MediaQuery.of(context).size.width / 2 + (carX * 120) - 25,
              child: Container(
                width: 50,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 5, spreadRadius: 2)
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🏎️',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),

            // ৩. টাচ কন্ট্রোল বাটন (মোবাইল ডিভাইসের জন্য অন-স্ক্রিন লেফট/রাইট বাটন)
            if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // লেফট বাটন
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      ),
                      onPressed: () {
                        setState(() {
                          if (carX > -0.8) carX -= 0.15;
                        });
                      },
                      child: const Text('◀ LEFT', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    // রাইট বাটন
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      ),
                      onPressed: () {
                        setState(() {
                          if (carX < 0.8) carX += 0.15;
                        });
                      },
                      child: const Text('RIGHT ▶', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),

            // ৪. ব্যাক বাটন
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}