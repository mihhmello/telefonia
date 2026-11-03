import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telefonia_app/utils/field_validators.dart';

void main() {
  test('máscara formata fixo/celular, remove letras e limita os dígitos', () {
    expect(PhoneInputFormatter.format('4232221234'), '(42) 3222-1234');
    expect(PhoneInputFormatter.format('42999991234'), '(42) 99999-1234');
    final value = PhoneInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'abc429999912345',
        selection: TextSelection.collapsed(offset: 15),
      ),
    );
    expect(value.text, '(42) 99999-1234');
    expect(FieldValidators.phone('(42) 99999-1234'), isNull);
    expect(FieldValidators.phone('123'), isNotNull);
    expect(FieldValidators.phone('00999999999'), isNotNull);
    expect(FieldValidators.username('a b'), isNotNull);
    expect(FieldValidators.username('maria.silva'), isNull);
    expect(FieldValidators.password('123'), isNotNull);
  });
}
