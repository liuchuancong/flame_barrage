import 'package:flutter_test/flutter_test.dart';

import 'package:flame_barrage/src/util/frame_timings_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start and stop are safe to call repeatedly', () {
    final monitor = FrameTimingsMonitor();

    // The first start calls stop internally: removing a callback that was
    // never registered asserts in the scheduler binding.
    monitor.start((_) {});
    monitor.stop();
    monitor.stop();

    monitor.start((_) {});
    monitor.stop();
  });
}
