import 'package:get/get.dart';
import 'package:sixam_mart_delivery/api/api_response_extension.dart';
import 'package:sixam_mart_delivery/features/html/domain/services/html_service_interface.dart';

class HtmlController extends GetxController implements GetxService {
  final HtmlServiceInterface htmlServiceInterface;
  HtmlController({required this.htmlServiceInterface});

  String? _htmlText;
  String? get htmlText => _htmlText;

  Future<void> getHtmlText(bool isPrivacyPolicy) async {
    _htmlText = null;
    Response response = await htmlServiceInterface.getHtmlText(isPrivacyPolicy);
    if (response.statusCode == 200) {
      if(response.content is String && response.content.isNotEmpty) {
        _htmlText = response.content.replaceAll('href=', 'target="_blank" href=');
      }else {
        _htmlText = '';
      }
    }
    update();
  }

}