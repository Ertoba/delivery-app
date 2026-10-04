import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/models/pagination_model.dart';

extension ApiResponseExtension on Response {

  bool get hasEnvelope => body is Map && (body as Map).containsKey('identical_code');
  dynamic get content => hasEnvelope ? body['content'] : body;
  String? get apiMessage => body is Map ? body['message'] : null;

  List<dynamic> get contentList {
    dynamic data = content;
    if(data is List) {return data;}
    if(data is Map && data['data'] is List) {return data['data'];}
    return [];
  }

  PaginationModel? get pagination {
    dynamic data = content;
    if(data is Map && data['pagination'] != null) {
      return PaginationModel.fromJson(data['pagination']);
    }
    return null;
  }
}
