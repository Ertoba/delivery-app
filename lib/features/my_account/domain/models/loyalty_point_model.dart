import 'package:sixam_mart_delivery/features/my_account/domain/models/loyalty_report_model.dart';

class LoyaltyPointModel {
  int? total;
  String? limit;
  String? offset;
  List<LoyalityPoints>? loyalityPoints;

  LoyaltyPointModel({this.total, this.limit, this.offset, this.loyalityPoints});

  LoyaltyPointModel.fromJson(Map<String, dynamic> json) {
    if (json['pagination'] != null) {
      total = json['pagination']['total'];
      limit = json['pagination']['per_page']?.toString();
      offset = json['pagination']['current_page']?.toString();
    } else {
      total = json['total'];
      limit = json['limit'];
      offset = json['offset'];
    }
    var pointList = json['loyalityPoints'] ?? json['data'];
    if (pointList != null) {
      loyalityPoints = <LoyalityPoints>[];
      pointList.forEach((v) {
        loyalityPoints!.add(LoyalityPoints.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['limit'] = limit;
    data['offset'] = offset;
    if (loyalityPoints != null) {
      data['loyalityPoints'] = loyalityPoints!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}