class DisbursementMethodBody {
  int? totalSize;
  String? limit;
  String? offset;
  List<Methods>? methods;

  DisbursementMethodBody({
    this.totalSize,
    this.limit,
    this.offset,
    this.methods,
  });

  DisbursementMethodBody.fromJson(Map<String, dynamic> json) {
    if (json['pagination'] is Map) {
      totalSize = json['pagination']['total'];
      limit = json['pagination']['per_page']?.toString();
      offset = json['pagination']['current_page']?.toString();
    } else {
      totalSize = json['total_size'];
      limit = json['limit'];
      offset = json['offset'];
    }
    final dynamic methodList = json['data'] ?? json['methods'];
    if (methodList is List) {
      methods = <Methods>[];
      for (final dynamic v in methodList) {
        methods!.add(Methods.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (methods != null) {
      data['methods'] = methods!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Methods {
  int? id;
  int? storeId;
  int? deliveryManId;
  int? withdrawalMethodId;
  String? methodName;
  List<MethodField>? methodFields;
  bool? isDefault;
  String? createdAt;
  String? updatedAt;

  Methods({
    this.id,
    this.storeId,
    this.deliveryManId,
    this.withdrawalMethodId,
    this.methodName,
    this.methodFields,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  Methods.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    deliveryManId = json['delivery_man_id'];
    withdrawalMethodId = json['withdrawal_method_id'];
    methodName = json['method_name'];
    if (json['method_fields'] != null) {
      methodFields = <MethodField>[];
      json['method_fields'].forEach((v) {
        methodFields!.add(MethodField.fromJson(v));
      });
    }
    isDefault = json['is_default'] is bool
        ? json['is_default']
        : json['is_default'] == 1;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['delivery_man_id'] = deliveryManId;
    data['withdrawal_method_id'] = withdrawalMethodId;
    data['method_name'] = methodName;
    if (methodFields != null) {
      data['method_fields'] = methodFields!.map((v) => v.toJson()).toList();
    }
    data['is_default'] = isDefault;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class MethodField {
  String? userInput;
  String? userData;
  String? inputType;
  String? placeholder;
  int? isRequired;

  MethodField({
    this.userInput,
    this.userData,
    this.inputType,
    this.placeholder,
    this.isRequired,
  });

  MethodField.fromJson(Map<String, dynamic> json) {
    userInput = json['user_input'] ?? json['input_name'];
    userData = json['user_data'] ?? json['value'];
    inputType = json['input_type'];
    placeholder = json['placeholder'];
    isRequired = json['is_required'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_input'] = userInput;
    data['user_data'] = userData;
    data['input_type'] = inputType;
    data['placeholder'] = placeholder;
    data['is_required'] = isRequired;
    return data;
  }
}
