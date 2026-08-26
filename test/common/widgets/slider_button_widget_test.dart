import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/slider_button_widget.dart';

void main() {
  testWidgets('slider shows progress while its async action is pending', (
    tester,
  ) async {
    final Completer<void> action = Completer<void>();
    int calls = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SliderButton(
            width: 320,
            height: 52,
            buttonSize: 46,
            isLtr: true,
            dismissThresholds: 0.5,
            dismissible: false,
            vibrationFlag: false,
            label: const Text('Swipe'),
            action: () {
              calls++;
              return action.future;
            },
          ),
        ),
      ),
    );

    final Finder slider = find.byType(Dismissible);
    final Size sliderSize = tester.getSize(slider);
    final Offset sliderStart = tester.getTopLeft(slider) +
        Offset(8, sliderSize.height / 2);
    await tester.dragFrom(
      sliderStart,
      Offset(sliderSize.width * 1.2, 0),
    );
    for (int frame = 0; frame < 12 && calls == 0; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    action.complete();
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Swipe'), findsOneWidget);
  });
}
