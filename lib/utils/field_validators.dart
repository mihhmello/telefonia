import 'package:flutter/services.dart';


/// Validações de campos de formulário.
class FieldValidators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null; // verifica se o campo é nulo ou vazio, retornando uma mensagem de erro se for o caso.

  static String? username(String? value) =>
      value == null || !RegExp(r'^[a-zA-Z0-9._-]{3,40}$').hasMatch(value.trim())
      ? 'Use de 3 a 40 letras, números, ponto, _ ou -.' // garante que o texto contenha apenas letras, números, ponto, sublinhado ou hífen, com comprimento entre 3 e 40 caracteres.
      : null;

  static String? password(String? value) =>
      value == null || value.length < 8 || value.length > 128 // garante que a senha tenha entre 8 e 128 caracteres, retornando uma mensagem de erro se não atender a esse critério.
      ? 'A senha deve ter de 8 a 128 caracteres.'
      : null;

  static String digits(String value) => value.replaceAll(RegExp(r'\D'), ''); // remove todos os caracteres não numéricos de uma string, retornando apenas os dígitos.

  static String? phone(String? value) {
    final number = digits(value ?? '');
    if (!RegExp(r'^[1-9][0-9]{9,10}$').hasMatch(number)) {
      return 'Informe DDD e telefone com 10 ou 11 dígitos.'; //valida números de telefone, garantindo que comecem com um dígito de 1 a 9 e tenham entre 10 e 11 dígitos no total.
    }
    return null;
  }
}

// A máscara aceita apenas dígitos e preserva a posição do cursor ao editar, aplicando a formatação de telefone no padrão (XX) XXXXX-XXXX ou (XX) XXXX-XXXX, dependendo do comprimento do número.
class PhoneInputFormatter extends TextInputFormatter {// sobrescreve a classe TextInputFormatter para criar um formatador de entrada de telefone personalizado.
  static String format(String value) {
    final digits = FieldValidators.digits(value);
    final n = digits.substring(0, digits.length > 11 ? 11 : digits.length);
    if (n.isEmpty) return '';
    if (n.length <= 2) return '($n';
    final split = n.length > 10 ? 7 : 6;
    if (n.length <= split) return '(${n.substring(0, 2)}) ${n.substring(2)}';
    return '(${n.substring(0, 2)}) ${n.substring(2, split)}-${n.substring(split)}';
  }

  @override
  TextEditingValue formatEditUpdate( // sobrescreve o método formatEditUpdate da classe TextInputFormatter para aplicar a formatação de telefone ao texto digitado, mantendo a posição do cursor correta.
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = format(newValue.text);
    final offset = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final beforeCursor = FieldValidators.digits(
      newValue.text.substring(0, offset),
    ).length;
    var cursor = 0;
    var count = 0;
    while (cursor < text.length && count < beforeCursor) { // percorre o texto formatado até encontrar a posição correspondente ao cursor, contando apenas os dígitos.
      if (RegExp(r'[0-9]').hasMatch(text[cursor])) count++;
      cursor++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
