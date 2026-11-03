# Sistema de Telefonia

Aplicação Flutter acadêmica com Provider e persistência SQLite para técnicos,
contratos, agendamentos e usuários. O esquema é criado automaticamente na primeira abertura.
Não é necessário instalar um servidor de banco de dados.

## Executar no VS Code

1. Após clonar o projeto ou executar `git pull`, rode `flutter pub get` na pasta
   do projeto para instalar as dependências e evitar erros de imports, como Provider. Se o Flutter informar que plugins
   precisam de suporte a links simbólicos no Windows, habilite o **Modo de Desenvolvedor**
   nas configurações do Windows e execute novamente.
2. Encerre a execução antiga e inicie novamente com F5; a instalação dos plugins
   exige reinício completo, além de hot reload.
3. Entre com **usuário `admin` e senha inicial `12345678`**. A conta é gravada
   automaticamente no banco; não existe formulário público para criar o primeiro
   administrador. Altere a senha em **Meu perfil → Alterar minha senha** ou na área
   administrativa de usuários.
4. Na aba **Usuários**, o administrador cria contas do grupo Administrador ou Somente
   consulta. Pode editar os dados, carregar foto, redefinir senha e exigir troca no
   próximo login. A opção de troca vem marcada ao criar novas contas.
5. Cadastre um técnico e um contrato; depois crie o agendamento escolhendo data e hora.
   Use o lápis para editar e a lixeira para excluir, com confirmação.
6. No avatar do canto superior direito, abra **Meu perfil** para editar seus dados,
   foto e senha. O usuário comum não pode mudar o próprio grupo.

Criado por Milena de Campos Mello - Disciplina Programação de Dispositivos Móveis

Não está criando novo usuário na memória, apenas pega os usuários criados;
Falta o usuário confirmar a visita do técnico, será implementado posteriormente para as próximas entregas, onde tambén quero fazer a integração (recurso nativo) com o usuário tirando uma foto comprovando a visita do técnico;
Falta criar técnico e associar ao contrato;
Falta criar agendamento e associar a um usuário;
Comecei a implementar o que vai ser entregue posteriormente, mas ainda não está funcional

Java sdk versão 19


A versão 2 do banco acrescenta usuários e fotos sem apagar técnicos, contratos ou
agendamentos da versão 1. A versão 3 cria/configura a conta `admin` com senha
`12345678` uma única vez na atualização, mantendo ID, nome e foto de uma conta
`admin` existente. Nas aberturas seguintes, a senha alterada é preservada. A sessão não é mantida ao fechar/recarregar o aplicativo;
faça login novamente.

Em bases novas, técnicos, contratos e agendamentos começam vazios. Os exemplos antes escritos no Provider foram removidos;
dados que existiam somente na memória da versão anterior não podem ser recuperados.

### Navegador

No VS Code, selecione a configuração `telefonia_app (Chrome - SQLite local)`
e pressione F5. Ela mantém a porta 7357 fixa. Pelo terminal:

```sh
flutter run -d chrome --web-port=7357
```

Mantenha a mesma porta para reencontrar os dados locais: o armazenamento pertence à
origem (protocolo, endereço e porta) e ao perfil do navegador. Limpar os dados do site,
usar navegação privada ou trocar de navegador pode remover ou ocultar a base.

Os arquivos `web/sqlite3.wasm` e `web/sqflite_sw.js` estão incluídos no projeto.
Se atualizar as dependências SQLite, regenere os arquivos antes de compilar:

```sh
dart run sqflite_common_ffi_web:setup --force
```

