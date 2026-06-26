import 'package:sixam_mart_delivery/common/models/config_model.dart';

class PaymentMethodFilterHelper {
  static List<PaymentBody> nonKeepzMethods(List<PaymentBody>? methods) {
    if (methods == null) {
      return <PaymentBody>[];
    }

    return methods.where((method) => !isKeepz(method)).toList();
  }

  static bool isKeepz(PaymentBody method) {
    final String gateway = method.getWay?.trim().toLowerCase() ?? '';
    final String title = method.getWayTitle?.trim().toLowerCase() ?? '';

    return gateway == 'keepz' ||
        gateway.contains('keepz') ||
        title.contains('keepz');
  }
}
