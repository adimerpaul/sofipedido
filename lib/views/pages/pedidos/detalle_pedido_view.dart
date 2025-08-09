// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sofiapedido/services/database_helper.dart';

class DetallePedidoView extends StatefulWidget {
  final int pedidoId;

  const DetallePedidoView({super.key, required this.pedidoId});

  @override
  State<DetallePedidoView> createState() => _DetallePedidoViewState();
}

class _DetallePedidoViewState extends State<DetallePedidoView> {
  Map<String, dynamic>? pedido;
  List<Map<String, dynamic>> productos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  Future<void> cargarDetalle() async {
    final db = await DatabaseHelper().database;

    final p = await db.query(
      'pedidos',
      where: 'id = ?',
      whereArgs: [widget.pedidoId],
      limit: 1,
    );

    final pr = await db.query(
      'productos',
      where: 'pedido_id = ?',
      whereArgs: [widget.pedidoId],
    );

    if (mounted) {
      setState(() {
        pedido = p.first;
        productos = pr
            .map(
              (producto) => {
                ...producto,
                'cantidad': producto['cantidad'] ?? 0,
                'peso': producto['peso'] ?? 0.0,
                'subtotal': producto['subtotal'] ?? 0.0,
              },
            )
            .toList();
        loading = false;
      });
      // print productos
      // print('Productos cargados: ${productos.length}');
      // print(jsonEncode(productos));
    }
  }

  Future<void> guardarCambiosProductos() async {
    final db = await DatabaseHelper().database;

    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
    // int _toInt(dynamic v) => (v is int) ? v : (int.tryParse(v.toString()) ?? 0);

    for (var p in productos) {
      // print('Procesando producto ID: ${p['id']}');
      // print('Datos actuales: cantidad=${p['cantidad']}, peso=${p['peso']}, precio=${p['precio']}');
      final cant = toDouble(p['cantidad']);
      final peso = toDouble(p['peso']);
      final precio = toDouble(p['precio']);

      // print('Actualizando producto: ${p['nombre']}');
      // print('Nueva cantidad: $cant, Peso: $peso');

      if (cant > 0 || peso > 0) {
        final nuevoSubtotal = cant * precio;
        await db.update(
          'productos',
          {'cantidad': cant, 'subtotal': nuevoSubtotal, 'peso': peso},
          where: 'id = ?',
          whereArgs: [p['id']],
        );
      }
    }
  }

  Future<void> confirmarPedido() async {
    final messenger = ScaffoldMessenger.of(context);
    final db = await DatabaseHelper().database;

    await guardarCambiosProductos();

    await db.update(
      'pedidos',
      {'confirmado': 1},
      where: 'id = ?',
      whereArgs: [widget.pedidoId],
    );

    await cargarDetalle();

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pedido confirmado ✅')),
      );
    }
  }

  Future<void> eliminarProducto(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('productos', where: 'id = ?', whereArgs: [id]);
    await cargarDetalle();
  }

  @override
  Widget build(BuildContext context) {
    final estaConfirmado = pedido?['confirmado'] == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.pedidoId}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente: ${pedido?['cliente_nombre']}'),
                  Text('Dirección: ${pedido?['cliente_direccion']}'),
                  Text('Fecha: ${pedido?['fecha']}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Estado: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        estaConfirmado ? 'CONFIRMADO' : 'NO CONFIRMADO',
                        style: TextStyle(
                          color: estaConfirmado ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!estaConfirmado)
                        ElevatedButton.icon(
                          onPressed: confirmarPedido,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirmar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Productos:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: productos.isEmpty
                        ? const Text('No hay productos en este pedido')
                        : ListView.builder(
                            itemCount: productos.length,
                            itemBuilder: (_, index) {
                              final p = productos[index];

                              return Card(
                                child: ListTile(
                                  title: Text(p['nombre'].toString().trim()),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Cantidad:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 60,
                                            child: TextFormField(
                                              initialValue: p['cantidad']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              enabled: !estaConfirmado,
                                              onChanged: (val) {
                                                final nuevaCantidad =
                                                    int.tryParse(val);
                                                if (nuevaCantidad != null &&
                                                    nuevaCantidad > 0) {
                                                  setState(() {
                                                    productos[index]['cantidad'] =
                                                        nuevaCantidad;
                                                    productos[index]['subtotal'] =
                                                        nuevaCantidad *
                                                        (p['precio'] * 1.0);
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Peso: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 60,
                                            child: TextFormField(
                                              initialValue: p['peso']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              enabled: !estaConfirmado,
                                              onChanged: (val) {
                                                final nuevoPeso =
                                                    double.tryParse(val);
                                                if (nuevoPeso != null &&
                                                    nuevoPeso > 0) {
                                                  setState(() {
                                                    productos[index]['peso'] =
                                                        nuevoPeso;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: estaConfirmado
                                      ? null
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              eliminarProducto(p['id']),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
