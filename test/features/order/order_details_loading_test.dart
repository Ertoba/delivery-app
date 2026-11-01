import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/screens/order_details_screen.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('mount starts request after build; failure leaves retry, not infinite spinner', (tester) async {
    final service = _OrderService();
    final controller = Get.put(OrderController(orderServiceInterface: service));
    await tester.pumpWidget(GetMaterialApp(
      home: GetBuilder<OrderController>(builder: (_) => const OrderDetailsScreen(
        orderId: 12, isRunningOrder: true, orderIndex: 0,
      )),
    ));
    expect(tester.takeException(), isNull);
    expect(service.calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.response.complete(const Response(statusCode: 503));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('try_again'), findsOneWidget);
    await tester.tap(find.text('try_again'));
    await tester.pump();
    expect(service.calls, 2, reason: 'The refresh ID guard must have been released.');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  test('loading listener exception releases the in-flight guard', () async {
    final service = _OrderService();
    final controller = OrderController(orderServiceInterface: service);
    final remove = controller.addListener(() => throw StateError('listener failed'));
    expect(await controller.getOrderWithId(12, popOnError: false), isFalse);
    remove();
    final retry = controller.getOrderWithId(12, popOnError: false);
    service.response.complete(const Response(statusCode: 503));
    expect(await retry, isFalse);
    expect(service.calls, 1);
  });
}

class _OrderService implements OrderServiceInterface {
  final response = Completer<Response>();
  int calls = 0;
  @override
  Future<Response> getOrderWithId(int? orderId) {
    calls++;
    return response.future;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
