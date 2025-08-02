import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static String? url = dotenv.env['API_URL'];

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = '$dbPath/sofia_pedido.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tables here
        await db.execute('''
          CREATE TABLE pedidos (
            id TEXT PRIMARY KEY,
            clienteId TEXT,
            dataPedido TEXT,
            total REAL
          )
        ''');
      },
    );
  }
}