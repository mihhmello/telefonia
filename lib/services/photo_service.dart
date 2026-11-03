import 'dart:typed_data';
import 'dart:ui' as ui;

import '../repositories/crud_repository.dart';

class PhotoService {
  // Redimensiona mantendo a proporção e salva PNG, inclusive para arquivos do desktop.
  static Future<Uint8List> normalize(Uint8List bytes) async {
    if (bytes.length > 8 * 1024 * 1024) {
      throw const RepositoryException('Escolha uma imagem de até 8 MB.');
    }
    ui.Codec? codec;
    ui.Image? image;
    try {
      // ImageDescriptor.width/height não são suportados no Flutter Web.
      // Esta API fornece as dimensões de forma compatível com Chrome e celular.
      codec = await ui.instantiateImageCodecWithSize(
        await ui.ImmutableBuffer.fromUint8List(bytes),
        getTargetSize: (width, height) {
          if (width * height > 40000000) {
            throw const RepositoryException(
              'Escolha uma imagem com resolução menor.',
            );
          }
          final scale = 512 / (width > height ? width : height);
          return ui.TargetImageSize(
            width: scale < 1 ? (width * scale).round().clamp(1, 512) : width,
            height: scale < 1 ? (height * scale).round().clamp(1, 512) : height,
          );
        },
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || data.lengthInBytes > 2 * 1024 * 1024) {
        throw const RepositoryException(
          'A foto deve ter até 2 MB após o processamento.',
        );
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image?.dispose();
      codec?.dispose();
      // instantiateImageCodecWithSize já libera o buffer de entrada.
    }
  }
}
