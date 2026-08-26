import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/models/response_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/services/order_service_interface.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('accepting a map order with index -1 updates state safely', () async {
    final OrderController controller = OrderController(
      orderServiceInterface: _FakeOrderService(),
    );
    final OrderModel order = OrderModel(id: 100236, orderStatus: 'confirmed');

    final bool accepted = await controller.acceptOrder(order.id, -1, order);

    expect(accepted, isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.currentOrderList?.map((item) => item.id), <int?>[100236]);
  });
}

class _FakeOrderService implements OrderServiceInterface {
  @override
  Future<ResponseModel> acceptOrder(int? orderID) async {
    return ResponseModel(true, 'accepted');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
