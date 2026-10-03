import 'package:sixam_mart_delivery/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/slider_button_widget.dart';
import 'package:sixam_mart_delivery/features/language/controllers/language_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/bottom_view/delivery_confirmation_section.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/parcel_cancelation/cancellation_reason_bottom_sheet.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/parcel_cancelation/collect_money_bottom_sheet.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/parcel_cancelation/parcel_return_date_time_bottom_sheet.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/verify_delivery_sheet_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ParcelState {waitingToAccept, readyToConfirm, readyToPickup, readyToDeliver, readyToReturn, completed}

class ParcelBottomView extends StatelessWidget {
  final OrderController orderController;
  final OrderModel controllerOrderModel;
  final bool fromLocationScreen;
  final bool showDeliveryConfirmImage;
  final int orderId;
  final double? total;
  const ParcelBottomView({super.key, required this.orderController, required this.controllerOrderModel, required this.fromLocationScreen, required this.showDeliveryConfirmImage, required this.orderId, this.total});

  @override
  Widget build(BuildContext context) {

    final bool isShowableStatus = ['accepted', 'confirmed', 'handover'].contains(controllerOrderModel.orderStatus);
    final bool hasValidPayer = controllerOrderModel.chargePayer == 'sender' || controllerOrderModel.chargePayer == 'receiver';

    final bool showPaymentInfo = isShowableStatus && hasValidPayer;

    final parcelState = _getParcelState(controllerOrderModel);

    switch (parcelState) {
      case ParcelState.waitingToAccept:
        return const _ParcelWaitingStatus();

      case ParcelState.readyToConfirm:
        return _ParcelConfirmationActions(orderController: orderController, order: controllerOrderModel, showPaymentInfo: showPaymentInfo, total: total);

      case ParcelState.readyToPickup:
        return _ParcelPickupSlider(orderController: orderController, order: controllerOrderModel, showPaymentInfo: showPaymentInfo, total: total);

      case ParcelState.readyToDeliver:
        return _ParcelDeliverySlider(orderController: orderController, order: controllerOrderModel, showDeliveryConfirmImage: showDeliveryConfirmImage, fromLocationScreen: fromLocationScreen);

      case ParcelState.readyToReturn:
      return _ParcelReturnOption(order: controllerOrderModel, orderController: orderController, orderId: orderId);

      default:
        return const SizedBox();
    }
  }

  ParcelState _getParcelState(OrderModel order) {
    final status = order.orderStatus;

    switch (status) {
      case AppConstants.accepted || AppConstants.confirmed:
        return ParcelState.readyToConfirm;
      case AppConstants.handover:
        return ParcelState.readyToPickup;
      case AppConstants.pickedUp:
        return ParcelState.readyToDeliver;
      case AppConstants.canceled:
        return ParcelState.readyToReturn;
      default:
        return ParcelState.completed;
    }
  }
}

// Parcel waiting status
class _ParcelWaitingStatus extends StatelessWidget {
  const _ParcelWaitingStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Text('order_waiting_for_process'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge), textAlign: TextAlign.center),
    );
  }
}

