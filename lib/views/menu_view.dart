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
  final List<Widget> items = [
    const HomeView(),
    const ImportView(),
    const PedidosView(),
    const ProductosView(),
    const ProductosTotalesView()
  ];
  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Principal'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: items[currentIndex],
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
              // prodcutos totales
              leading: const Icon(Icons.list),
              title: const Text('Productos Totales'),
              onTap: () {
                setState(() => currentIndex = 4);
                Navigator.pop(context);
              }
            )
          ],
        ),
      ),
    );
  }
}
