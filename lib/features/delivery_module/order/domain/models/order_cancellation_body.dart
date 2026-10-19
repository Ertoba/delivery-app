class OrderCancellationBody {
  int? totalSize;
  String? limit;
  String? offset;
  List<CancellationData>? reasons;

  OrderCancellationBody({
    this.totalSize,
    this.limit,
    this.offset,
    this.reasons,
  });

  OrderCancellationBody.fromJson(Map<String, dynamic> json) {
    if (json['pagination'] is Map) {
      totalSize = json['pagination']['total'];
      limit = json['pagination']['per_page']?.toString();
      offset = json['pagination']['current_page']?.toString();
    } else {
      totalSize = json['total_size'];
      limit = json['limit'];
      offset = json['offset'];
    }
    final dynamic reasonList = json['data'];
    if (reasonList is List) {
      reasons = <CancellationData>[];
      for (final dynamic v in reasonList) {
        reasons!.add(CancellationData.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (reasons != null) {
      data['reasons'] = reasons!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CancellationData {
  int? id;
  String? reason;
  String? userType;
  int? status;
  String? createdAt;
  String? updatedAt;

  CancellationData({
    this.id,
    this.reason,
    this.userType,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  CancellationData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reason = json['reason'];
    userType = json['user_type'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['reason'] = reason;
    data['user_type'] = userType;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
