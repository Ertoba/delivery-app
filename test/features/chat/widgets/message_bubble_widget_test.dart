import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart_delivery/features/chat/widgets/message_bubble_widget.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

void main() {
  test('admin chat identifies courier and operator messages without profile userinfo', () {
    expect(
      isIncomingChatMessage(
        messageSenderId: 19,
        receiverId: 0,
        currentSenderId: 19,
        userType: AppConstants.admin,
      ),
      isFalse,
    );
    expect(
      isIncomingChatMessage(
        messageSenderId: 24,
        receiverId: 0,
        currentSenderId: 19,
        userType: AppConstants.admin,
      ),
      isTrue,
    );
  });
}
