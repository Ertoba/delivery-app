import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart_delivery/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/custom_print_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static Future<void> initialize(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    var androidInitialize = const AndroidInitializationSettings(
      'notification_icon',
    );
    var iOSInitialize = const DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    var initializationsSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    androidPlugin.requestNotificationsPermission();
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'portal_notifications',
        'პორტალი კურიერი შეტყობინებები',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
      ),
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationsSettings,
      onDidReceiveNotificationResponse: (load) async {
        try {
          if (load.payload!.isNotEmpty) {
            NotificationBodyModel payload = NotificationBodyModel.fromJson(
              jsonDecode(load.payload!),
            );

            final Map<NotificationType, Function> notificationActions = {
              NotificationType.order: () => Get.toNamed(
                RouteHelper.getOrderDetailsRoute(
                  payload.orderId,
                  fromNotification: true,
                ),
              ),
              NotificationType.order_request: () =>
                  Get.toNamed(RouteHelper.getMainRoute('order-request')),
              NotificationType.block: () =>
                  Get.offAllNamed(RouteHelper.getSignInRoute()),
              NotificationType.unblock: () =>
                  Get.offAllNamed(RouteHelper.getSignInRoute()),
              NotificationType.otp: () => null,
              NotificationType.unassign: () =>
                  Get.to(const DashboardScreen(pageIndex: 1)),
              NotificationType.message: () => Get.toNamed(
                RouteHelper.getChatRoute(
                  notificationBody: payload,
                  conversationId: payload.conversationId,
                  fromNotification: true,
                ),
              ),
              NotificationType.withdraw: () =>
                  Get.toNamed(RouteHelper.getMyAccountRoute()),
              NotificationType.general: () => Get.toNamed(
                RouteHelper.getNotificationRoute(fromNotification: true),
              ),
            };

            notificationActions[payload.notificationType]?.call();
          }
        } catch (_) {}
        return;
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("onMessage message type:${message.data['type']}");
        print("onMessage message:${message.data}");
      }

      if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.chatScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
          if (Get.find<ChatController>().messageModel!.conversation!.id
                  .toString() ==
              message.data['conversation_id'].toString()) {
            Get.find<ChatController>().getMessages(
              1,
              NotificationBodyModel(
                notificationType: NotificationType.message,
                customerId: message.data['sender_type'] == AppConstants.user
                    ? 0
                    : null,
                vendorId: message.data['sender_type'] == AppConstants.vendor
                    ? 0
                    : null,
              ),
              null,
              int.parse(message.data['conversation_id'].toString()),
            );
          } else {
            NotificationHelper.showNotification(
              message,
              flutterLocalNotificationsPlugin,
            );
          }
        }
      } else if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.conversationListScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
        }
        NotificationHelper.showNotification(
          message,
          flutterLocalNotificationsPlugin,
        );
      } else if (message.data['type'] == 'otp') {
        NotificationHelper.showNotification(
          message,
          flutterLocalNotificationsPlugin,
        );
      } else if (message.data['type'] == 'deliveryman_referral') {
        NotificationHelper.showNotification(
          message,
          flutterLocalNotificationsPlugin,
        );
      } else {
        String? type = message.data['type'];

        if (type != 'assign' &&
            type != 'new_order' &&
            type != 'order_request') {
          NotificationHelper.showNotification(
            message,
            flutterLocalNotificationsPlugin,
          );
          Get.find<OrderController>().getRunningOrders(1, status: 'all');
          Get.find<OrderController>().getOrderCount(
            Get.find<OrderController>().orderType,
          );
          Get.find<OrderController>().getLatestOrders();
          Get.find<NotificationController>().getNotificationList();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("onOpenApp message type:${message.data['type']}");
      }
      try {
        if (message.data.isNotEmpty) {
          NotificationBodyModel notificationBody = convertNotification(
            message.data,
          )!;

          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () => Get.toNamed(
              RouteHelper.getOrderDetailsRoute(
                int.parse(message.data['order_id']),
                fromNotification: true,
              ),
            ),
            NotificationType.order_request: () =>
                Get.toNamed(RouteHelper.getMainRoute('order-request')),
            NotificationType.block: () =>
                Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.unblock: () =>
                Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.otp: () => null,
            NotificationType.unassign: () =>
                Get.to(const DashboardScreen(pageIndex: 1)),
            NotificationType.message: () => Get.toNamed(
              RouteHelper.getChatRoute(
                notificationBody: notificationBody,
                conversationId: notificationBody.conversationId,
                fromNotification: true,
              ),
            ),
            NotificationType.withdraw: () =>
                Get.toNamed(RouteHelper.getMyAccountRoute()),
            NotificationType.general: () => Get.toNamed(
              RouteHelper.getNotificationRoute(fromNotification: true),
            ),
          };

          notificationActions[notificationBody.notificationType]?.call();
        }
      } catch (_) {}
    });
  }

  static Future<void> showNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    String? title;
    String? body;
    String? image;
    NotificationBodyModel? notificationBody = convertNotification(message.data);

    title = localizedTitle(message.data['title']);
    body = localizedBody(message.data['body']);
    image = (message.data['image'] != null && message.data['image'].isNotEmpty)
        ? message.data['image'].startsWith('http')
              ? message.data['image']
              : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}'
        : null;

    if (image != null && image.isNotEmpty) {
      try {
        await showBigPictureNotificationHiddenLargeIcon(
          title,
          body,
          notificationBody,
          image,
          fln,
        );
      } catch (e) {
        await showBigTextNotification(title, body, notificationBody, fln);
      }
    } else {
      await showBigTextNotification(title, body, notificationBody, fln);
    }
  }

  static String localizedTitle(String? title) {
    return _localizedNotificationText(title, isTitle: true);
  }

  static String localizedBody(String? body) {
    return _localizedNotificationText(body);
  }

  static Future<bool> shouldUseGeorgianNotificationText() async {
    if (Get.locale?.languageCode == 'ka') {
      return true;
    }

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final List<String?> languageCodes = [
        preferences.getString(AppConstants.languageCode),
        preferences.getString(AppConstants.cacheLanguageCode),
      ];

      return languageCodes.any((code) => code?.toLowerCase() == 'ka');
    } catch (_) {
      return false;
    }
  }

  static String _localizedNotificationText(
    String? text, {
    bool isTitle = false,
  }) {
    final String rawText = text?.trim() ?? '';
    if (rawText.isEmpty || Get.locale?.languageCode != 'ka') {
      return rawText;
    }
    final String normalizedText = rawText
        .replaceFirst(RegExp(r'^messages\.'), '')
        .trim();

    final Map<String, String> exactMatches = {
      'Order Notification': _translatedLabel(
        'notification_order_title',
        'შეკვეთის შეტყობინება',
      ),
      'Order is processing': _translatedLabel(
        'notification_is_processing',
        'შეკვეთა მუშავდება',
      ),
      'Loyalty Point Transaction': _translatedLabel(
        'notification_loyalty_point_transaction',
        'ქულების ტრანზაქცია',
      ),
    };

    if (exactMatches.containsKey(normalizedText)) {
      return exactMatches[normalizedText]!;
    }

    final List<_NotificationTextPattern> patterns = [
      _NotificationTextPattern(
        RegExp(r'^New order alert, confirm to proceed$', caseSensitive: false),
        (_) => _translatedLabel(
          'notification_new_order_alert_confirm_to_proceed',
          'ახალი შეკვეთის შეტყობინება, გასაგრძელებლად დაადასტურეთ',
        ),
      ),
      _NotificationTextPattern(
        RegExp(
          r'^New order request arrived, you can confirm this\.?$',
          caseSensitive: false,
        ),
        (_) => _translatedLabel(
          'notification_new_order_request_body',
          'ახალი შეკვეთის მოთხოვნა მოვიდა, შეგიძლიათ დაადასტუროთ.',
        ),
      ),
      _NotificationTextPattern(
        RegExp(r'^(\d+)\s+Order is picked up$', caseSensitive: false),
        (match) =>
            '${_translatedLabel('notification_order_prefix', 'შეკვეთა')} #${match.group(1)} ${_translatedLabel('notification_picked_up', 'აღებულია')}',
      ),
      _NotificationTextPattern(
        RegExp(r'^Order\s+#?(\d+)\s+is picked up$', caseSensitive: false),
        (match) =>
            '${_translatedLabel('notification_order_prefix', 'შეკვეთა')} #${match.group(1)} ${_translatedLabel('notification_picked_up', 'აღებულია')}',
      ),
      _NotificationTextPattern(
        RegExp(
          r'^Order\s+#?(\d+)\s+delivered successfully$',
          caseSensitive: false,
        ),
        (match) =>
            '${_translatedLabel('notification_order_prefix', 'შეკვეთა')} #${match.group(1)} ${_translatedLabel('notification_delivered_successfully', 'წარმატებით ჩაბარდა')}',
      ),
      _NotificationTextPattern(
        RegExp(
          r'^Order\s+#?(\d+)\s+is delivered successfully$',
          caseSensitive: false,
        ),
        (match) =>
            '${_translatedLabel('notification_order_prefix', 'შეკვეთა')} #${match.group(1)} ${_translatedLabel('notification_delivered_successfully', 'წარმატებით ჩაბარდა')}',
      ),
      _NotificationTextPattern(
        RegExp(
          r'^You have earned\s+([\d.,]+)\s+Loyalty points?$',
          caseSensitive: false,
        ),
        (match) =>
            '${_translatedLabel('notification_loyalty_points_earned_prefix', 'თქვენ დაგერიცხათ')} ${match.group(1)} ${_translatedLabel('notification_loyalty_points_unit', 'ქულა')}',
      ),
      _NotificationTextPattern(
        RegExp(
          r'^You have converted\s+([\d.,]+)\s+Loyalty points?$',
          caseSensitive: false,
        ),
        (match) =>
            '${_translatedLabel('notification_loyalty_points_converted_prefix', 'თქვენ გადაცვალეთ')} ${match.group(1)} ${_translatedLabel('notification_loyalty_points_unit', 'ქულა')}',
      ),
    ];

    for (final pattern in patterns) {
      final RegExpMatch? match = pattern.regex.firstMatch(normalizedText);
      if (match != null) {
        return pattern.builder(match);
      }
    }

    return normalizedText;
  }

  static String _translatedLabel(String key, String fallback) {
    final String translated = key.tr;
    return translated == key ? fallback : translated;
  }

  static Future<void> showTextNotification(
    String title,
    String body,
    NotificationBodyModel notificationBody,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'portal_notifications',
          AppConstants.appName,
          playSound: true,
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound('notification'),
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await fln.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(notificationBody.toJson()),
    );
  }

  static Future<void> showBigTextNotification(
    String? title,
    String body,
    NotificationBodyModel? notificationBody,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'portal_notifications',
          AppConstants.appName,
          importance: Importance.max,
          styleInformation: bigTextStyleInformation,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification'),
        );
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await fln.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: notificationBody != null
          ? jsonEncode(notificationBody.toJson())
          : null,
    );
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
    String? title,
    String? body,
    NotificationBodyModel? notificationBody,
    String image,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(
      image,
      'bigPicture',
    );
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: body,
          htmlFormatSummaryText: true,
        );
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'portal_notifications',
          AppConstants.appName,
          largeIcon: FilePathAndroidBitmap(largeIconPath),
          priority: Priority.max,
          playSound: true,
          styleInformation: bigPictureStyleInformation,
          importance: Importance.max,
          sound: const RawResourceAndroidNotificationSound('notification'),
        );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await fln.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: notificationBody != null
          ? jsonEncode(notificationBody.toJson())
          : null,
    );
  }

  static Future<String> _downloadAndSaveFile(
    String url,
    String fileName,
  ) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static NotificationBodyModel? convertNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final orderId = data['order_id'];

    switch (type) {
      case 'cash_collect':
        return NotificationBodyModel(
          notificationType: NotificationType.general,
        );
      case 'unassign':
        return NotificationBodyModel(
          notificationType: NotificationType.unassign,
        );
      case 'order_status':
        return NotificationBodyModel(
          orderId: int.parse(orderId),
          notificationType: NotificationType.order,
        );
      case 'order_request':
        return NotificationBodyModel(
          orderId: int.parse(orderId),
          notificationType: NotificationType.order_request,
        );
      case 'block':
        return NotificationBodyModel(notificationType: NotificationType.block);
      case 'unblock':
        return NotificationBodyModel(
          notificationType: NotificationType.unblock,
        );
      case 'otp':
        return NotificationBodyModel(notificationType: NotificationType.otp);
      case 'message':
        return _handleMessageNotification(data);
      case 'withdraw':
        return NotificationBodyModel(
          notificationType: NotificationType.withdraw,
        );
      case 'deliveryman_referral':
        return NotificationBodyModel(
          notificationType: NotificationType.general,
        );
      default:
        return NotificationBodyModel(
          notificationType: NotificationType.general,
        );
    }
  }

  static NotificationBodyModel _handleMessageNotification(
    Map<String, dynamic> data,
  ) {
    final conversationId = data['conversation_id'];
    final senderType = data['sender_type'];

    return NotificationBodyModel(
      conversationId: (conversationId != null && conversationId.isNotEmpty)
          ? int.parse(conversationId)
          : null,
      notificationType: NotificationType.message,
      type: senderType == AppConstants.user
          ? AppConstants.user
          : AppConstants.vendor,
    );
  }
}

