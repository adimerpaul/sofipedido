import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sofiapedido/views/pages/home_view.dart';
import 'package:sofiapedido/views/pages/import_view.dart';
import 'package:sofiapedido/views/pages/pedidos/pedidos_view.dart';
import 'package:sofiapedido/views/pages/productos_totales_view.dart';
import 'package:sofiapedido/views/pages/productos_view.dart';
import 'package:flutter/services.dart'; // 👈 importa esto arriba

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  int currentIndex = 0;

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

  // ----- Drawer Header bonito con degradado + avatar -----
  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD32F2F), // rojo intenso
            Color(0xFFF44336), // rojo
            Color(0xFFFF7043), // deep orange
          ],
        ),
        // 👉 Si tienes una imagen, descomenta esto y añade assets/drawer_bg.png al pubspec.yaml
        // image: const DecorationImage(
        //   image: AssetImage('assets/drawer_bg.png'),
        //   fit: BoxFit.cover,
        //   colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
        // ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar con logo
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Títulos
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Sofía Pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestión de importaciones y pedidos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- Item del Drawer con indicador de selección bonito -----
  Widget _navItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool selected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => currentIndex = index);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.red.withValues(alpha: 0.10) // antes: withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.red.withValues(alpha: 0.35) // antes: withOpacity(0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Indicador lateral animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: selected ? 5 : 0,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF7043), Color(0xFFD32F2F)],
                ),
              ),
            ),
            // Contenido del tile
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(
                icon,
                color: selected ? const Color(0xFFD32F2F) : Colors.grey[700],
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFFD32F2F) : Colors.black87,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: Color(0xFFD32F2F), size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar con leve degradado para combinar con el Drawer
    final appBar = AppBar(
      elevation: 0,
      title: const Text('Menú Principal'),
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            dotenv.env['VERSION'] ?? 'v1.0.0',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light, // 👈 aquí el truco
    );

    return Scaffold(
      appBar: appBar,
      body: _currentBody(),
      drawer: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                children: [
                  _navItem(icon: Icons.home, title: 'Inicio', index: 0),
                  _navItem(icon: Icons.cloud_download, title: 'Importar', index: 1),
                  _navItem(icon: Icons.receipt_long, title: 'Pedidos', index: 2),
                  _navItem(icon: Icons.inventory_2, title: 'Productos', index: 3),
                  _navItem(icon: Icons.list, title: 'Productos Totales', index: 4),
                ],
              ),
            ),
            // Pie del drawer (opcional)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Colors.black54),
                  SizedBox(width: 6),
                  Text('v1.0.0', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
