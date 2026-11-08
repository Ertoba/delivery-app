import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/collect_cash_payment.dart';
import 'package:sixam_mart_delivery/features/my_account/widgets/collect_cash_payment_sheet.dart';

void main() {
  final base = Uri.parse('https://mili.ge');
  const id = 'f46dcb4e-673e-45a6-bab7-11479c978632';
  final sessionJson = <String, dynamic>{
    'redirect_link': 'https://mili.ge/payment/keepz/pay?payment_id=$id',
    'payment_id': id,
    'status_url':
        'https://mili.ge${CollectCashPayment.statusPath}?payment_id=$id',
  };
  final payment = CollectCashPayment.fromJson(sessionJson, base);
  final successUri = Uri.parse('https://mili.ge/success?flag=success');

  group('cash-payment contract and navigation policy', () {
    test('session requires the exact owned authenticated-status endpoint', () {
      expect(payment.paymentId, id);
      for (final bad in [
        {
          ...sessionJson,
          'status_url': 'https://evil.test/status?payment_id=$id',
        },
        {...sessionJson, 'status_url': 'https://mili.ge/other?payment_id=$id'},
        {
          ...sessionJson,
          'status_url': '${sessionJson['status_url']}&token=secret',
        },
        {
          ...sessionJson,
          'status_url': '${sessionJson['status_url']}&payment_id=other',
        },
        {...sessionJson, 'redirect_link': 'https://mili.ge.evil.test/pay'},
        {...sessionJson, 'redirect_link': 'https://user@mili.ge/pay'},
        {...sessionJson, 'redirect_link': 'http://mili.ge/pay'},
        {
          ...sessionJson,
          'redirect_link': 'https://mili.ge/pay?payment_id=other',
        },
      ]) {
        expect(
          () => CollectCashPayment.fromJson(bad, base),
          throwsFormatException,
        );
      }
    });

    test('redirect is a hint only from exact origin, path and single flag', () {
      final policy = CollectCashNavigationPolicy(base);
      expect(policy.callback(successUri), CollectCashCallback.success);
      for (final url in [
        'https://evil.test/?next=https://mili.ge/success?flag=success',
        'https://mili.ge.evil.test/success?flag=success',
        'https://evil@mili.ge/success?flag=success',
        'https://mili.ge:444/success?flag=success',
        'http://mili.ge/success?flag=success',
        'https://mili.ge/success-extra?flag=success',
        'https://mili.ge/success?flag=success&flag=fail',
        'https://mili.ge/success?flag=success#spoof',
      ]) {
        expect(policy.callback(Uri.parse(url)), isNull);
      }
      expect(
        policy.allowsInline(Uri.parse('https://acs.bank.test/3ds')),
        isTrue,
      );
      expect(
        policy.allowsInline(
          Uri.parse('https://evil.test/success?flag=success'),
        ),
        isFalse,
      );
      for (final url in [
        'intent://pay',
        'javascript:alert(1)',
        'file:///secret',
        'http://bank.test',
        'https://user:secret@bank.test',
      ]) {
        expect(policy.allowsInline(Uri.parse(url)), isFalse);
      }
    });

    test(
      'success needs matching id, paid and settled; URL cannot supply them',
      () {
        Map<String, dynamic> payload({
          bool paid = true,
          bool settled = true,
          String status = 'success',
        }) => {
          'payment_id': id,
          'status': status,
          'is_paid': paid,
          'is_settled': settled,
        };
        expect(
          CollectCashPaymentStatus.fromJson(payload(), id).state,
          CollectCashPaymentState.success,
        );
        expect(
          CollectCashPaymentStatus.fromJson(payload(settled: false), id).state,
          CollectCashPaymentState.pending,
        );
        expect(
          CollectCashPaymentStatus.fromJson(payload(paid: false), id).state,
          CollectCashPaymentState.pending,
        );
        expect(
          CollectCashPaymentStatus.fromJson(
            payload(status: 'failed', paid: false),
            id,
          ).state,
          CollectCashPaymentState.failed,
        );
        expect(
          () => CollectCashPaymentStatus.fromJson(payload(), 'another'),
          throwsFormatException,
        );
      },
    );
  });

  Future<void> openSheet(
    WidgetTester tester, {
    required Future<CollectCashPaymentStatus> Function(CollectCashPayment)
    verify,
    required Future<void> Function() refresh,
    required void Function(Future<void> Function(Uri)) capture,
    bool statusOnly = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('account-screen'),
                TextButton(
                  child: const Text('open-payment'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CollectCashPaymentSheet(
                        payment: payment,
                        verify: verify,
                        refreshAccount: refresh,
                        pollDelay: Duration.zero,
                        statusOnly: statusOnly,
                        contentBuilder: (context, callback) {
                          capture(callback);
                          return const Center(child: Text('inline-checkout'));
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-payment'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('cancel closes only the owned modal and stays on account', (
    tester,
  ) async {
    var verifies = 0;
    var refreshes = 0;
    await openSheet(
      tester,
      verify: (_) async {
        verifies++;
        return CollectCashPaymentStatus(id, CollectCashPaymentState.pending);
      },
      refresh: () async {
        refreshes++;
      },
      capture: (_) {},
    );
    expect(find.text('inline-checkout'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cash-payment-close')));
    await tester.pumpAndSettle();
    expect(find.text('account-screen'), findsOneWidget);
    expect(find.text('inline-checkout'), findsNothing);
    expect(verifies, 0);
    expect(refreshes, 0);
  });

  testWidgets('duplicate callbacks verify and refresh once; close pops once', (
    tester,
  ) async {
    late Future<void> Function(Uri) navigate;
    var verifies = 0;
    var refreshes = 0;
    final response = Completer<CollectCashPaymentStatus>();
    await openSheet(
      tester,
      verify: (_) {
        verifies++;
        return response.future;
      },
      refresh: () async {
        refreshes++;
      },
      capture: (value) => navigate = value,
    );
    final first = navigate(successUri);
    await navigate(successUri);
    expect(verifies, 1);
    response.complete(
      CollectCashPaymentStatus(id, CollectCashPaymentState.success),
    );
    await first;
    await tester.pump();
    expect(refreshes, 1);
    expect(find.text('your_payment_is_successfully_completed'), findsOneWidget);
    await navigate(successUri);
    expect(verifies, 1);
    await tester.tap(find.text('okay'));
    await tester.pumpAndSettle();
    expect(find.text('account-screen'), findsOneWidget);
    expect(find.byKey(const Key('cash-payment-result')), findsNothing);
  });

  testWidgets('unconfirmed redirect stays pending; retry only reads status', (
    tester,
  ) async {
    late Future<void> Function(Uri) navigate;
    var verifies = 0;
    var refreshes = 0;
    await openSheet(
      tester,
      verify: (_) async {
        verifies++;
        return CollectCashPaymentStatus(id, CollectCashPaymentState.pending);
      },
      refresh: () async {
        refreshes++;
      },
      capture: (value) => navigate = value,
    );
    await tester.runAsync(() => navigate(successUri));
    await tester.pump();
    expect(verifies, 4);
    expect(refreshes, 0);
    expect(find.byKey(const Key('cash-payment-pending')), findsOneWidget);
    expect(find.text('your_payment_is_successfully_completed'), findsNothing);
    await tester.tap(find.byKey(const Key('cash-payment-verify')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.pump();
    expect(verifies, 8);
    expect(refreshes, 0);
  });

  testWidgets('confirmed failure stays in modal and never refreshes balance', (
    tester,
  ) async {
    late Future<void> Function(Uri) navigate;
    var refreshes = 0;
    await openSheet(
      tester,
      verify: (_) async =>
          CollectCashPaymentStatus(id, CollectCashPaymentState.failed),
      refresh: () async {
        refreshes++;
      },
      capture: (value) => navigate = value,
    );
    await navigate(Uri.parse('https://mili.ge/success?flag=fail'));
    await tester.pump();
    expect(find.text('your_payment_is_not_done'), findsOneWidget);
    expect(find.text('account-screen'), findsOneWidget);
    expect(refreshes, 0);
  });

  testWidgets('spoof callback never verifies or closes the modal', (
    tester,
  ) async {
    late Future<void> Function(Uri) navigate;
    var verifies = 0;
    await openSheet(
      tester,
      verify: (_) async {
        verifies++;
        return CollectCashPaymentStatus(id, CollectCashPaymentState.success);
      },
      refresh: () async {},
      capture: (value) => navigate = value,
    );
    await navigate(Uri.parse('https://evil.test/success?flag=success'));
    await tester.pump();
    expect(verifies, 0);
    expect(find.text('inline-checkout'), findsOneWidget);
  });

  testWidgets(
    'pending session reopens as read-only status without loading checkout',
    (tester) async {
      var verifies = 0;
      var checkoutBuilds = 0;
      await openSheet(
        tester,
        verify: (_) async {
          verifies++;
          return CollectCashPaymentStatus(id, CollectCashPaymentState.pending);
        },
        refresh: () async {},
        capture: (_) {
          checkoutBuilds++;
        },
        statusOnly: true,
      );
      expect(checkoutBuilds, 0);
      expect(find.text('inline-checkout'), findsNothing);
      expect(find.byKey(const Key('cash-payment-pending')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cash-payment-verify')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(verifies, 4);
      expect(checkoutBuilds, 0);
    },
  );

  testWidgets('late verification after cancel cannot refresh or pop account', (
    tester,
  ) async {
    late Future<void> Function(Uri) navigate;
    final response = Completer<CollectCashPaymentStatus>();
    var refreshes = 0;
    await openSheet(
      tester,
      verify: (_) => response.future,
      refresh: () async {
        refreshes++;
      },
      capture: (value) => navigate = value,
    );
    final pending = navigate(successUri);
    await tester.pump();
    await tester.tap(find.byKey(const Key('cash-payment-close')));
    await tester.pumpAndSettle();
    response.complete(
      CollectCashPaymentStatus(id, CollectCashPaymentState.success),
    );
    await pending;
    await tester.pump();
    expect(refreshes, 0);
    expect(find.text('account-screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
