import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart_delivery/api/api_client.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/collect_cash_payment.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/repositories/my_account_repository.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

void main() {
  const id = 'dca36777-802c-4142-9745-ee45a04c19d0';
  final validInit = {
    'payment_id': id,
    'redirect_link': 'https://mili.ge/payment/keepz/pay?payment_id=$id',
    'status_url':
        'https://mili.ge${CollectCashPayment.statusPath}?payment_id=$id',
  };
  const capability = Response(
    statusCode: 200,
    body: {'verification_version': 1, 'supports_embedded_keepz': true},
  );
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.token: 'test-only-token',
    });
    preferences = await SharedPreferences.getInstance();
  });

  for (final response in [
    const Response(statusCode: 404),
    const Response(statusCode: 500),
    const Response(statusCode: 200, body: {}),
    const Response(statusCode: 200, body: 'not-json'),
    const Response(
      statusCode: 200,
      body: {'verification_version': 2, 'supports_embedded_keepz': true},
    ),
    const Response(
      statusCode: 200,
      body: {'verification_version': '1', 'supports_embedded_keepz': true},
    ),
    const Response(
      statusCode: 200,
      body: {'verification_version': 1, 'supports_embedded_keepz': false},
    ),
    const Response(
      statusCode: 200,
      body: {'verification_version': 1, 'supports_embedded_keepz': 'true'},
    ),
  ]) {
    test(
      'unsupported capability ${response.statusCode}/${response.body} creates zero transfers',
      () async {
        final api = _Api(
          preferences,
          () async => response,
          Response(statusCode: 200, body: validInit),
        );
        final repository = MyAccountRepository(
          apiClient: api,
          sharedPreferences: preferences,
        );
        final result = await repository.makeCollectCashPayment(10, 'keepz');
        expect(result.isSuccess, isFalse);
        expect(api.creates, 0);
        expect(api.reads, hasLength(1));
        expect(
          Uri.parse(api.reads.single).queryParameters.containsKey('payment_id'),
          isFalse,
        );
      },
    );
  }

  test('supported capability creates once and does not navigate', () async {
    final api = _Api(
      preferences,
      () async => capability,
      Response(statusCode: 200, body: validInit),
    );
    final repository = MyAccountRepository(
      apiClient: api,
      sharedPreferences: preferences,
    );
    final result = await repository.makeCollectCashPayment(10, 'keepz');
    expect(result.payment?.paymentId, id);
    expect(api.creates, 1);
    expect(api.reads, hasLength(1));
  });

  test(
    'unsupported gateway is rejected before any probe or payment creation',
    () async {
      final api = _Api(
        preferences,
        () async => capability,
        Response(statusCode: 200, body: validInit),
      );
      final repository = MyAccountRepository(
        apiClient: api,
        sharedPreferences: preferences,
      );
      final result = await repository.makeCollectCashPayment(10, 'stripe');
      expect(result.isSuccess, isFalse);
      expect(api.creates, 0);
      expect(api.reads, isEmpty);
    },
  );

  test('concurrent start has one probe and one create', () async {
    final probe = Completer<Response>();
    final api = _Api(
      preferences,
      () => probe.future,
      Response(statusCode: 200, body: validInit),
    );
    final repository = MyAccountRepository(
      apiClient: api,
      sharedPreferences: preferences,
    );
    final first = repository.makeCollectCashPayment(10, 'keepz');
    final duplicate = await repository.makeCollectCashPayment(10, 'keepz');
    expect(duplicate.isSuccess, isFalse);
    probe.complete(capability);
    expect((await first).isSuccess, isTrue);
    expect(api.creates, 1);
    expect(api.reads, hasLength(1));
  });

  test(
    'status retry is read-only and rejects mismatched identity/unsettled payment',
    () async {
      var statusPayload = <String, dynamic>{
        'payment_id': 'foreign',
        'status': 'success',
        'is_paid': true,
        'is_settled': true,
      };
      final api = _Api(
        preferences,
        () async => Response(statusCode: 200, body: statusPayload),
        Response(statusCode: 200, body: validInit),
      );
      final repository = MyAccountRepository(
        apiClient: api,
        sharedPreferences: preferences,
      );
      final payment = CollectCashPayment.fromJson(
        validInit,
        Uri.parse(AppConstants.baseUrl),
      );
      expect(
        (await repository.getCollectCashPaymentStatus(payment)).state,
        CollectCashPaymentState.pending,
      );
      statusPayload = {...statusPayload, 'payment_id': id, 'is_settled': false};
      expect(
        (await repository.getCollectCashPaymentStatus(payment)).state,
        CollectCashPaymentState.pending,
      );
      statusPayload['is_settled'] = true;
      expect(
        (await repository.getCollectCashPaymentStatus(payment)).state,
        CollectCashPaymentState.success,
      );
      expect(api.creates, 0);
      expect(api.reads, hasLength(3));
      for (final url in api.reads) {
        expect(Uri.parse(url).path, CollectCashPayment.statusPath);
        expect(Uri.parse(url).queryParameters['payment_id'], id);
      }
    },
  );
}

class _Api extends ApiClient {
  final Future<Response> Function() read;
  final Response created;
  final List<String> reads = [];
  int creates = 0;
  _Api(SharedPreferences preferences, this.read, this.created)
    : super(appBaseUrl: AppConstants.baseUrl, sharedPreferences: preferences);

  @override
  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool handleError = true,
  }) {
    reads.add(uri);
    return read();
  }

  @override
  Future<Response> postData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    expect(uri, AppConstants.makeCollectedCashPaymentUri);
    creates++;
    return created;
  }
}
