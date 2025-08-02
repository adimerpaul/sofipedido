import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sofiapedido/services/database_helper.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  bool loading = false;
  String mensaje = '';
  String fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Colores disponibles (zona + color real)
  final List<Map<String, String>> colores = [
    {"zona": "NORTE", "color": "deep-orange-4", "colorStyle": "#FF7043"},
    {"zona": "BOLIVAR", "color": "pink-4", "colorStyle": "#F06292"},
    {"zona": "SE RECOGE", "color": "blue-grey-4", "colorStyle": "#37474F"},
    {"zona": "CENTRO", "color": "yellow", "colorStyle": "#F5EE17"},
    {"zona": "APOYO", "color": "green-4", "colorStyle": "#1B5E20"},
    {"zona": "PROVINCIA", "color": "deep-purple-4", "colorStyle": "#9575CD"},
    {"zona": "SUD", "color": "blue-4", "colorStyle": "#0D47A1"},
    {"zona": "SIN ZONA", "color": "grey-6", "colorStyle": "#757575"},
  ];

  Map<String, String>? colorSeleccionado;

  Future<void> importarDatos() async {
    if (colorSeleccionado == null || fecha.isEmpty) {
      setState(() => mensaje = 'Selecciona una fecha y una zona');
      return;
    }

    setState(() {
      loading = true;
      mensaje = 'Importando...';
    });

    try {
      await DatabaseHelper().importarPedidosDesdeApi(
        fecha,
        colorSeleccionado!['color']!,
      );
      setState(() => mensaje = 'Datos importados correctamente ✅');
    } catch (e) {
      setState(() => mensaje = 'Error al importar ❌: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> exportarDatos() async {
    setState(() {
      loading = true;
      mensaje = 'Exportando...';
    });

    try {
      final pedidos = await DatabaseHelper().exportarPedidos();
      setState(() => mensaje = 'Exportado ${pedidos.length} pedidos');
    } catch (e) {
      setState(() => mensaje = 'Error al exportar ❌: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Importar / Exportar Pedidos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Input de fecha
            TextFormField(
              initialValue: fecha,
              onChanged: (val) => fecha = val,
              decoration: const InputDecoration(
                labelText: 'Fecha (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),

            // Dropdown de colores
            DropdownButtonFormField<Map<String, String>>(
              value: colorSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Zona para importar',
                border: OutlineInputBorder(),
              ),
              items: colores.map((color) {
                return DropdownMenuItem(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${color['colorStyle']!.substring(1)}')),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(color['zona']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => colorSeleccionado = val);
              },
            ),
            const SizedBox(height: 24),

            // Botón de importar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Importar desde API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading ? null : importarDatos,
              ),
            ),
            const SizedBox(height: 10),

            // Botón de exportar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text('Exportar desde DB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading ? null : exportarDatos,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: mensaje.contains('✅') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
