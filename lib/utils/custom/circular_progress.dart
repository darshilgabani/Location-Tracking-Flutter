import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/colors.dart';

class CircularProgress extends StatelessWidget {
  const CircularProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: themeOrangeColor,
      ),
    );
  }
}
