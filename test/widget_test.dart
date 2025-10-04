import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:camera/camera.dart';

void main() {
  testWidgets('Кнопка камеры открывает экран предпросмотра камеры', (WidgetTester tester) async {
    final camera = CameraDescription(
      name: 'fake_camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );

    await tester.pumpWidget(MyApp(camera: camera));

    expect(find.byIcon(Icons.camera_alt), findsOneWidget);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(find.text('Предпросмотр камеры'), findsOneWidget);
  });
}
