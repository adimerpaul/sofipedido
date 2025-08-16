import 'package:flutter/material.dart';
import 'package:sofiapedido/views/pages/home_view.dart';
import 'package:sofiapedido/views/pages/import_view.dart';
import 'package:sofiapedido/views/pages/pedidos/pedidos_view.dart';
import 'package:sofiapedido/views/pages/productos_totales_view.dart';
import 'package:sofiapedido/views/pages/productos_view.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  int currentIndex = 0;

  // Devuelve el widget actual SIN usar 'late' ni listas almacenadas
  Widget _currentBody() {
    switch (currentIndex) {
      case 0:
        return HomeView(
          onImportPressed: () => setState(() => currentIndex = 1),
          onPedidosPressed: () => setState(() => currentIndex = 2),
        );
      case 1:
        return const ImportView();
      case 2:
        return const PedidosView();
      case 3:
        return const ProductosView();
      case 4:
        return const ProductosTotalesView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Principal'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _currentBody(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Center(
                child: Text(
                  'Sofia Pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                setState(() => currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Importar'),
              onTap: () {
                setState(() => currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Pedidos'),
              onTap: () {
                setState(() => currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Productos'),
              onTap: () {
                setState(() => currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Productos Totales'),
              onTap: () {
                setState(() => currentIndex = 4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
