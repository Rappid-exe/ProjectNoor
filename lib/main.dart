import 'package:flutter/material.dart';
import 'package:noor/theme/app_theme.dart';
import 'package:noor/views/chat/model_check_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ModelCheckWrapper(),
    );
  }
}
