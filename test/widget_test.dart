import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('primary action at $width px and $scale text scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var submitted = 0;
        var busy = false;
        late StateSetter update;
        await tester.pumpWidget(
          GetMaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      update = setState;
                      return CustomButtonWidget(
                        buttonText:
                            'შეკვეთის გაფორმება და გადახდის უსაფრთხოდ გაგრძელება',
                        fontSize: 16,
                        isLoading: busy,
                        icon: Icons.lock_outline,
                        onPressed: () {
                          submitted++;
                          update(() => busy = true);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final action = find.byType(TextButton);
        final before = tester.getSize(action);
        expect(before.width, lessThanOrEqualTo(width - 32));
        expect(before.height, greaterThanOrEqualTo(48));
        await tester.tap(action);
        await tester.pump();
        expect(
          tester.getSize(action),
          before,
          reason: 'Loading must retain the action bounds.',
        );
        expect(tester.widget<TextButton>(action).onPressed, isNull);
        await tester.tap(action);
        expect(
          submitted,
          1,
          reason: 'A busy action must reject duplicate submissions.',
        );
        update(() => busy = false);
        await tester.pump();
        expect(tester.getSize(action), before);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
