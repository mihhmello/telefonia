import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

// PBKDF2 é fornecido pela biblioteca. Cada senha recebe um salt aleatório.
// No aplicativo nativo, compute evita bloquear a interface durante o cálculo.
class PasswordHasher {
  const PasswordHasher({this.iterations = 600000});
  final int iterations;

  Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = base64Encode(List.generate(16, (_) => random.nextInt(256)));
    final digest = await compute(_derive, [password, salt, '$iterations']);
    return 'pbkdf2:$iterations:$salt:$digest';
  }

  Future<bool> verify(String password, String encoded) async {
    final parts = encoded.split(':');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final digest = await compute(_derive, [password, parts[2], parts[1]]);
    // Comparação sem encerrar no primeiro caractere diferente.
    if (digest.length != parts[3].length) return false;
    var difference = 0;
    for (var i = 0; i < digest.length; i++) {
      difference |= digest.codeUnitAt(i) ^ parts[3].codeUnitAt(i);
    }
    return difference == 0;
  }
}

Future<String> _derive(List<String> values) async {
  final algorithm = Pbkdf2.hmacSha256(
    iterations: int.parse(values[2]),
    bits: 256,
  );
  final key = await algorithm.deriveKeyFromPassword(
    password: values[0],
    nonce: base64Decode(values[1]),
  );
  return base64Encode(await key.extractBytes());
}
