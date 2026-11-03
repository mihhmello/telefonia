export 'database_factory_native.dart'
    if (dart.library.js_interop) 'database_factory_web.dart'; // Exporta a implementação correta da fábrica de banco de dados SQLite com base na plataforma, usando sqflite_ffi para desktop e sqflite_ffi_web para navegadores, garantindo compatibilidade com diferentes ambientes de execução.