// Parcel confirmation actions (Cancel/Confirm buttons)
class _ParcelConfirmationActions extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final bool showPaymentInfo;
  final double? total;
  const _ParcelConfirmationActions({required this.orderController, required this.order, required this.showPaymentInfo, required this.total});

  @override
  Widget build(BuildContext context) {
    final cancelPermission = Get.find<SplashController>().configModel!.canceledByDeliveryman ?? false;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column( mainAxisAlignment: MainAxisAlignment.start,
        children: [
          showPaymentInfo ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Image.asset(Images.coinIcon, width: 15, height: 15),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('amount_collect_from_customer'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                (order.paymentMethod != 'cash_on_delivery' && order.paymentMethod != 'offline_payment') && order.paymentStatus == 'paid' ? Text('already_paid_digitally'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)) : const SizedBox.shrink(),
              ],
            )),
            Text(
              (order.paymentMethod != 'cash_on_delivery' &&order.paymentMethod != 'offline_payment') && order.paymentStatus == 'paid' ? '0.0' : PriceConverterHelper.convertPrice(total),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ]) : const SizedBox.shrink(),
          showPaymentInfo ? const SizedBox(height: Dimensions.paddingSizeExtraSmall) : const SizedBox.shrink(),
          Row(children: [
            (cancelPermission && ((order.isGuest! && order.orderStatus == 'pending')
                || (!order.isGuest!))) ? Expanded(child: _ParcelCancelButton(order: order))
                : const SizedBox(),
            SizedBox(width: (cancelPermission && ((order.isGuest! && order.orderStatus == 'pending') || (!order.isGuest!))) ? Dimensions.paddingSizeSmall : 0),

            Expanded(
              child: _ParcelConfirmButton(orderController: orderController, order: order),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ParcelCancelButton extends StatelessWidget {
  final OrderModel order;
  const _ParcelCancelButton({required this.order});

  @override
  Widget build(BuildContext context) {
    return CustomButtonWidget(
      buttonText: 'cancel'.tr,
      isBorder: true, transparent: true,
      fontColor: Theme.of(context).textTheme.bodyLarge!.color,
      onPressed: () {
        showCustomBottomSheet(
          child: CancellationReasonBottomSheet(
            isBeforePickup: _isBeforePickup(order),
            orderId: order.id!,
          ),
        );
      },
    );
  }
}

class _ParcelConfirmButton extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  const _ParcelConfirmButton({required this.orderController, required this.order});

  @override
  Widget build(BuildContext context) {
    return CustomButtonWidget(
      buttonText: 'confirm'.tr,
      onPressed: _handleParcelConfirmation,
    );
  }

  void _handleParcelConfirmation() {
    Get.dialog(
      ConfirmationDialogWidget(
        icon: Images.warning,
        title: 'are_you_sure_to_confirm'.tr,
        description: 'you_want_to_confirm_this_delivery'.tr,
        onYesPressed: () => orderController.updateOrderStatus(order, AppConstants.handover),
      ),
      barrierDismissible: false,
    );
  }
}

// Parcel pickup slider
class _ParcelPickupSlider extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final bool showPaymentInfo;
  final double? total;
  const _ParcelPickupSlider({required this.orderController, required this.order, required this.showPaymentInfo, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        showPaymentInfo ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Image.asset(Images.coinIcon, width: 15, height: 15),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('amount_collect_from_customer'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
              (order.paymentMethod != 'cash_on_delivery' && order.paymentMethod != 'offline_payment') && order.paymentStatus == 'paid' ? Text('already_paid_digitally'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)) : const SizedBox.shrink(),
            ],
          )),
          Text(
            (order.paymentMethod != 'cash_on_delivery' && order.paymentMethod != 'offline_payment') && order.paymentStatus == 'paid' ? '0.0' : PriceConverterHelper.convertPrice(total),
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
        ]) : const SizedBox.shrink(),
        showPaymentInfo ? const SizedBox(height: Dimensions.paddingSizeExtraSmall) : const SizedBox.shrink(),
        SliderButton(
          action: _handleParcelPickup,
          label: Text(
            'swipe_to_pick_up_parcel'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
          ),
          dismissThresholds: 0.5, dismissible: false,
          shimmer: true, width: 1170, height: 60, buttonSize: 50, radius: 10,
          icon: const _SliderIcon(),
          isLtr: Get.find<LocalizationController>().isLtr,
          boxShadow: const BoxShadow(blurRadius: 0),
          buttonColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          baseColor: Theme.of(context).primaryColor,
        ),

        (order.isGuest! && order.orderStatus == 'pending') || (!order.isGuest!) ? _ParcelCancelOption(order: order) : const SizedBox(height: 15),
      ]),
    );
  }

  void _handleParcelPickup() {
    final cod = order.paymentMethod == 'cash_on_delivery';

    if (order.chargePayer == 'sender' && cod) {
      Get.bottomSheet(
        VerifyDeliverySheetWidget(
          currentOrderModel: order,
          verify: false,
          isSetOtp: false,
          orderAmount: order.orderAmount,
          cod: cod,
          isSenderPay: true,
          isParcel: true,
        ),
        isScrollControlled: true,
      );
    } else {
      if (Get.find<ProfileController>().profileModel!.active == 1) {
        orderController.updateOrderStatus(order, AppConstants.pickedUp);
      } else {
        showCustomSnackBar('make_yourself_online_first'.tr);
      }
    }
  }
}

