import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/planner_controller.dart';
import '../data/cloud_planner_repository.dart';
import 'home_page.dart';
import 'sign_in_page.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  String? _attachedUid;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final user = auth.user;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final planner = context.read<PlannerController>();
          final cloud = context.read<CloudPlannerRepository>();

          final uid = user?.uid;
          if (uid == _attachedUid) return;

          _attachedUid = uid;
          if (uid == null) {
            await planner.detachCloudSync();
          } else {
            await planner.attachCloudSync(uid: uid, cloud: cloud);
          }
        });

        if (user == null) return const SignInPage();
        return const HomePage();
      },
    );
  }
}