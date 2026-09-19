import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart_delivery/common/widgets/navigation_safe_area.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final bottom in [0.0, 21.0, 34.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          '$platform bottom=$bottom dark=$dark has exactly one safe inset',
          (tester) async {
            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final color = dark
                ? const Color(0xff18242c)
                : const Color(0xffeef8f1);
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(
                  platform: platform,
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: EdgeInsets.only(bottom: bottom),
                    viewPadding: EdgeInsets.only(bottom: bottom),
                  ),
                  child: AppSafeArea(child: child!),
                ),
                home: Scaffold(
                  key: const Key('screen'),
                  body: const SizedBox.expand(),
                  bottomNavigationBar: BottomNavigationSurface(
                    key: const Key('bar'),
                    decoration: BoxDecoration(color: color),
                    child: Builder(
                      builder: (context) {
                        expect(MediaQuery.paddingOf(context).bottom, 0);
                        return SizedBox.expand(
                          key: const Key('buttons'),
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('მენიუ'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            final bar = tester.getRect(find.byKey(const Key('bar')));
            final buttons = tester.getRect(find.byKey(const Key('buttons')));
            final screen = tester.getRect(find.byKey(const Key('screen')));
            expect(buttons.height, platform == TargetPlatform.iOS ? 60 : 65);
            expect(buttons.bottom, 844 - bottom);
            if (platform == TargetPlatform.iOS) {
              expect(
                screen.bottom,
                844,
                reason: 'The navigator must reach the iPhone bottom edge.',
              );
              expect(
                bar.bottom,
                844,
                reason:
                    'The navigation surface paints the home-indicator area.',
              );
              expect(bar.height, 60 + bottom);
            } else {
              expect(screen.bottom, 844 - bottom);
              expect(
                bar.height,
                65,
                reason: 'Do not add the already-consumed Android inset twice.',
              );
            }
            final surface = tester.widget<Container>(
              find
                  .descendant(
                    of: find.byKey(const Key('bar')),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            expect((surface.decoration! as BoxDecoration).color, color);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'keyboard removes the home-indicator inset and large labels have room',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.only(bottom: 34),
              viewInsets: EdgeInsets.only(bottom: 300),
              textScaler: TextScaler.linear(2),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavigationSurface(
                key: const Key('bar'),
                decoration: const BoxDecoration(color: Colors.green),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 25),
                    SizedBox(height: 5),
                    Text('მენიუ', maxLines: 1, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('bar'))).height, 83);
      expect(tester.takeException(), isNull);
    },
  );
}
