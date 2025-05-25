import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/bluetooth_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BluetoothService(),
      child: MaterialApp(
        title: 'Doğalgaz Kaçağı Tespit Sistemi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue.shade700,
            secondary: Colors.orange,
            error: Colors.red,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          cardTheme: const CardTheme(
            clipBehavior: Clip.antiAlias,
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 4),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
