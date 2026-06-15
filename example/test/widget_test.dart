import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_barrage/flame_barrage.dart';

class MockPicture extends ui.Picture {
  bool _isDisposed = false;

  @override
  int get approximateBytesUsed => 0;

  @override
  void dispose() {
    _isDisposed = true;
  }

  @override
  bool get debugDisposed => _isDisposed;

  @override
  Future<ui.Image> toImage(int width, int height) {
    throw UnsupportedError('MockPicture does not support async text-to-image conversion in test environment.');
  }

  @override
  ui.Image toImageSync(int width, int height, {ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare}) {
    throw UnsupportedError('MockPicture does not support synchronous text-to-image conversion in test environment.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlameBarrageWidget & Central Engine Integrations', () {
    late BarrageConfig baseConfig;
    late BarrageController controller;

    setUp(() {
      baseConfig = const BarrageConfig(trackHeight: 40, maxTrackCount: 5, normalEmitInterval: 0.1, maxVisibleCount: 10);
      controller = BarrageController();
    });

    tearDown(() {
      controller.detach();
    });

    testWidgets('Should mount FlameBarrageWidget safely inside component tree', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: FlameBarrageWidget(config: baseConfig, emojiAtlas: EmojiAtlas.instance, controller: controller),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(FlameBarrageWidget), findsOneWidget);
      });
    });

    testWidgets('Should dispatch pipeline from controller to engine safely', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: FlameBarrageWidget(config: baseConfig, emojiAtlas: EmojiAtlas.instance, controller: controller),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(() {
          controller.send(const BarrageItem(content: 'Pipeline Integration Test Core', type: BarrageType.scroll));
        }, returnsNormally);

        await tester.pump(const Duration(milliseconds: 200));
        controller.clear();
        await tester.pump();
      });
    });
  });
}
