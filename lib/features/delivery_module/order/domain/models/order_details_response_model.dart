import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';

class OrderDetailsResponseModel {
  final List<OrderDetailsModel> details;
  final EtaModel? eta;

  OrderDetailsResponseModel({required this.details, this.eta});

  factory OrderDetailsResponseModel.fromResponse(dynamic content) {
    if (content is Map) {
      return OrderDetailsResponseModel(
        details: _parseDetails(content['details'] ?? content['data']),
        eta: content['eta'] is Map ? EtaModel.fromJson(Map<String, dynamic>.from(content['eta'])) : null,
      );
    }
    return OrderDetailsResponseModel(details: _parseDetails(content));
  }

  static List<OrderDetailsModel> _parseDetails(dynamic raw) {
    final List<OrderDetailsModel> details = [];
    if (raw is List) {
      for (final dynamic item in raw) {
        if (item is Map) {
          details.add(OrderDetailsModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return details;
  }
}
