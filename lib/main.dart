import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'app/app.dart';
import 'app/system_ui.dart';
import 'controllers/auth_controller.dart';
import 'controllers/planner_controller.dart';
import 'data/cloud_planner_repository.dart';
import 'data/planner_repository_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  applySystemUiStyle();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final localRepo = PlannerRepository(prefs);
  final initial = await localRepo.load();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CloudPlannerRepository(FirebaseFirestore.instance)),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(
          create: (_) => PlannerController(localRepo: localRepo, initial: initial),
        ),
      ],
      child: const MyApp(),
    ),
  );
}