import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/my_account/controllers/my_account_controller.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/collect_cash_payment.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/services/my_account_service_interface.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_delivery/features/profile/domain/services/profile_service_interface.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  final payment = CollectCashPayment(
    redirectUri: Uri.parse(
      'https://mili.ge/payment/keepz/pay?payment_id=transfer',
    ),
    paymentId: 'transfer',
    statusUri: Uri.parse(
      'https://mili.ge${CollectCashPayment.statusPath}?payment_id=transfer',
    ),
  );

  test(
    'double start has one create; pending session is reused until terminal verification',
    () async {
      final profile = Get.put<ProfileController>(_ProfileController());
      final service = _Service();
      final controller = MyAccountController(
        myAccountServiceInterface: service,
      );
      final first = controller.makeCollectCashPayment(12, 'keepz');
      expect(
        (await controller.makeCollectCashPayment(12, 'keepz')).isSuccess,
        isFalse,
      );
      expect(service.creates, 1);
      service.result.complete(CollectCashPaymentResult.success(payment));
      expect((await first).payment, payment);
      expect(controller.activeCashPayment, payment);
      expect(
        (await controller.makeCollectCashPayment(12, 'keepz')).payment,
        payment,
      );
      expect(service.creates, 1);
      controller.finishCashPayment(payment, CollectCashPaymentState.pending);
      expect(controller.activeCashPayment, payment);
      controller.finishCashPayment(payment, CollectCashPaymentState.success);
      expect(controller.activeCashPayment, isNull);
      expect(profile.profileModel?.id, 7);
    },
  );

  test('pending transfer never crosses account identities', () async {
    final profile = _ProfileController();
    Get.put<ProfileController>(profile);
    final service = _Service();
    final controller = MyAccountController(myAccountServiceInterface: service);
    final creating = controller.makeCollectCashPayment(12, 'keepz');
    profile.model.id =
        8; // Account switches while the old request is in flight.
    service.result.complete(CollectCashPaymentResult.success(payment));
    await creating;
    expect(controller.activeCashPayment, isNull);
  });
}

class _Service implements MyAccountServiceInterface {
  int creates = 0;
  final result = Completer<CollectCashPaymentResult>();
  @override
  Future<CollectCashPaymentResult> makeCollectCashPayment(
    double amount,
    String paymentGatewayName,
  ) {
    creates++;
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileController extends ProfileController {
  final model = ProfileModel(id: 7);
  _ProfileController() : super(profileServiceInterface: _ProfileService());
  @override
  ProfileModel get profileModel => model;
}

class _ProfileService implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
