import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/message_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/parcel_cancellation_reasons_model.dart';
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_method_model.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/delivery_income_statement_model.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/loyalty_point_model.dart';
import 'package:sixam_mart_delivery/features/refer_and_earn/domain/models/refer_and_earn_model.dart';

Map<String, dynamic> page() => <String, dynamic>{
  'total': 12,
  'per_page': 10,
  'current_page': 2,
  'last_page': 2,
};

void main() {
  test('delivery order and disbursement responses accept V4.2 pagination', () {
    final PaginatedOrderModel orders = PaginatedOrderModel.fromJson(
      <String, dynamic>{'data': <dynamic>[], 'pagination': page()},
    );
    final DisbursementMethodBody methods = DisbursementMethodBody.fromJson(
      <String, dynamic>{'data': <dynamic>[], 'pagination': page()},
    );

    expect(orders.orders, isEmpty);
    expect(orders.totalSize, 12);
    expect(orders.lastPage, 2);
    expect(orders.offset, '2');
    expect(methods.methods, isEmpty);
    expect(methods.totalSize, 12);
  });

  test('delivery secondary list models accept data and pagination', () {
    expect(
      ConversationsModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).conversations,
      isEmpty,
    );
    expect(
      MessageModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).messages,
      isEmpty,
    );
    expect(
      OrderCancellationBody.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).reasons,
      isEmpty,
    );
    expect(
      ParcelCancellationReasonsModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).data,
      isEmpty,
    );
    expect(
      DeliveryIncomeStatementModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).transactions,
      isEmpty,
    );
    expect(
      LoyaltyPointModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).loyalityPoints,
      isEmpty,
    );
    expect(
      ReferEarningModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': page(),
      }).refrealEarnings,
      isEmpty,
    );
  });

  test('legacy delivery order pagination remains supported', () {
    final PaginatedOrderModel orders = PaginatedOrderModel.fromJson(
      <String, dynamic>{
        'orders': <dynamic>[],
        'total_size': 0,
        'limit': 10,
        'offset': 1,
      },
    );
    expect(orders.orders, isEmpty);
    expect(orders.totalSize, 0);
    expect(orders.offset, '1');
  });
}
