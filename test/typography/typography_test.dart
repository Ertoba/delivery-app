import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/theme/light_theme.dart';
import 'package:sixam_mart_delivery/theme/dark_theme.dart';
import 'package:sixam_mart_delivery/util/typography.dart';
import 'package:sixam_mart_delivery/features/auth/widgets/mili_auth_ui.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final primary = FontLoader('Noto Sans Georgian');
    for (final style in [
      'Thin',
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ]) {
      primary.addFont(
        rootBundle.load('assets/font/noto/NotoSansGeorgian-$style.ttf'),
      );
    }
    await primary.load();
    final cyrillic = FontLoader('MILI Cyrillic');
    for (final style in ['Regular', 'Bold', 'Italic', 'BoldItalic']) {
      cyrillic.addFont(
        rootBundle.load('assets/font/noto/MiliCyrillic-$style.ttf'),
      );
    }
    await cyrillic.load();
  });

  test(
    'Cyrillic falls back to the bundled subset without replacing Georgian or Latin',
    () {
      double width(String value, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: value, style: style.copyWith(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();
        final result = painter.width;
        painter.dispose();
        return result;
      }

      expect(
        width('Москва', MiliTypography.regular),
        closeTo(
          width('Москва', const TextStyle(fontFamily: 'MILI Cyrillic')),
          .01,
        ),
      );
      for (final value in ['თბილისი', 'Tbilisi']) {
        expect(
          width(value, MiliTypography.regular),
          closeTo(
            width(value, const TextStyle(fontFamily: 'Noto Sans Georgian')),
            .01,
          ),
        );
      }
    },
  );

  for (final isDark in [false, true]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'bundled text, form and app bar fit at scale $scale, dark=$isDark',
        (tester) async {
          Get.testMode = true;
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final input = TextEditingController();
          await tester.pumpWidget(
            GetMaterialApp(
              theme: isDark ? dark : light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                appBar: const CustomAppBarWidget(
                  title: 'შეკვეთები / Заказы',
                  isBackButtonExist: false,
                ),
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'რჩეული პროდუქტები',
                      style: MiliTypography.heading.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'თბილისი • Tbilisi • Москва\nფასი 24.50 ₾ / Price / Цена',
                      style: MiliTypography.regular,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'მნიშვნელოვანი / Important / Важно',
                      style: MiliTypography.bold,
                    ),
                    const Text(
                      'ციტატა / Quotation / Цитата',
                      style: MiliTypography.italic,
                    ),
                    const SizedBox(height: 20),
                    MiliAuthField(
                      label: 'ტელეფონი / Телефон',
                      hint: 'შეიყვანე ნომერი',
                      controller: input,
                    ),
                    const SizedBox(height: 16),
                    MiliAuthSubmit(
                      loading: false,
                      label: 'გაგრძელება / Continue',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byType(TextFormField));
          await tester.enterText(find.byType(TextFormField), 'თბილისი Москва');
          await tester.pumpAndSettle();
          expect(input.text, 'თბილისი Москва');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          input.dispose();
          Get.reset();
        },
      );
    }
  }
}
