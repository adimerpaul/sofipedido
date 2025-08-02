import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/logo.png', width: 200, height: 200),
    );
  }
}
