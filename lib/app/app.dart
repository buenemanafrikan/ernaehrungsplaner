import 'package:flutter/material.dart';

import '../ui/root_gate.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ernährungsplaner",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(context),
      home: const RootGate(),
    );
  }
}