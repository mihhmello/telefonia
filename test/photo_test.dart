import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:telefonia_app/services/photo_service.dart';

import 'fixtures/avatar_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'foto é validada e reduzida mantendo proporção para salvar no banco',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.runAsync(() async {
        final normalized = await PhotoService.normalize(avatarImage);
        final codec = await ui.instantiateImageCodec(normalized);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 512);
        expect(frame.image.height, 256);
        expect(normalized.length, lessThan(2 * 1024 * 1024));
        frame.image.dispose();
        codec.dispose();
        await expectLater(
          PhotoService.normalize(Uint8List.fromList([1, 2, 3])),
          throwsException,
        );
        await expectLater(
          PhotoService.normalize(Uint8List(8 * 1024 * 1024 + 1)),
          throwsException,
        );
      });
    },
  );
}
