import 'package:flutter/services.dart';

class FieldValidators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  static String? username(String? value) =>
      value == null || !RegExp(r'^[a-zA-Z0-9._-]{3,40}$').hasMatch(value.trim())
      ? 'Use de 3 a 40 letras, números, ponto, _ ou -.'
      : null;

  static String? password(String? value) =>
      value == null || value.length < 8 || value.length > 128
      ? 'A senha deve ter de 8 a 128 caracteres.'
      : null;

  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String? phone(String? value) {
    final number = digits(value ?? '');
    if (!RegExp(r'^[1-9][0-9]{9,10}$').hasMatch(number)) {
      return 'Informe DDD e telefone com 10 ou 11 dígitos.';
    }
    return null;
  }
}

// A máscara aceita apenas dígitos e preserva a posição do cursor ao editar.
class PhoneInputFormatter extends TextInputFormatter {
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
  TextEditingValue formatEditUpdate(
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
    while (cursor < text.length && count < beforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(text[cursor])) count++;
      cursor++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
