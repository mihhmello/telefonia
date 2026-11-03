import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../repositories/crud_repository.dart';
import '../../services/photo_service.dart';
import 'person_avatar.dart';

// Um campo de formulário que permite ao usuário selecionar, capturar ou remover uma foto, exibindo a foto atual ou um ícone de fallback.
class PhotoPickerField extends StatefulWidget {
  const PhotoPickerField({
    super.key,
    this.photo,
    this.legacyUrl = '',
    required this.onChanged,
    this.enabled = true,
  });
  final Uint8List? photo;
  final String legacyUrl;
  final ValueChanged<Uint8List?> onChanged;
  final bool enabled;
  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

// O estado do campo de seleção de foto, gerenciando o processo de seleção, captura e remoção da foto, bem como o estado de carregamento.
class _PhotoPickerFieldState extends State<PhotoPickerField> {
  bool _picking = false;
  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    var selecting = true;
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null) return; // Cancelar mantém a foto anterior.
      if (await file.length() > 8 * 1024 * 1024) {
        throw const RepositoryException('Escolha uma imagem de até 8 MB.');
      }
      selecting = false;
      final photo = await PhotoService.normalize(await file.readAsBytes());
      if (mounted) widget.onChanged(photo);
    } catch (error, stack) {
      // O console de debug informa a causa real, sem registrar os bytes da foto.
      debugPrint('Falha ao carregar avatar: $error\n$stack');
      final String message;
      if (error is RepositoryException) {
        message = error.message;
      } else if (error is MissingPluginException) {
        message = 'Reinicie completamente o aplicativo para ativar o seletor de fotos.';
      } else if (error is PlatformException) {
        message = 'Não foi possível acessar a câmera ou galeria. Verifique as permissões do dispositivo.';
      } else {
        message = selecting
            ? 'Não foi possível selecionar o arquivo. Tente novamente.'
            : 'Não foi possível ler essa imagem. Escolha uma foto PNG, JPEG ou WebP válida.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_picking;
    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return Column(
      children: [
        PersonAvatar(
          photo: widget.photo,
          legacyUrl: widget.legacyUrl,
          radius: 48,
        ),
        if (_picking) const LinearProgressIndicator(),
        Wrap(
          spacing: 12,
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: enabled ? () => _pick(ImageSource.gallery) : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Carregar foto'),
            ),
            if (mobile)
              TextButton.icon(
                onPressed: enabled ? () => _pick(ImageSource.camera) : null,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tirar foto'),
              ),
            if (widget.photo != null)
              TextButton(
                onPressed: enabled ? () => widget.onChanged(null) : null,
                child: const Text('Remover foto'),
              ),
          ],
        ),
      ],
    );
  }
}
