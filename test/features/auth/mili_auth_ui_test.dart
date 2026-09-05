import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/auth/widgets/mili_auth_ui.dart';
import 'package:sixam_mart_delivery/util/images.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations({
      for (final locale in ['en', 'ka', 'ru'])
        locale: Map<String, String>.from(
          jsonDecode(File('assets/language/$locale.json').readAsStringSync())
              as Map,
        ),
    });
  });
  tearDown(() => Get.reset());

  for (final locale in ['en', 'ka', 'ru']) {
    testWidgets(
      '$locale sign-in stays reachable with keyboard and large text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final email = TextEditingController();
        final password = TextEditingController();
        final emailFocus = FocusNode();
        final passwordFocus = FocusNode();
        var submitted = 0;
        await tester.pumpWidget(
          GetMaterialApp(
            locale: Locale(locale),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: SafeArea(
                child: MiliAuthLayout(
                  logoAsset: Images.brandMark,
                  children: [
                    MiliAuthIntro(
                      title: 'auth_ui_title'.tr,
                      subtitle: 'auth_ui_manual_subtitle'.tr,
                    ),
                    MiliAuthField(
                      label: 'email'.tr,
                      hint: 'example@email.com',
                      controller: email,
                      focusNode: emailFocus,
                      nextFocus: passwordFocus,
                    ),
                    const SizedBox(height: 18),
                    MiliAuthField(
                      label: 'password'.tr,
                      hint: 'enter_password'.tr,
                      controller: password,
                      focusNode: passwordFocus,
                      isPassword: true,
                      inputAction: TextInputAction.done,
                      onSubmit: (_) => submitted++,
                    ),
                    MiliAuthOptions(
                      remember: false,
                      onRemember: () {},
                      onForgot: () {},
                    ),
                    MiliAuthSubmit(
                      loading: false,
                      label: 'sign_in'.tr,
                      onPressed: () => submitted++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          emailFocus.hasFocus,
          isFalse,
          reason: 'The form must not open the keyboard automatically.',
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'person@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(passwordFocus.hasFocus, isTrue);
        await tester.enterText(
          find.byType(TextFormField).last,
          'test-password',
        );
        await tester.ensureVisible(find.byTooltip('auth_ui_show_password'.tr));
        await tester.tap(find.byTooltip('auth_ui_show_password'.tr));
        await tester.pumpAndSettle();
        final passwordInput = find.descendant(
          of: find.byType(MiliAuthField).last,
          matching: find.byType(TextField),
        );
        expect(tester.widget<TextField>(passwordInput).obscureText, isFalse);
        expect(password.text, 'test-password');
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        expect(submitted, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        email.dispose();
        password.dispose();
        emailFocus.dispose();
        passwordFocus.dispose();
      },
    );
  }
  testWidgets('loading prevents duplicate button submissions', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiliAuthSubmit(
            loading: true,
            label: 'Sign in',
            onPressed: () => count++,
          ),
        ),
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(count, 0);
  });
}
