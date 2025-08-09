import 'package:flutter/material.dart';
import 'package:sofiapedido/views/pages/pedidos/detalle_pedido_view.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:sofiapedido/services/database_helper.dart';

class PedidosView extends StatefulWidget {
  const PedidosView({super.key});

  @override
  State<PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<PedidosView> {
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> filtrados = [];
  int total = 0;
  int confirmados = 0;
  int noConfirmados = 0;
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargarPedidos();
  }

  Future<void> cargarPedidos() async {
    final db = await DatabaseHelper().database;

    final todos = await db.rawQuery('''
    SELECT p.*, 
      (SELECT COUNT(*) FROM productos WHERE pedido_id = p.id) AS productos_count
    FROM pedidos p
    ORDER BY productos_count DESC
  ''');

    final totalCount = todos.length;
    final confirmedCount = todos.where((p) => p['confirmado'] == 1).length;

    setState(() {
      pedidos = todos;
      total = totalCount;
      confirmados = confirmedCount;
      noConfirmados = totalCount - confirmedCount;
      aplicarFiltro();
    });
  }

  void aplicarFiltro() {
    setState(() {
      if (filtro.trim().isEmpty) {
        filtrados = pedidos;
      } else {
        filtrados = pedidos.where((p) {
          final texto = filtro.toLowerCase();
          return p['cliente_nombre'].toString().toLowerCase().contains(texto) ||
              p['cliente_direccion'].toString().toLowerCase().contains(texto) ||
              p['id'].toString().contains(texto);
        }).toList();
      }
    });
  }

  Widget _cardResumen(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '$cantidad',
          style: TextStyle(fontSize: 18, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Importados'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🟨 Resumen
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _cardResumen('Total', total, Colors.black87),
                    _cardResumen('Confirmados', confirmados, Colors.green),
                    _cardResumen('No confirmados', noConfirmados, Colors.red),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔍 Filtro
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por cliente, dirección o número...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                filtro = val;
                aplicarFiltro();
              },
            ),

            const SizedBox(height: 12),

            // 📋 Lista de pedidos
            Expanded(
              child: filtrados.isEmpty
                  ? const Center(child: Text('No hay pedidos'))
                  : ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (_, index) {
                  final p = filtrados[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetallePedidoView(pedidoId: p['id']),
                          ),
                        ).then((_) => cargarPedidos());
                      },
                      leading: CircleAvatar(
                        backgroundColor: p['confirmado'] == 1 ? Colors.green : Colors.grey,
                        child: Text(
                          (index + 1).toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        'Pedido #${p['id']} (${p['productos_count']})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['cliente_nombre']),
                          Text(p['cliente_direccion']),
                          Text('📅 ${p['fecha']}'),
                        ],
                      ),
                      trailing: p['confirmado'] == 1
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked, color: Colors.red),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
