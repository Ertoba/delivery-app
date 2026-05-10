import 'package:fluttertoast/fluttertoast.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/helper/server_message_translator.dart';

void showCustomSnackBar(
  String? message, {
  bool isError = true,
  bool getXSnackBar = true,
}) {
  final String displayMessage = ServerMessageTranslator.translate(message);

  if (displayMessage.isEmpty) {
    return;
  }

  if (getXSnackBar) {
    Get.showSnackbar(
      GetSnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        message: displayMessage,
        duration: const Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        borderRadius: 10,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  } else {
    Fluttertoast.showToast(
      msg: displayMessage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
