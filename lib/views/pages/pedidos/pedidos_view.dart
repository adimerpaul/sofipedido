import 'package:flutter/material.dart';
import 'package:sofiapedido/views/pages/pedidos/detalle_pedido_view.dart';
import 'package:sofiapedido/services/database_helper.dart';

class PedidosView extends StatefulWidget {
  const PedidosView({super.key});

  @override
  State<PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<PedidosView> {
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> filtrados = [];
  List<Map<String, dynamic>> zonaImports = [];

  int total = 0;
  int confirmados = 0;
  int noConfirmados = 0;

  String filtro = '';

  // filtros por chip
  String? fechaFiltro;
  String? colorStyleFiltroHex; // ej. #FF7043
  String? colorNameFiltro;     // ej. deep-orange-4

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await cargarZonaImports();
    await cargarPedidos();
  }

  Future<void> cargarZonaImports() async {
    final data = await DatabaseHelper().obtenerZonaImports(); // historial completo
    setState(() => zonaImports = data);
  }

  Future<void> cargarPedidos() async {
    setState(() => loading = true);
    final db = await DatabaseHelper().database;

    final buffer = StringBuffer('''
      SELECT p.*,
        (SELECT COUNT(*) FROM productos WHERE pedido_id = p.id) AS productos_count
      FROM pedidos p
    ''');

    final args = <Object?>[];
    final whereParts = <String>[];

    if (fechaFiltro != null && fechaFiltro!.isNotEmpty) {
      whereParts.add('date(p.fecha) = ?');
      args.add(fechaFiltro);
    }

    // Filtrar por color: aceptar HEX o nombre
    if ((colorStyleFiltroHex != null && colorStyleFiltroHex!.isNotEmpty) ||
        (colorNameFiltro != null && colorNameFiltro!.isNotEmpty)) {
      if ((colorStyleFiltroHex ?? '').isNotEmpty && (colorNameFiltro ?? '').isNotEmpty) {
        // whereParts.add('(p.colorStyle = ? OR p.colorStyle = ?)');
        // args.addAll([colorStyleFiltroHex, colorNameFiltro]);
        whereParts.add("p.colorStyle like '%' || ? || '%' OR p.colorStyle like '%' || ? || '%'");
        args.addAll([colorStyleFiltroHex!.replaceAll('#', ''), colorNameFiltro!.replaceAll('#', '')]);
      } else {
        // solo uno de los dos está seteado
        whereParts.add('p.colorStyle = ?');
        args.add((colorStyleFiltroHex ?? colorNameFiltro)!);
      }
    }

    if (whereParts.isNotEmpty) {
      buffer.write(' WHERE ${whereParts.join(' AND ')} ');
    }
    buffer.write(' ORDER BY productos_count DESC');

    final todos = await db.rawQuery(buffer.toString(), args);

    final totalCount = todos.length;
    final confirmedCount = todos.where((p) => (p['confirmado'] ?? 0) == 1).length;

    setState(() {
      pedidos = todos;
      total = totalCount;
      confirmados = confirmedCount;
      noConfirmados = totalCount - confirmedCount;
      loading = false;
      aplicarFiltro();
    });
  }

  void aplicarFiltro() {
    final texto = filtro.trim().toLowerCase();
    setState(() {
      if (texto.isEmpty) {
        filtrados = pedidos;
      } else {
        filtrados = pedidos.where((p) {
          final cliente = (p['cliente_nombre'] ?? '').toString().toLowerCase();
          final dir = (p['cliente_direccion'] ?? '').toString().toLowerCase();
          final idtxt = (p['id'] ?? '').toString().toLowerCase();
          return cliente.contains(texto) || dir.contains(texto) || idtxt.contains(texto);
        }).toList();
      }
    });
  }

  void _seleccionarChip(Map<String, dynamic> z) async {
    final fecha = (z['fecha'] ?? '').toString();
    final colorHex = (z['colorStyle'] ?? '').toString(); // #FF7043
    final colorName = (z['color'] ?? '').toString();     // deep-orange-4
    print('fecha: $fecha, colorHex: $colorHex, colorName: $colorName');

    setState(() {
      fechaFiltro = fecha;
      colorStyleFiltroHex = colorHex;
      colorNameFiltro = colorName;
    });
    await cargarPedidos();
  }

  void _limpiarFiltroChips() async {
    setState(() {
      fechaFiltro = null;
      colorStyleFiltroHex = null;
      colorNameFiltro = null;
    });
    await cargarPedidos();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = (fechaFiltro == null && (colorStyleFiltroHex == null && colorNameFiltro == null))
        ? 'Pedidos Importados'
        : 'Pedidos – ${fechaFiltro ?? ''}';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (fechaFiltro != null || colorStyleFiltroHex != null || colorNameFiltro != null)
            TextButton.icon(
              onPressed: _limpiarFiltroChips,
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              label: const Text('Quitar filtro', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // HISTORIAL DE IMPORTACIONES (chips coloreados)
            if (zonaImports.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(
                  chipTheme: Theme.of(context).chipTheme.copyWith(
                    surfaceTintColor: Colors.transparent,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.history, size: 14),
                              SizedBox(width: 4),
                              Text('Historial',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: zonaImports.map((z) {
                                final fecha = (z['fecha'] ?? '').toString();
                                final zona = (z['zona'] ?? '').toString();
                                final colorHex = (z['colorStyle'] as String?)?.replaceAll('#', '') ?? '757575';
                                final bg = Color(int.parse('0xFF$colorHex'));

                                final isSelected = (fechaFiltro == fecha) &&
                                    ((colorStyleFiltroHex == (z['colorStyle'] ?? '')) ||
                                        (colorNameFiltro == (z['color'] ?? '')));

                                return ChoiceChip(
                                  label: Text(
                                    '$fecha · $zona',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) => _seleccionarChip(z),
                                  backgroundColor: bg,
                                  selectedColor: bg,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.transparent, width: 0),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // RESUMEN
            Card(
              elevation: 1,
              margin: const EdgeInsets.only(top: 6, bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('$total', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Confirmados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('$confirmados', style: const TextStyle(fontSize: 14, color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('No confirmados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('$noConfirmados', style: const TextStyle(fontSize: 14, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // BUSCADOR
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

            // LISTA
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
                        backgroundColor: (p['confirmado'] ?? 0) == 1 ? Colors.green : Colors.grey,
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
                          Text(p['cliente_nombre'] ?? ''),
                          Text(p['cliente_direccion'] ?? ''),
                          Text('📅 ${p['fecha'] ?? ''}'),
                        ],
                      ),
                      trailing: (p['confirmado'] ?? 0) == 1
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked, color: Colors.red),
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
