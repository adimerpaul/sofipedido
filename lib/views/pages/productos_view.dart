import 'package:flutter/material.dart';
import 'package:sofiapedido/services/database_helper.dart';

class ProductosView extends StatefulWidget {
  const ProductosView({super.key});

  @override
  State<ProductosView> createState() => _ProductosViewState();
}

class _ProductosViewState extends State<ProductosView> {
  List<Map<String, dynamic>> productos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    final data = await DatabaseHelper().obtenerResumenProductos();
    setState(() {
      productos = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen de Productos (${productos.length})'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : productos.isEmpty
          ? const Center(child: Text('No hay productos registrados'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: productos.length,
        itemBuilder: (_, index) {
          final p = productos[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Text(
                  p['total_cantidad'].toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                p['nombre'].toString().trim(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Código: ${p['cod_prod']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Total Bs.'),
                  Text(
                    p['total_subtotal'].toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
