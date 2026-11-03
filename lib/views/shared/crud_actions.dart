import 'package:flutter/material.dart';

import '../../repositories/crud_repository.dart';

Future<bool> runCrudAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error, stack) {
    debugPrint('Falha no CRUD: $error\n$stack');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is RepositoryException
                ? error.message
                : 'Não foi possível concluir a operação. Tente novamente.',
          ),
        ),
      );
    }
    return false;
  }
}

Future<void> confirmDelete(
  BuildContext context,
  Future<void> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir registro'),
      content: const Text(
        'Deseja excluir este registro? Esta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await runCrudAction(context, action);
  }
}
