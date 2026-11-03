import 'package:flutter/material.dart';

import '../../repositories/crud_repository.dart';

Future<bool> runCrudAction(// executa uma ação de CRUD e trata erros, exibindo uma mensagem de erro em um SnackBar se a ação falhar.
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

Future<void> confirmDelete( // exibe um diálogo de confirmação antes de executar uma ação de exclusão, chamando runCrudAction se o usuário confirmar a exclusão.
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
