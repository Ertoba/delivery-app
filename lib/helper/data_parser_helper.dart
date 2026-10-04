import 'package:flutter/foundation.dart';

class DataParserHelper {
  static List<int> convertIntoListOfInteger(String options) {
    List<int> result = [];
    String s = options.replaceAll('(', '').replaceAll(')', '');
    List<String> res = s.split(',');
    for (String element in res) {
      try {
        result.add(int.parse(element));
      } catch (e) {
        if (kDebugMode) {
          print('=====not converted : $e');
        }
      }
    }
    return result;
  }

  static bool parseBool(dynamic value){
    return value == 'true' || value == true || value == 1 || value == '1';
  }

  static int? parseInt(dynamic value, {bool keepDefaultZero = true}){
    return num.tryParse(value.toString())?.toInt() ?? (keepDefaultZero ? 0 : null);
  }

  static double? parseDouble(dynamic value, {bool keepDefaultZero = true}){
    return num.tryParse(value.toString())?.toDouble() ?? (keepDefaultZero ? 0.0 : null);
  }

}