final AudioPlayer _audioPlayer = AudioPlayer();

/// Background FCM message handler
@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  customPrint("onBackground: ${message.data}");

  final notificationBody = NotificationHelper.convertNotification(message.data);

  if (notificationBody != null &&
      (notificationBody.notificationType == NotificationType.order ||
          notificationBody.notificationType ==
              NotificationType.order_request)) {
    FlutterForegroundTask.initCommunicationPort();
    await _initService();
    await _startService(
      notificationBody.orderId?.toString(),
      notificationBody.notificationType!,
    );
  }
}

/// Initialize Foreground Service
@pragma('vm:entry-point')
Future<void> _initService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'portal_notifications',
      channelName: 'Foreground Service Notification',
      channelDescription:
          'This notification appears when the foreground service is running.',
      onlyAlertOnce: false,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

/// Start Foreground Service
@pragma('vm:entry-point')
Future<ServiceRequestResult> _startService(
  String? orderId,
  NotificationType notificationType,
) async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    final bool isKa =
        await NotificationHelper.shouldUseGeorgianNotificationText();
    final String requestTitle = isKa
        ? NotificationHelper._translatedLabel(
            'notification_new_order_request_title',
            'შეკვეთის შეტყობინება',
          )
        : 'Order Notification';
    final String requestBody = isKa
        ? NotificationHelper._translatedLabel(
            'notification_new_order_request_body',
            'ახალი შეკვეთის მოთხოვნა მოვიდა, შეგიძლიათ დაადასტუროთ.',
          )
        : 'New order request arrived, you can confirm this.';
    final String assignedTitle = isKa
        ? '${NotificationHelper._translatedLabel('notification_assigned_new_order', 'ახალი შეკვეთა დაგენიშნათ')}${orderId != null && orderId.isNotEmpty ? ' (#$orderId)' : ''}'
        : 'You have been assigned a new order ($orderId)';
    final String assignedBody = isKa
        ? NotificationHelper._translatedLabel(
            'notification_open_app_check_order_details',
            'გახსენით აპი და გადაამოწმეთ შეკვეთის დეტალები.',
          )
        : 'Open app and check order details.';
    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: notificationType == NotificationType.order_request
          ? requestTitle
          : assignedTitle,
      notificationText: notificationType == NotificationType.order_request
          ? requestBody
          : assignedBody,
      callback: startCallback,
    );
  }
}

