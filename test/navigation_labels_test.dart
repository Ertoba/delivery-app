import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/navigation_safe_area.dart';
import 'package:sixam_mart_delivery/features/dashboard/widgets/bottom_nav_item_widget.dart';
import 'package:sixam_mart_delivery/util/images.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  for (final scale in [1.0, 2.0]) {
    testWidgets('real iPhone navigation labels fit at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 34),
              textScaler: TextScaler.linear(scale),
            ),
            child: AppSafeArea(child: child!),
          ),
          home: Scaffold(
            bottomNavigationBar: BottomNavigationSurface(
              decoration: const BoxDecoration(color: Colors.white),
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  for (final title in [
                    'მთავარი',
                    'შეკვეთები',
                    'საფულე',
                    'მენიუ',
                  ])
                    BottomNavItemWidget(
                      iconData: Images.home,
                      label: title,
                      isSelected: false,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(BottomNavigationSurface)).bottom, 844);
    });
  }
}
