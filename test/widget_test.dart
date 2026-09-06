import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';

void main() {
  testWidgets('primary courier action remains usable with long Georgian text on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButtonWidget(
                buttonText: 'შეკვეთის მიღება და მიწოდების უსაფრთხოდ გაგრძელება',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TextButton), findsOneWidget);
    expect(find.text('შეკვეთის მიღება და მიწოდების უსაფრთხოდ გაგრძელება'), findsOneWidget);

    final buttonRect = tester.getRect(find.byType(TextButton));
    expect(buttonRect.width, lessThanOrEqualTo(288));
    expect(buttonRect.height, greaterThanOrEqualTo(50));

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
