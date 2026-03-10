import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void applySystemUiStyle() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // ANDROID: Icons dunkel
      statusBarBrightness: Brightness.light, // iOS
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}