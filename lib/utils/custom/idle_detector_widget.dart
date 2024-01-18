import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/helper.dart';
import 'package:location_tracking_flutter/utils/theme.dart';

class IdleDetector extends StatefulWidget {
  final Widget child;
  final Function? onUserInActive;
  final Function? onUserActive;
  final VoidCallback? callback;

  const IdleDetector(
      {super.key,
      required this.child,
      this.onUserActive,
      this.onUserInActive,
      this.callback});

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector> {
  @override
  Widget build(BuildContext context) {
    bool isPanGesture = false;
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // if (!isPanGesture) {
          handleUserInteraction();
          // }
        },
        // onPanDown: (details) {
        //   // isPanGesture = true;
        //   // handleUserInteraction();
        // },
        // onPanEnd: (details) {
        //   // isPanGesture = false;
        // },
        child: MaterialApp(
          home: widget.child,
          debugShowCheckedModeBanner: false,
        ));
  }
}

void handleUserInteraction() {
  // showSnackBar(context, "Clicked");
  print("@@## Clicked Clicked");
}
