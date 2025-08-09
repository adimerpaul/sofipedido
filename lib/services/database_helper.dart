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
      },
    );
  }

  Future<void> importarPedidosDesdeApi(String fecha, String color) async {
    final db = await database;

    final response = await http.post(
      Uri.parse('$url/importPedido'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"fecha": fecha, "color": color}),
    );
    // print('Llamando a API: $url/importPedido');
    // print('Request: ${jsonEncode({"fecha": fecha, "color": color})}');
    // print('Response: ${response.statusCode} - ${response.body}');

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

    final pedidos = await db.query('pedidos');
    List<Map<String, dynamic>> exportList = [];

    for (var pedido in pedidos) {
      final productos = await db.query(
        'productos',
        where: 'pedido_id = ?',
        whereArgs: [pedido['id']],
      );

      exportList.add({
        ...pedido,
        'nro_pedido': pedido['id'], // mapeo al campo del backend
        'productos': productos
      });
    }

    final response = await http.post(
      Uri.parse('$url/exportar-pedidos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pedidos': exportList}),
    );

    if (response.statusCode == 200) {
      // Marca como exportados (confirmado = 1)
      for (var pedido in pedidos) {
        await db.update(
          'pedidos',
          {'confirmado': 1},
          where: 'id = ?',
          whereArgs: [pedido['id']],
        );
      }
    } else {
      throw Exception('Error al exportar: ${response.statusCode}');
    }
  }


  Future<List<Map<String, dynamic>>> exportarProductos(int pedidoId) async {
    final db = await database;
    return await db.query('productos', where: 'pedido_id = ?', whereArgs: [pedidoId]);
  }
  Future<void> vaciarTodo() async {
    final db = await database;
    await db.delete('productos');
    await db.delete('pedidos');
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
