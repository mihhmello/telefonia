import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory createDatabaseFactory() => databaseFactoryFfiWeb; // Cria uma fábrica de banco de dados SQLite para uso em navegadores, utilizando sqflite_ffi_web para fornecer suporte a SQLite em ambientes web.
