import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/ui/screen_location_list/location_list_screen.dart';
import 'package:location_tracking_flutter/utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appThemeData,
      home: LocationListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

