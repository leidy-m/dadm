import 'package:flutter/material.dart';
import './home_screen.dart'; // Importa el archivo de HomeScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Directorio de Empresas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Establece HomeScreen como la pantalla principal
    );
  }
}
