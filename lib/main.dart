import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sofiapedido/views/home_view.dart';
Future main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  const bool isProduction = bool.fromEnvironment('dart.vm.product');
  await dotenv.load(fileName: isProduction ? '.env' : '.env.development');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sofia Pedido',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      routes: {
        '/': (context) => const HomeView(),
      },
      initialRoute: '/',
      // home: const MyHomePage(),
    );
  }
}

