import 'dart:async';

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

  test(
    'order refresh coalesces duplicates and ignores stale responses',
    () async {
      final _FakeOrderService service = _FakeOrderService();
      final OrderController controller = OrderController(
        orderServiceInterface: service,
      );

      final Future<bool> firstOrder = controller.getOrderWithId(
        1,
        showLoading: false,
        popOnError: false,
      );
      final Future<bool> duplicateOrder = controller.getOrderWithId(
        1,
        showLoading: false,
        popOnError: false,
      );
      final Future<bool> secondOrder = controller.getOrderWithId(
        2,
        showLoading: false,
        popOnError: false,
      );

      expect(await duplicateOrder, isFalse);
      expect(service.orderCalls[1], 1);
      service.orderResponses[1]!.complete(
        const Response(
          statusCode: 200,
          body: <String, dynamic>{'id': 1, 'order_status': 'processing'},
        ),
      );
      expect(await firstOrder, isTrue);
      expect(controller.orderModel, isNull);

      service.orderResponses[2]!.complete(
        const Response(
          statusCode: 200,
          body: <String, dynamic>{'id': 2, 'order_status': 'handover'},
        ),
      );
      expect(await secondOrder, isTrue);
      expect(controller.orderModel?.id, 2);
      expect(controller.orderModel?.orderStatus, 'handover');
    },
  );

  test('same-order reload keeps items; switching order discards old items', () async {
    final service = _FakeOrderService();
    final controller = OrderController(orderServiceInterface: service);
    final first = controller.getOrderWithId(1, popOnError: false);
    service.orderResponses[1]!.complete(const Response(
      statusCode: 200, body: {'id': 1, 'order_status': 'handover'},
    ));
    expect(await first, isTrue);
    await controller.getOrderDetails(1, true);
    final items = controller.orderDetailsModel;
    expect(items, isNotNull);

    // Parcel-return and cancellation callers refresh the same order without
    // fetching item details again. They must not lose the already loaded list.
    expect(await controller.getOrderWithId(1, popOnError: false), isTrue);
    expect(controller.orderDetailsModel, same(items));

    final second = controller.getOrderWithId(2, popOnError: false);
    expect(controller.orderDetailsModel, isNull);
    service.orderResponses[2]!.complete(const Response(
      statusCode: 200, body: {'id': 2, 'order_status': 'processing'},
    ));
    expect(await second, isTrue);
  });
}

class _FakeOrderService implements OrderServiceInterface {
  final Map<int, Completer<Response>> orderResponses =
      <int, Completer<Response>>{};
  final Map<int, int> orderCalls = <int, int>{};

  @override
  Future<ResponseModel> acceptOrder(int? orderID) async {
    return ResponseModel(true, 'accepted');
  }

  @override
  Future<Response> getOrderWithId(int? orderId) {
    orderCalls.update(orderId!, (count) => count + 1, ifAbsent: () => 1);
    return (orderResponses[orderId] ??= Completer<Response>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
