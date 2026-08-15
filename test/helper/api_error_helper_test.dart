import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/helper/api_error_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  test('extracts the first structured API error code safely', () {
    expect(
      ApiErrorHelper.firstErrorCode({
        'errors': [
          {'code': 'auth-001', 'message': 'Incorrect credential'},
        ],
      }),
      'auth-001',
    );
    expect(ApiErrorHelper.firstErrorCode(null), isNull);
    expect(ApiErrorHelper.firstErrorCode({'errors': []}), isNull);
  });

  testWidgets('maps Georgian auth-001 response to wrong credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(locale: Locale('ka'), home: SizedBox()),
    );

    expect(
      ApiErrorHelper.userMessage(
        'არასწორი სერთიფიკატი, გთხოვთ, სცადოთ ხელახლა',
        statusCode: 401,
        errorCode: 'auth-001',
      ),
      'ტელეფონის ნომერი ან პაროლი არასწორია.',
    );
  });

  testWidgets('maps auth-001 response to English wrong credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(locale: Locale('en'), home: SizedBox()),
    );

    expect(
      ApiErrorHelper.userMessage(
        'Incorrect credential, please try again',
        statusCode: 401,
        errorCode: 'auth-001',
      ),
      'The phone number or password is incorrect.',
    );
  });

  testWidgets('maps auth-001 response to Russian wrong credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(locale: Locale('ru'), home: SizedBox()),
    );

    expect(
      ApiErrorHelper.userMessage(
        'Incorrect_credential,_please_try_again',
        statusCode: 401,
        errorCode: 'auth-001',
      ),
      'Неверный номер телефона или пароль.',
    );
  });

  testWidgets('keeps suspended and not-approved states distinct', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(locale: Locale('en'), home: SizedBox()),
    );

    expect(
      ApiErrorHelper.userMessage(
        'Your account has been suspended',
        statusCode: 401,
        errorCode: 'auth-003',
      ),
      'Your account has been suspended.',
    );
    expect(
      ApiErrorHelper.userMessage(
        'messages.Your_account_is_not_approved_yet.',
        statusCode: 401,
        errorCode: 'auth-003',
      ),
      'Your account has not been approved yet.',
    );
  });

  testWidgets('does not classify TLS failures as credential failures', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(locale: Locale('en'), home: SizedBox()),
    );

    expect(
      ApiErrorHelper.userMessage(
        'HandshakeException: CERTIFICATE_VERIFY_FAILED',
        statusCode: 1,
      ),
      'Unable to connect to the server. Check your internet connection.',
    );
  });
}
