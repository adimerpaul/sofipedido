import 'package:flutter/material.dart';

class PedidosView extends StatelessWidget {
  const PedidosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'This is the Pedidos View',
            style: TextStyle(fontSize: 24),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigator.pop(context);
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }
}
