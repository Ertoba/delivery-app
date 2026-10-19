class DeliveryIncomeStatementModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<DeliveryIncomeStatement>? transactions;

  DeliveryIncomeStatementModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.transactions,
  });

  DeliveryIncomeStatementModel.fromJson(Map<String, dynamic> json) {
    if (json['pagination'] is Map) {
      totalSize = json['pagination']['total'];
      limit = json['pagination']['per_page'];
      offset = json['pagination']['current_page'];
    } else {
      totalSize = int.tryParse(json['total_size'].toString());
      limit = int.tryParse(json['limit'].toString());
      offset = int.tryParse(json['offset'].toString());
    }
    final dynamic rows = json['data'];
    if (rows is List) {
      transactions = <DeliveryIncomeStatement>[];
      for (final dynamic v in rows) {
        transactions!.add(DeliveryIncomeStatement.fromJson(v));
      }
    }
  }
}

class DeliveryIncomeStatement {
  int? id;
  int? vendorId;
  int? deliveryManId;
  int? orderId;
  double? orderAmount;
  double? storeAmount;
  double? adminCommission;
  String? receivedBy;
  String? createdAt;
  String? updatedAt;
  double? deliveryCharge;
  double? originalDeliveryCharge;
  double? tax;
  double? dmTips;
  double? deliveryFeeComission;

  DeliveryIncomeStatement({
    this.id,
    this.vendorId,
    this.deliveryManId,
    this.orderId,
    this.orderAmount,
    this.storeAmount,
    this.adminCommission,
    this.receivedBy,
    this.createdAt,
    this.updatedAt,
    this.deliveryCharge,
    this.originalDeliveryCharge,
    this.tax,
    this.dmTips,
    this.deliveryFeeComission,
  });

  DeliveryIncomeStatement.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = int.tryParse(json['vendor_id'].toString());
    deliveryManId = int.tryParse(json['delivery_man_id'].toString());
    orderId = int.tryParse(json['order_id'].toString());
    orderAmount = double.tryParse(json['order_amount'].toString());
    storeAmount = double.tryParse(json['store_amount'].toString());
    adminCommission = double.tryParse(json['admin_commission'].toString());
    receivedBy = json['received_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deliveryCharge = double.tryParse(json['delivery_charge'].toString());
    originalDeliveryCharge = double.tryParse(
      json['original_delivery_charge'].toString(),
    );
    tax = double.tryParse(json['tax'].toString());
    dmTips = double.tryParse(json['dm_tips'].toString());
    deliveryFeeComission = double.tryParse(
      json['delivery_fee_comission'].toString(),
    );
  }
}
