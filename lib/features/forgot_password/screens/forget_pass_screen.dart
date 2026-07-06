import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/forgot_password/controllers/forgot_password_controller.dart';
import 'package:sixam_mart_delivery/helper/custom_validator_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPassScreen extends StatefulWidget {
  const ForgetPassScreen({super.key});

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  final TextEditingController _numberController = TextEditingController();
  String? _countryDialCode = CountryCode.fromCountryCode(
    Get.find<SplashController>().configModel!.country!,
  ).dialCode;
  String? _countryCode = CountryCode.fromCountryCode(
    Get.find<SplashController>().configModel!.country!,
  ).code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'forgot_password'.tr),
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                MediaQuery.of(context).viewInsets.bottom +
                    Dimensions.paddingSizeDefault,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _ForgotPasswordIllustration(),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        Text(
                          'შეიყვანეთ რეგისტრირებული\nმობილურის ნომერი',
                          textAlign: TextAlign.center,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeExtraLarge,
                            height: 1.25,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          'მოგაწვდით კოდს, რომლითაც პაროლის აღდგენას შეძლებთ.',
                          textAlign: TextAlign.center,
                          style: robotoRegular.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeSmall,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(
                          height: Dimensions.paddingSizeExtraLarge,
                        ),

                        CustomTextFieldWidget(
                          hintText: 'XXX-XXXXXX',
                          labelText: 'phone_number'.tr,
                          controller: _numberController,
                          inputType: TextInputType.phone,
                          inputAction: TextInputAction.done,
                          isPhone: true,
                          isRequired: true,
                          onCountryChanged: (CountryCode countryCode) {
                            _countryDialCode = countryCode.dialCode;
                            _countryCode = countryCode.code;
                          },
                          countryDialCode:
                              _countryCode ??
                              CountryCode.fromCountryCode(
                                Get.find<SplashController>()
                                    .configModel!
                                    .country!,
                              ).code,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        const _PhoneSecurityCard(),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        GetBuilder<ForgotPasswordController>(
                          builder: (forgotPasswordController) {
                            return _RecoverButton(
                              isLoading: forgotPasswordController.isLoading,
                              onPressed: () => _forgetPass(_countryDialCode!),
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        const _SecurePasswordFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _forgetPass(String countryCode) async {
    String phone = _numberController.text.trim();

    String numberWithCountryCode = countryCode + phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(
      numberWithCountryCode,
    );
    numberWithCountryCode = phoneValid.phone;

    if (phone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    } else if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
    } else {
      Get.find<ForgotPasswordController>()
          .forgetPassword(numberWithCountryCode)
          .then((status) async {
            if (status.isSuccess) {
              if (Get.find<SplashController>()
                  .configModel!
                  .firebaseOtpVerification!) {
                Get.find<ForgotPasswordController>().firebaseVerifyPhoneNumber(
                  numberWithCountryCode,
                );
              } else {
                Get.toNamed(
                  RouteHelper.getVerificationRoute(numberWithCountryCode),
                );
              }
            } else {
              showCustomSnackBar(status.message);
            }
          });
    }
  }
}

class _ForgotPasswordIllustration extends StatelessWidget {
  const _ForgotPasswordIllustration();

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 248,
            height: 188,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(96),
            ),
          ),
          Positioned(
            left: 90,
            child: Container(
              width: 96,
              height: 168,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_rounded, color: primaryColor, size: 46),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '••••',
                      style: robotoBold.copyWith(
                        color: primaryColor,
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Icon(Icons.lock_rounded, color: primaryColor, size: 30),
                ],
              ),
            ),
          ),
          Positioned(
            right: 70,
            top: 34,
            child: Container(
              width: 66,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.key_rounded, color: Colors.white),
            ),
          ),
          Positioned(
            right: 86,
            bottom: 34,
            child: Icon(Icons.person, color: primaryColor, size: 78),
          ),
        ],
      ),
    );
  }
}

class _PhoneSecurityCard extends StatelessWidget {
  const _PhoneSecurityCard();

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: primaryColor, size: 28),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              'ჩვენ არასდროს გავაზიარებთ თქვენს ნომერს სხვა პირებთან.',
              style: robotoMedium.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoverButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RecoverButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isLoading
            ? Theme.of(context).disabledColor
            : primaryColor,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'next'.tr,
                  style: robotoBold.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
                const Positioned(
                  right: 18,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SecurePasswordFooter extends StatelessWidget {
  const _SecurePasswordFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: Theme.of(context).primaryColor,
          size: 18,
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Flexible(
          child: Text(
            'უსაფრთხო და დაცული პაროლის გამოყენებით',
            style: robotoMedium.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ),
      ],
    );
  }
}