// Parcel delivery slider
class _ParcelDeliverySlider extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final bool showDeliveryConfirmImage;
  final bool fromLocationScreen;
  const _ParcelDeliverySlider({required this.orderController, required this.order, required this.showDeliveryConfirmImage, required this.fromLocationScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(children: [
        if (showDeliveryConfirmImage) const DeliveryConfirmationSection(),
        SizedBox(height: showDeliveryConfirmImage ? Dimensions.paddingSizeSmall : 0),

        SliderButton(
          action: _handleParcelDelivery,
          label: Text(
            'swipe_to_deliver_parcel'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
          ),
          dismissThresholds: 0.5, dismissible: false,
          shimmer: true, width: 1170, height: 60, buttonSize: 50, radius: 10,
          icon: const _SliderIcon(),
          isLtr: Get.find<LocalizationController>().isLtr,
          boxShadow: const BoxShadow(blurRadius: 0),
          buttonColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          baseColor: Theme.of(context).primaryColor,
        ),

        (order.isGuest! && order.orderStatus == 'pending') || (!order.isGuest!) ? _ParcelCancelOption(order: order) : const SizedBox(height: 15),
      ]),
    );
  }

  void _handleParcelDelivery() {
    final orderVerificationActive = Get.find<SplashController>().configModel?.orderDeliveryVerification ?? false;
    final cod = order.paymentMethod == 'cash_on_delivery';

    if (orderVerificationActive && order.chargePayer != 'sender' && cod) {
      _showParcelVerifyDeliverySheet(order, orderVerificationActive, cod, false);
    } else if (orderVerificationActive && order.chargePayer == 'sender' && cod) {
      _showParcelVerifyDeliverySheet(order, orderVerificationActive, cod, true);
    } else if (orderVerificationActive) {
      _showParcelVerifyDeliverySheet(order, orderVerificationActive, cod, null);
    } else if(order.chargePayer != 'sender') {
      _showParcelVerifyDeliverySheet(order, orderVerificationActive, cod, false);
    } else {
      orderController.updateOrderStatus(
        order,
        AppConstants.delivered,
        back: fromLocationScreen ? false : true,
        gotoDashboard: fromLocationScreen ? true : false,
      );
    }
  }

  void _showParcelVerifyDeliverySheet(OrderModel order, bool verify, bool cod, bool? isSenderPay) {
    Get.bottomSheet(
      VerifyDeliverySheetWidget(
        currentOrderModel: order,
        verify: verify,
        orderAmount: order.orderAmount,
        cod: cod,
        isSenderPay: isSenderPay ?? false,
        isParcel: true,
      ),
      isScrollControlled: true,
    ).then((value) {
      if (value == 'show_price_view') {
        Get.bottomSheet(
          VerifyDeliverySheetWidget(
            currentOrderModel: order,
            verify: false,
            isSetOtp: false,
            orderAmount: order.orderAmount,
            cod: cod,
            isSenderPay: isSenderPay ?? false,
            isParcel: true,
          ),
          isScrollControlled: true,
        );
      }
    });
  }
}

class _ParcelCancelOption extends StatelessWidget {
  final OrderModel order;
  const _ParcelCancelOption({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      child: InkWell(
        onTap: () {
          showCustomBottomSheet(
            child: CancellationReasonBottomSheet(
              isBeforePickup: _isBeforePickup(order),
              orderId: order.id!,
            ),
          );
        },
        child: Center(
          child: Text(
            'cancel_delivery'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

// Parcel return action
class _ParcelReturnOption extends StatelessWidget {
  final OrderModel order;
  final OrderController orderController;
  final int orderId;
  const _ParcelReturnOption({required this.order, required this.orderController, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return !(order.parcelCancellation?.beforePickup == 1) ? Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: order.parcelCancellation?.setReturnDate == 0 ? CustomButtonWidget(
        buttonText: 'set_return_date_and_time'.tr,
        onPressed: () {
          showCustomBottomSheet(
            child: ParcelReturnDateTimeBottomSheet(orderId: orderId, canceledDateTime: orderController.orderModel!.canceled!),
          );
        },
      ) : SliderButton(
        label: Text(
          'parcel_returned'.tr,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
        ),
        dismissThresholds: 0.5, dismissible: false,
        shimmer: true, width: 1170, height: 60, buttonSize: 50, radius: 10,
        icon: const _SliderIcon(),
        isLtr: Get.find<LocalizationController>().isLtr,
        boxShadow: const BoxShadow(blurRadius: 0),
        buttonColor: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        baseColor: Theme.of(context).primaryColor,
        action: () {
          showCustomBottomSheet(
            child: CollectMoneyBottomSheet(orderId: orderId),
          );
        },
      ),
    ) : const SizedBox();
  }
}

class _SliderIcon extends StatelessWidget {
  const _SliderIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_arrow_left,
        color: Colors.white,
        size: 20.0,
      ),
    );
  }
}

bool _isBeforePickup(OrderModel order) {
  final status = order.orderStatus;
  return status == AppConstants.processing || status == AppConstants.accepted || status == AppConstants.confirmed || status == AppConstants.handover;
}
