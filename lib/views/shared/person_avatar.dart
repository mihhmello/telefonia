import 'dart:typed_data';

import 'package:flutter/material.dart';

// A foto do SQLite é exibida diretamente, sem depender de arquivos temporários.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    this.photo,
    this.legacyUrl = '',
    this.radius = 24,
  });
  final Uint8List? photo;
  final String legacyUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {// constrói o widget de avatar da pessoa, exibindo a foto se disponível, caso contrário, exibe um ícone de fallback.
    final fallback = ColoredBox(
      color: Colors.orange.shade100,
      child: Center(
        child: Icon(Icons.person, size: radius, color: Colors.deepOrange),
      ),
    );
    Widget child = fallback;
    if (photo != null) {
      child = Image.memory(
        photo!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (legacyUrl.isNotEmpty) {
      child = Image.network(
        legacyUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return ClipOval(
      child: SizedBox(width: radius * 2, height: radius * 2, child: child),
    );
  }
}
