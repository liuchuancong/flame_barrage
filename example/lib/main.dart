import 'demo/barrage_router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlameBarrageApp());
}

class FlameBarrageApp extends StatelessWidget {
  const FlameBarrageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flame Barrage Demo Suite',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: BarrageRouter.getRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }
}
