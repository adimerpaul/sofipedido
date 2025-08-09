import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sofiapedido/services/database_helper.dart';

class ProductosTotalesView extends StatefulWidget {
  const ProductosTotalesView({super.key});

  @override
  State<ProductosTotalesView> createState() => _ProductosTotalesViewState();
}

class _ProductosTotalesViewState extends State<ProductosTotalesView> {
  List<Map<String, dynamic>> productos = [];
  bool loading = true;
  DateTime fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  String get _fechaStr => DateFormat('yyyy-MM-dd').format(fecha);

  Future<void> _cargarProductos() async {
    setState(() => loading = true);
    final data = await DatabaseHelper().obtenerProductosTotalesGuardados();
    setState(() {
      productos = data;
      loading = false;
    });
  }

  Future<void> _importar() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => loading = true);
    try {
      await DatabaseHelper().importarResumenProductosDesdeApi(_fechaStr);
      await _cargarProductos();
      messenger.showSnackBar(
        SnackBar(content: Text('Importado OK para $_fechaStr')),
      );
    } catch (e) {
      setState(() => loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error al importar: $e')),
      );
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Selecciona fecha',
    );
    if (picked != null) {
      setState(() => fecha = picked);
    }
  }

  // Helpers para castear seguro
  double _asDouble(dynamic v) =>
      (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

  @override
  Widget build(BuildContext context) {
    final totalItems = productos.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen de Productos ($totalItems)'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Fila de controles: fecha + importar
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_fechaStr),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _importar,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Importar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : productos.isEmpty
                  ? const Center(child: Text('No hay productos registrados'))
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: productos.length,
                itemBuilder: (_, index) {
                  final p = productos[index];
                  final totalCant = _asDouble(p['total_cantidad']);
                  final totalBs = _asDouble(p['total_subtotal']);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Text(
                          totalCant.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        p['nombre']?.toString().trim() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Código: ${p['cod_prod'] ?? '-'}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Total Bs.'),
                          Text(
                            totalBs.toStringAsFixed(2),
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
            ),
          ],
        ),
      ),
    );
  }
}
