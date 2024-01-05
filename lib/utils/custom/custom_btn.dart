import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/colors.dart';

class CustomButton extends StatelessWidget {
  final String btnName;
  final String disableBtnText;
  final Color? color;
  final Color textColor;
  final bool isBtnEnable;
  final bool isPaddingEnable;
  final VoidCallback? callback;

  const CustomButton(
      {super.key,
      required this.btnName,
      this.disableBtnText = "",
      this.color = themeOrangeColor,
      this.callback,
      this.isBtnEnable = true,
      this.isPaddingEnable = true,
      this.textColor = textWhiteColor});

  @override
  Widget build(BuildContext context) {
    return isBtnEnable
        ? Padding(
            padding: EdgeInsets.all(isPaddingEnable ? 8.0 : 0),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  callback?.call();
                },
                child: Text(
                  btnName,
                  style: TextStyle(color: textColor, fontSize: 17),
                ),
              ),
            ),
          )
        : Padding(
            padding: EdgeInsets.all(isPaddingEnable ? 8.0 : 0),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(disableBtnColor),
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)))),
                  child: Text(
                    disableBtnText != "" ? disableBtnText : btnName,
                    style: TextStyle(color: disableBtnTextColor, fontSize: 17),
                  )),
            ),
          );
  }
}
