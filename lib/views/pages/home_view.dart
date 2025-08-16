import 'package:flutter/material.dart';
import 'package:sofiapedido/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onImportPressed;
  final VoidCallback? onPedidosPressed;
  const HomeView({super.key, this.onImportPressed, this.onPedidosPressed});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool loading = true;

  // Totales
  int total = 0;
  int confirmados = 0;
  int noConfirmados = 0;

  // Historial de zonas importadas (últimas)
  List<Map<String, dynamic>> zonaImports = [];

  @override
  void initState() {
    super.initState();
    _cargarHomeData();
  }

  Future<void> _cargarHomeData() async {
    final db = await DatabaseHelper().database;

    // Totales
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pedidos'),
    ) ??
        0;

    final confirmedCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pedidos WHERE confirmado = 1'),
    ) ??
        0;

    // Historial zonas (últimos 12 registros)
    final zonas = await DatabaseHelper().obtenerZonaImports(); // ordenado DESC
    final ultimas = zonas.length > 12 ? zonas.sublist(0, 12) : zonas;

    setState(() {
      total = totalCount;
      confirmados = confirmedCount;
      noConfirmados = totalCount - confirmedCount;
      zonaImports = ultimas;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarHomeData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          // Logo compacto arriba
          Center(
            child: Image.asset('assets/logo.png', width: 140, height: 140),
          ),

          const SizedBox(height: 8),

          // Card de resumen SUPER compacto
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(top: 6, bottom: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniStat('Total', total, Colors.black87),
                  _miniStat('✔', confirmados, Colors.green),
                  _miniStat('✖', noConfirmados, Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Mini gráfico (barras) Confirmados vs No confirmados
          const SizedBox(height: 110, child: _MiniBarChart()),

          const SizedBox(height: 10),

          // Historial de importaciones (chips compactos)
          if (zonaImports.isNotEmpty) ...[
            Row(
              children: const [
                Icon(Icons.history, size: 16),
                SizedBox(width: 6),
                Text('Zonas importadas',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: zonaImports.map((z) {
                final fecha = (z['fecha'] ?? '').toString();
                final zona = (z['zona'] ?? '').toString();
                final colorHex =
                    (z['colorStyle'] as String?)?.replaceAll('#', '') ?? '757575';
                final bg = Color(int.parse('0xFF$colorHex'));
                return Chip(
                  label: Text(
                    '$fecha · $zona',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: bg.withValues(alpha: 0.90),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.60),
                      width: 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                );
              }).toList(),
            ),
          ] else
            _emptyHint(),

          const SizedBox(height: 16),

          // Acciones rápidas
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.download,
                  label: 'Importar',
                  color: Colors.green.shade600,
                  onTap: () {
                    widget.onImportPressed?.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickTile(
                  icon: Icons.list_alt,
                  label: 'Pedidos',
                  color: Colors.red.shade600,
                  onTap: () {
                    // Navigator.pushNamed(context, '/pedidos');
                    widget.onPedidosPressed?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _emptyHint() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Aún no hay zonas importadas. Importa pedidos para verlas aquí.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    );
  }
}

/// MiniBarChart usa LayoutBuilder para evitar overflow.
/// Consume exactamente el alto de su contenedor padre.
class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart();

  @override
  Widget build(BuildContext context) {
    // Los valores los toma del Inherited de arriba? No; para simplicidad,
    // accedemos al estado via context.findAncestorStateOfType.
    final state = context.findAncestorStateOfType<_HomeViewState>();
    final confirmados = state?.confirmados ?? 0;
    final noConfirmados = state?.noConfirmados ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = (confirmados + noConfirmados).clamp(0, 1 << 30);
        final maxVal = total == 0 ? 1.0 : total.toDouble();
        final confPct = total == 0 ? 0.0 : confirmados / maxVal;
        final noConfPct = total == 0 ? 0.0 : noConfirmados / maxVal;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Confirmados
              Expanded(
                child: _Bar(
                  valuePct: confPct,
                  color: Colors.green,
                  label: 'Confirmados',
                  value: confirmados,
                ),
              ),
              const SizedBox(width: 12),
              // No confirmados
              Expanded(
                child: _Bar(
                  valuePct: noConfPct,
                  color: Colors.red,
                  label: 'No conf.',
                  value: noConfirmados,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final double valuePct; // 0..1
  final MaterialColor color; // MaterialColor para shade700
  final String label;
  final int value;

  const _Bar({
    required this.valuePct,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Column sin overflow: el centro (barra) usa Expanded
    return LayoutBuilder(
      builder: (context, constraints) {
        final pct = valuePct.isNaN ? 0.0 : valuePct.clamp(0.0, 1.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Valor numérico (una sola línea)
            Text(
              '$value',
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 12,
                color: color.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),

            // Área de la barra se adapta al espacio disponible
            Expanded(
              child: Container(
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
                child: FractionallySizedBox(
                  heightFactor: pct, // usa porcentaje, sin tamaños fijos
                  widthFactor: 1,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(5),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Etiqueta (una línea)
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
