class ReferralReportModel {
  List<RefrealEarnings>? refrealEarnings;
  double? totalLoyaltyPointEarning;
  double? totalReferal;
  double? totalDmTips;
  double? totalDeliveryCharge;
  double? totalAdminCommission;
  String? type;
  String? limit;
  String? offset;
  int? total;

  ReferralReportModel({
    this.refrealEarnings,
    this.totalLoyaltyPointEarning,
    this.totalReferal,
    this.totalDmTips,
    this.totalDeliveryCharge,
    this.totalAdminCommission,
    this.type,
    this.limit,
    this.offset,
    this.total,
  });

  ReferralReportModel.fromJson(Map<String, dynamic> json) {
    final dynamic earningList = json['refrealEarnings'] ?? json['data'];
    if (earningList is List) {
      refrealEarnings = <RefrealEarnings>[];
      earningList.forEach((v) {
        refrealEarnings!.add(RefrealEarnings.fromJson(v));
      });
    }
    totalLoyaltyPointEarning = json['total_loyalty_point_earning']?.toDouble();
    totalReferal = json['total_referal']?.toDouble();
    totalDmTips = json['total_dm_tips']?.toDouble();
    totalDeliveryCharge = json['total_delivery_charge']?.toDouble();
    totalAdminCommission = json['total_admin_commission']?.toDouble();
    type = json['type'];
    limit = json['pagination'] != null
        ? json['pagination']['per_page']?.toString()
        : json['limit'];
    offset = json['pagination'] != null
        ? json['pagination']['current_page']?.toString()
        : json['offset'];
    total = json['pagination'] != null ? json['pagination']['total'] : json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (refrealEarnings != null) {
      data['refrealEarnings'] = refrealEarnings!.map((v) => v.toJson()).toList();
    }
    data['total_loyalty_point_earning'] = totalLoyaltyPointEarning;
    data['total_referal'] = totalReferal;
    data['total_dm_tips'] = totalDmTips;
    data['total_delivery_charge'] = totalDeliveryCharge;
    data['total_admin_commission'] = totalAdminCommission;
    data['type'] = type;
    data['limit'] = limit;
    data['offset'] = offset;
    return data;
  }
}

class RefrealEarnings {
  int? id;
  String? transactionId;
  double? amount;
  String? createdAt;

  RefrealEarnings({this.id, this.transactionId, this.amount, this.createdAt});

  RefrealEarnings.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    transactionId = json['transaction_id'];
    amount = json['amount']?.toDouble();
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['transaction_id'] = transactionId;
    data['amount'] = amount;
    data['created_at'] = createdAt;
    return data;
  }
}
