import 'package:flutter/material.dart';

import 'tecnicos_list_page.dart';
import 'contratos_list_page.dart';
import 'agendamentos_list_page.dart';
import 'users_list_page.dart';
import '../shared/account_menu.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});
  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _index = 0;
  final _pages = const [
    TecnicosListPage(),
    ContratosListPage(),
    AgendamentosListPage(),
    UsersListPage(),
  ];
  final _titles = const ['Técnicos', 'Contratos', 'Agendamentos', 'Usuários'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_titles[_index]),
      backgroundColor: Colors.orange,
      actions: const [AccountMenu()],
    ),
    body: _pages[_index],
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _index,
      selectedItemColor: Colors.orange,
      onTap: (v) => setState(() => _index = v),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Técnicos'),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Contratos',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Agendamentos'),
        BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts),
          label: 'Usuários',
        ),
      ],
    ),
  );
}
