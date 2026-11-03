import 'dart:io';

import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory createDatabaseFactory() { // Cria uma fábrica de banco de dados SQLite apropriada para a plataforma atual, usando sqflite_ffi para desktop e sqflite para dispositivos móveis.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return mobile.databaseFactory;
}
