import 'package:flutter/material.dart';

class Utils {
  Utils._();

  static void customChangeFocusOfTextField(
    BuildContext context,
    FocusNode originFocusNode,
    FocusNode? destinationFocusNode,
  ) {
    originFocusNode.unfocus();
    destinationFocusNode != null
        ? FocusScope.of(context).requestFocus(destinationFocusNode)
        : null;
  }
}
