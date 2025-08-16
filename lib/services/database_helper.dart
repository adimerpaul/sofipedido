import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static String? url = dotenv.env['API_URL'];

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/sofia_pedido.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla PEDIDOS
        await db.execute('''
          CREATE TABLE pedidos (
            id INTEGER PRIMARY KEY,
            fecha TEXT,
            cliente_id TEXT,
            cliente_nombre TEXT,
            cliente_direccion TEXT,
            cliente_telefono TEXT,
            cliente_zona TEXT,
            user_id TEXT,
            user_nombre TEXT,
            user_apellido TEXT,
            estado TEXT,
            fact TEXT,
            comentario TEXT,
            pago TEXT,
            placa TEXT,
            horario TEXT,
            colorStyle TEXT,
            cod_prod TEXT,
            precio REAL,
            cantidad REAL,
            cantidad_texto TEXT,
            subtotal REAL,
            bonificacion INTEGER,
            bonificacion_aprobacion TEXT,
            bonificacion_id TEXT,
            confirmado INTEGER DEFAULT 0
          )
        ''');

        // Tabla PRODUCTOS
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedido_id INTEGER,
            cod_prod TEXT,
            nombre TEXT,
            precio REAL,
            cantidad REAL,
            peso REAL default 0,
            cantidad_texto TEXT,
            subtotal REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE productos_totales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT,
            cod_prod TEXT,
            nombre TEXT,
            total_cantidad REAL,
            total_subtotal REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE zona_import (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT,
            zona TEXT,
            color TEXT,
            colorStyle TEXT,
          )
        ''');
      },
    );
  }
  // 1) Importa desde API y guarda LOCAL (vacía y vuelve a llenar)
  Future<void> importarResumenProductosDesdeApi(String fecha) async {
    final db = await database;

    final response = await http.post(
      Uri.parse('$url/reporteTotalProductos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"fecha": fecha}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al llamar API: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json['status'] != 'success') {
      throw Exception('Error desde servidor: ${json['message']}');
    }

    final List productos = json['data'];

    // transacción para atomicidad + rendimiento
    await db.transaction((txn) async {
      await txn.delete('productos_totales');

      final batch = txn.batch();
      for (var prod in productos) {
        batch.insert('productos_totales', {
          'fecha': fecha,
          'cod_prod': prod['cod_prod'],
          'nombre': prod['nombre'],
          'total_cantidad':
          double.tryParse(prod['total_cantidad'].toString()) ?? 0.0,
          'total_subtotal':
          double.tryParse(prod['total_subtotal'].toString()) ?? 0.0,
        });
      }
      await batch.commit(noResult: true);
    });
  }

// 2) Lee SOLO de la tabla local (sin API)
  Future<List<Map<String, dynamic>>> obtenerProductosTotalesGuardados() async {
    final db = await database;
    return await db.query(
      'productos_totales',
      orderBy: 'total_cantidad DESC',
    );
  }
  // insertColorImport
  Future<void> insertColorImport(String fecha, String zona, String color, String colorStyle) async {
    final db = await database;
    await db.insert('zona_import', {
      'fecha': fecha,
      'zona': zona,
      'color': color,
      'colorStyle': colorStyle,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> importarPedidosDesdeApi(String fecha, color) async {
    final db = await database;

    final response = await http.post(
      Uri.parse('$url/importPedido'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"fecha": fecha, "color": color['color']}),
    );
    // print('Llamando a API: $url/importPedido');
    // print('Request: ${jsonEncode({"fecha": fecha, "color": color})}');
    // print('Response: ${response.statusCode} - ${response.body}');
    insertColorImport(fecha, color['zona'], color['color'], color['colorStyle']);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        final List pedidos = json['data'];

        for (var item in pedidos) {
          final pedido = item['pedido'];
          final cliente = pedido['cliente'];
          final user = pedido['user'];
          final productos = item['productos'];

          // Insertar en tabla pedidos
          await db.insert('pedidos', {
            'id': pedido['NroPed'],
            'fecha': pedido['fecha'],
            'cliente_id': pedido['idCli'],
            'cliente_nombre': cliente?['Nombres'] ?? '',
            'cliente_direccion': cliente?['Direccion'] ?? '',
            'cliente_telefono': cliente?['Telf'] ?? '',
            'cliente_zona': cliente?['zona'] ?? '',
            'user_id': user?['CodAut'] ?? '',
            'user_nombre': user?['Nombre1'] ?? '',
            'user_apellido': user?['App1'] ?? '',
            'estado': pedido['estado'],
            'fact': pedido['fact'],
            'comentario': pedido['comentario'] ?? '',
            'pago': pedido['pago'],
            'placa': pedido['placa'],
            'horario': pedido['horario'] ?? '',
            'colorStyle': pedido['colorStyle'],
            'cod_prod': pedido['cod_prod'],
            'precio': double.tryParse(pedido['precio'].toString()) ?? 0.0,
            'cantidad': double.tryParse(pedido['Cant'].toString()) ?? 0.0,
            'cantidad_texto': pedido['Canttxt'],
            'subtotal': double.tryParse(pedido['subtotal'].toString()) ?? 0.0,
            'bonificacion': pedido['bonificacion'],
            'bonificacion_aprobacion': pedido['bonificacionAprovacion'],
            'bonificacion_id': pedido['bonificacionId']?.toString() ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Insertar productos relacionados
          for (var prod in productos) {
            await db.insert('productos', {
              'pedido_id': pedido['NroPed'],
              'cod_prod': prod['cod_prod'],
              'nombre': prod['producto'],
              'precio': double.tryParse(prod['precio'].toString()) ?? 0.0,
              'cantidad': double.tryParse(prod['Cant'].toString()) ?? 0.0,
              'peso': 0.0,
              'cantidad_texto': prod['Canttxt'],
              'subtotal': double.tryParse(prod['subtotal'].toString()) ?? 0.0,
            });
          }
        }
      } else {
        throw Exception('Error desde servidor: ${json['message']}');
      }
    } else {
      throw Exception('Error al llamar API: ${response.statusCode}');
    }
  }

  Future<void> exportarPedidos() async {
    final db = await database;

    // Solo no confirmados (ajusta si quieres otro filtro)
    final pedidos = await db.query('pedidos', where: 'confirmado = 1');

    if (pedidos.isEmpty) {
      throw Exception('No hay pedidos pendientes para exportar.');
    }

    final exportList = <Map<String, dynamic>>[];

    for (var pedido in pedidos) {
      final productos = await db.query(
        'productos',
        where: 'pedido_id = ?',
        whereArgs: [pedido['id']],
      );

      exportList.add({
        ...pedido,
        'nro_pedido': pedido['id'],
        'productos': productos.map((p) => {
          'cod_prod': p['cod_prod'],
          'nombre': p['nombre'],
          'precio': (p['precio'] as num?)?.toDouble() ?? 0.0,
          'cantidad': (p['cantidad'] as num?)?.toDouble() ?? 0.0,
          'peso': (p['peso'] as num?)?.toDouble() ?? 0.0,   // <-- AQUI
          'cantidad_texto': p['cantidad_texto'],
          'subtotal': (p['subtotal'] as num?)?.toDouble() ?? 0.0,
        }).toList(),
      });
    }

    final uri = Uri.parse('$url/exportar-pedidos');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'pedidos': exportList}),
    );

    // Logs útiles para ver el problema real
    // ignore: avoid_print
    print('EXPORT status: ${res.statusCode}');
    // ignore: avoid_print
    print('EXPORT body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Error HTTP ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body);
    if (json is! Map || json['status'] != 'success') {
      throw Exception('Exportación fallida: ${res.body}');
    }

    // Marca confirmados localmente
    final batch = db.batch();
    for (var pedido in pedidos) {
      batch.update(
        'pedidos',
        {'confirmado': 1},
        where: 'id = ?',
        whereArgs: [pedido['id']],
      );
    }
    await batch.commit(noResult: true);
  }



  Future<List<Map<String, dynamic>>> exportarProductos(int pedidoId) async {
    final db = await database;
    return await db.query('productos', where: 'pedido_id = ?', whereArgs: [pedidoId]);
  }
  Future<void> vaciarTodo() async {
    final db = await database;
    await db.delete('productos');
    await db.delete('pedidos');
    await db.delete('zona_import');
  }
  Future<List<Map<String, dynamic>>> obtenerResumenProductos() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      cod_prod,
      nombre,
      SUM(cantidad) AS total_cantidad,
      SUM(subtotal) AS total_subtotal
    FROM productos
    GROUP BY cod_prod, nombre
    ORDER BY total_cantidad DESC
  ''');
  }

}
