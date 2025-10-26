import 'package:flutter/material.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Ayarları'),
      ),
      body: const Center(
        child: Text('Tema ayarları yakında eklenecek'),
      ),
    );
  }
}