O adaptador Web usa IndexedDB e SharedWorker; seu suporte é experimental conforme
[a documentação do pacote](https://pub.dev/packages/sqflite_common_ffi_web).
Para distribuição, sirva também esses dois arquivos na pasta da aplicação.

### Windows e dispositivos

```sh
flutter run -d windows
```

O Windows exige as ferramentas de compilação desktop do Flutter. A base se chama
`telefonia.db` e fica no diretório retornado pela factory SQLite da plataforma
(`getDatabasesPath`). Android/iOS/macOS usam o plugin sqflite; Windows/Linux usam
sqflite_common_ffi. Os testes usam um banco separado e nunca alteram os cadastros reais.

## Organização para estudo

```text
Telas (views)
    -> AppProvider (estado, carregamento e operações assíncronas)
        -> TelefoniaRepository / CrudRepository / UserRepository (dados e permissões)
            -> AppDatabase (conexão e versão do esquema)
                -> SQLite
```

- `lib/models`: entidades e conversão `toMap` / `fromMap`.
- `lib/data`: abertura do banco, esquema versão 3, migração e escolha do adaptador.
- `lib/services`: hash de senha e validação/redimensionamento de imagens.
- `lib/routing`: rotas centralizadas e checagem da sessão/grupo.
- `lib/utils`: validadores compartilhados e máscara de telefone.
- `lib/repositories`: SQL parametrizado, CRUD e leitura consistente dos vínculos.
- `lib/providers`: estado observado pelas telas; listas atualizadas após gravação.
- `lib/views/shared`: mensagens de falha e confirmação de exclusão.

As telas não executam SQL. Para acrescentar outro cadastro, crie seu modelo, tabela,
repositório e métodos no Provider, e conecte a tela às operações assíncronas.
Para alterar o esquema de uma base existente, aumente a versão e implemente
`onUpgrade` em `AppDatabase`, preservando os dados já cadastrados.

## Modelo relacional e regras

| Tabela | Chave e campos principais |
| --- | --- |
| tecnicos | id, nome, especialidade, telefone, foto_url legado, foto (BLOB) |
| contratos | id, numero_contrato, cliente, plano, endereco |
| agendamentos | id, tecnico_id, contrato_id, data_hora |
| usuarios | id, nome, local_trabalho, username único, senha_hash, role, trocar_senha, foto (BLOB) |

Um técnico e um contrato podem participar de vários agendamentos. A visita guarda
as chaves estrangeiras, por isso uma edição do cadastro aparece nas visitas existentes.
Data/hora são armazenadas como milissegundos desde epoch e exibidas no horário local.

- Campos obrigatórios são validados na tela e no banco.
- Número de contrato é único, sem diferenciar maiúsculas/minúsculas ASCII.
- Um técnico não pode ter dois agendamentos no mesmo instante; não há cálculo de
  duração ou bloqueio de intervalos de atendimento nesta versão.
- A exclusão de técnico/contrato com visitas é bloqueada por chave estrangeira.
  Exclua ou altere as visitas antes de remover o cadastro.
- Novos agendamentos e alterações de horário exigem uma data futura na interface.
- Erros de gravação aparecem na tela e mantêm o formulário aberto.

## Verificação

```sh
flutter analyze
flutter test
flutter build web
```

Os testes cobrem CRUD, reabertura da base, migrações v1/v2 → v3, persistência de fotos,
hash e troca de senha, perfis, bloqueio de escrita para usuários comuns, duplicidades,
chaves estrangeiras, máscaras, acesso direto a rotas e cadastro pela interface.
Para executar testes/análise Web em uma máquina Windows sem suporte a links simbólicos,
use `flutter test --no-pub`, `flutter analyze --no-pub` e `flutter build web --no-pub`
após baixar as dependências. Para compilar o aplicativo Windows com os plugins de
imagem, habilite o Modo de Desenvolvedor do Windows (necessário aos links simbólicos).

## Fotos e câmera

**Carregar foto** permite selecionar uma imagem para técnicos e usuários.
**Tirar foto** aparece em Android/iOS, inclusive em navegadores identificados como
celular; no navegador a captura depende do suporte do dispositivo. Desktop permite
selecionar um arquivo, sem captura de webcam nesta versão.

O arquivo selecionado deve ter até 8 MB. A imagem é decodificada, reduzida para no
máximo 512 pixels de lado mantendo proporção e salva como PNG de até 2 MB no SQLite.
O avatar usa recorte circular na exibição. O arquivo temporário não é usado como
referência permanente. Permissões de câmera/galeria foram declaradas no iOS e o
seletor de arquivos foi autorizado no sandbox do macOS.

## Acesso e limites da base local

Senhas são armazenadas como PBKDF2-HMAC-SHA256 (600 mil iterações, salt aleatório
individual); o modelo mostrado às telas não contém senha nem hash. O login consulta
o banco. A carga do administrador ocorre somente na criação/migração do esquema;
não há criação pública de conta, método de cadastro inicial sem autenticação ou
reposição da senha padrão a cada login. As demais contas exigem um administrador
autenticado.

As rotas conferem sessão, grupo e obrigatoriedade de troca de senha em cada atualização.
Abrir `/admin/...` pelo endereço não libera telas administrativas a usuários comuns.
Sem sessão, a tela de login é exibida. Após logout, os dados em memória são limpos.
As operações de gravação do Provider também consultam a permissão no banco.
No perfil pessoal, somente nome, local de trabalho, usuário e foto são atualizáveis;
role e flag de senha não são aceitos como alterações de perfil.

Essa proteção atende ao aplicativo local. O banco e o código ficam no dispositivo;
uma pessoa com acesso ao arquivo SQLite ou às ferramentas do navegador pode alterá-los.
Para dados compartilhados e autorização que o cliente não possa contornar, é necessária
uma API que valide sessão e grupo no servidor. Cada instalação/navegador continua com
sua própria base. A agenda de consulta é geral, sem vínculo de contratos a contas.

A câmera real e suas permissões precisam ser verificadas em um celular antes da
distribuição; os testes automatizados validam o tratamento das imagens e sua persistência.

## Diagnóstico no debug

- Chrome: o processamento do avatar usa `instantiateImageCodecWithSize`. Não leia
  `ImageDescriptor.width/height` de imagens codificadas no Web, pois essa API não é
  suportada. A imagem escolhida é validada antes de salvar e falhas aparecem também
  no console de debug. Para testar o processamento no navegador:
  `flutter test --platform chrome --no-pub test/photo_test.dart`.
- Android no Windows: `kotlin.incremental=false` evita o erro de cache Kotlin
  `this and base files have different roots` quando o Pub Cache está em C: e o
  projeto em D:. A compilação pode demorar um pouco mais. Não é necessário mover
  o projeto, reinstalar o emulador nem apagar o banco.
- O aviso sobre versões XML do SDK é diferente da falha fatal do cache Kotlin.
  Se reaparecer, confira a instalação das ferramentas Android com `flutter doctor -v`.
- Após trocar plugins ou configurações Android, encerre a sessão de debug e execute
  novamente com F5. Hot reload não substitui essa recompilação.