/// Stop Foreground Service
@pragma('vm:entry-point')
Future<ServiceRequestResult> stopService() async {
  try {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  } catch (e) {
    customPrint('Audio dispose error: $e');
  }
  return FlutterForegroundTask.stopService();
}

/// Foreground Service entry point
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

/// Foreground Service Task Handler
class MyTaskHandler extends TaskHandler {
  AudioPlayer? _localPlayer;

  void _playAudio() {
    _localPlayer?.play(AssetSource('notification.mp3'));
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _localPlayer = AudioPlayer();
    _playAudio();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _playAudio();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _localPlayer?.dispose();
    await stopService();
  }

  @override
  void onReceiveData(Object data) {
    _playAudio();
  }

  @override
  void onNotificationButtonPressed(String id) {
    customPrint('onNotificationButtonPressed: $id');
    if (id == '1') {
      FlutterForegroundTask.launchApp('/');
    }
    stopService();
  }

  @override
  void onNotificationPressed() {
    customPrint('onNotificationPressed');
    FlutterForegroundTask.launchApp('/');
    stopService();
  }

  @override
  void onNotificationDismissed() async {
    final bool isKa =
        await NotificationHelper.shouldUseGeorgianNotificationText();
    FlutterForegroundTask.updateService(
      notificationTitle: isKa
          ? NotificationHelper._translatedLabel(
              'notification_assigned_new_order',
              'ახალი შეკვეთა დაგენიშნათ',
            )
          : 'You got a new order!',
      notificationText: isKa
          ? NotificationHelper._translatedLabel(
              'notification_open_app_check_order_details',
              'გახსენით აპი და გადაამოწმეთ შეკვეთის დეტალები.',
            )
          : 'Open app and check order details.',
    );
  }
}

class _NotificationTextPattern {
  final RegExp regex;
  final String Function(RegExpMatch match) builder;

  const _NotificationTextPattern(this.regex, this.builder);
}
