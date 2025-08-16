import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sofiapedido/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  bool loading = false;
  String mensaje = '';
  String fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());

  int total = 0;
  int confirmados = 0;
  int noConfirmados = 0;

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

  @override
  void initState() {
    super.initState();
    cargarTotales();
  }
  Future<void> vaciarDatos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('Esto eliminará todos los pedidos y productos importados.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, eliminar', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      setState(() {
        loading = true;
        mensaje = 'Eliminando datos...';
      });

      try {
        await DatabaseHelper().vaciarTodo();
        await cargarTotales();
        setState(() => mensaje = 'Datos eliminados correctamente 🗑');
      } catch (e) {
        setState(() => mensaje = 'Error al eliminar ❌: $e');
      } finally {
        setState(() => loading = false);
      }
    }
  }


  Future<void> cargarTotales() async {
    final db = await DatabaseHelper().database;
    final totalCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pedidos')) ?? 0;
    final confirmedCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pedidos WHERE confirmado = 1')) ?? 0;
    setState(() {
      total = totalCount;
      confirmados = confirmedCount;
      noConfirmados = totalCount - confirmedCount;
    });
  }

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
        colorSeleccionado!,
      );
      setState(() => mensaje = 'Datos importados correctamente ✅');
      await cargarTotales();
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
      await DatabaseHelper().exportarPedidos();
      setState(() => mensaje = 'Exportado correctamente ✅');
      await cargarTotales();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Importar / Exportar Pedidos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 🟨 CARD DE RESUMEN
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _resumenBox('Importados', total, Colors.black87),
                    _resumenBox('Confirmados', confirmados, Colors.green),
                    _resumenBox('No confirmados', noConfirmados, Colors.red),
                  ],
                ),
              ),
            ),

            // 📆 INPUT DE FECHA
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

            // 🎨 SELECTOR DE COLORES
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

            // 📥 Botón de importar
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

            // 📤 Botón de exportar
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
            const SizedBox(height: 10),

// 🗑 Botón de vaciar datos
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Vaciar todos los datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading ? null : vaciarDatos,
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

  Widget _resumenBox(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          '$cantidad',
          style: TextStyle(fontSize: 20, color: color),
        ),
      ],
    );
  }
}
