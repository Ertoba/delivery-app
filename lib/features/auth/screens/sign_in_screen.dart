import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/helper/custom_validator_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/enums.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _countryDialCode;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _countryDialCode =
        Get.find<AuthController>().getUserCountryDialCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryDialCode()
        : CountryCode.fromCountryCode(
            Get.find<SplashController>().configModel!.country!,
          ).dialCode;
    _countryCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryCode()
        : CountryCode.fromCountryCode(
            Get.find<SplashController>().configModel!.country!,
          ).code;
    _phoneController.text = Get.find<AuthController>().getUserNumber();
    _passwordController.text = Get.find<AuthController>().getUserPassword();
  }

  @override
  Widget build(BuildContext context) {
    bool isRideActive = AppConstants.appMode == AppMode.ride;
    final config = Get.find<SplashController>().configModel;
    bool isSelfRegistrationActive = isRideActive
        ? (config?.toggleRiderRegistration ?? false)
        : (config?.toggleDmRegistration ?? false);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GetBuilder<AuthController>(
          builder: (authController) {
            return Stack(
              children: [
                const _CourierLoginBackground(),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ThemedAuthLogo(isRideActive: isRideActive),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          Text(
                            'sign_in'.tr,
                            textAlign: TextAlign.center,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeOverLarge,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.color,
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall,
                          ),
                          Text(
                            isRideActive
                                ? 'rider_login_subtitle'.tr
                                : 'delivery_login_subtitle'.tr,
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              height: 1.25,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraLarge,
                          ),
                          CustomTextFieldWidget(
                            hintText: 'XXX-XXXXXX',
                            labelText: 'phone_number'.tr,
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            nextFocus: _passwordFocus,
                            inputType: TextInputType.phone,
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
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          CustomTextFieldWidget(
                            hintText: '********',
                            labelText: 'password'.tr,
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            inputAction: TextInputAction.done,
                            inputType: TextInputType.visiblePassword,
                            isPassword: true,
                            isRequired: true,
                            onSubmit: (text) => GetPlatform.isWeb
                                ? _login(
                                    authController,
                                    _phoneController,
                                    _passwordController,
                                    _countryDialCode!,
                                    _countryCode!,
                                    context,
                                  )
                                : null,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          _LoginOptionsRow(authController: authController),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          _PrimaryLoginButton(
                            isLoading: authController.isLoading,
                            onPressed: () => _login(
                              authController,
                              _phoneController,
                              _passwordController,
                              _countryDialCode!,
                              _countryCode!,
                              context,
                            ),
                          ),
                          if (isSelfRegistrationActive) ...[
                            const SizedBox(
                              height: Dimensions.paddingSizeExtraLarge,
                            ),
                            const _OrDivider(),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),
                            _RegistrationEntry(isRideActive: isRideActive),
                          ],
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          _TrustFooter(isRideActive: isRideActive),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _login(
    AuthController authController,
    TextEditingController phoneText,
    TextEditingController passText,
    String countryDialCode,
    String countryCode,
    BuildContext context,
  ) async {
    String phone = phoneText.text.trim();
    String password = passText.text.trim();
    String type = AppConstants.appMode == AppMode.delivery
        ? AppConstants.isDelivery
        : AppConstants.isRide;

    String numberWithCountryCode = countryDialCode + phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(
      numberWithCountryCode,
    );
    numberWithCountryCode = phoneValid.phone;

    if (phone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    } else if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
    } else if (password.isEmpty) {
      showCustomSnackBar('enter_password'.tr);
    } else if (password.length < 6) {
      showCustomSnackBar('password_should_be'.tr);
    } else {
      authController.login(numberWithCountryCode, password, type).then((
        status,
      ) async {
        if (status.isSuccess) {
          if (authController.isActiveRememberMe) {
            authController.saveUserNumberAndPassword(
              phone,
              password,
              countryDialCode,
              countryCode,
            );
          } else {
            authController.clearUserNumberAndPassword();
          }
          await Get.find<ProfileController>().getProfile();
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          showCustomSnackBar(status.message);
        }
      });
    }
  }
}

class _CourierLoginBackground extends StatelessWidget {
  const _CourierLoginBackground();

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -130,
              left: -110,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 150,
              right: 58,
              child: Icon(
                Icons.cloud_rounded,
                size: 52,
                color: primaryColor.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemedAuthLogo extends StatelessWidget {
  final bool isRideActive;

  const _ThemedAuthLogo({required this.isRideActive});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            child: Container(
              width: 136,
              height: 92,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
            ),
          ),
          Positioned(
            left: 86,
            bottom: 10,
            child: Icon(
              Icons.route_outlined,
              size: 34,
              color: primaryColor.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            right: 86,
            top: 12,
            child: Icon(
              isRideActive
                  ? Icons.two_wheeler_rounded
                  : Icons.delivery_dining_rounded,
              size: 42,
              color: primaryColor.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 160,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Image.asset(
              Images.authLogo,
              width: 146,
              height: 78,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginOptionsRow extends StatelessWidget {
  final AuthController authController;

  const _LoginOptionsRow({required this.authController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            onTap: authController.toggleRememberMe,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    activeColor: Theme.of(context).primaryColor,
                    value: authController.isActiveRememberMe,
                    onChanged: (bool? isChecked) =>
                        authController.toggleRememberMe(),
                  ),
                  Expanded(
                    child: Text(
                      'remember_me'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Get.toNamed(RouteHelper.getForgotPassRoute()),
          child: Text(
            '${'forgot_password'.tr}?',
            textAlign: TextAlign.end,
            style: robotoBold.copyWith(
              color: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryLoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isLoading
            ? Theme.of(context).disabledColor
            : primaryColor,
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  'loading'.tr,
                  style: robotoBold.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const SizedBox(width: 30),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Flexible(
                        child: Text(
                          'log_in'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoBold.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: Text(
            'or'.tr,
            style: robotoMedium.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
      ],
    );
  }
}

class _RegistrationEntry extends StatelessWidget {
  final bool isRideActive;

  const _RegistrationEntry({required this.isRideActive});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: () => Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute()),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                isRideActive
                    ? Icons.two_wheeler_rounded
                    : Icons.delivery_dining_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'delivery_registration_cta_title'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault * 0.675,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    isRideActive
                        ? 'rider_registration_cta_subtitle'.tr
                        : 'delivery_registration_cta_subtitle'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeSmall * 0.675,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Text(
                    'delivery_registration_cta_action'.tr,
                    style: robotoBold.copyWith(
                      color: primaryColor,
                      fontSize: Dimensions.fontSizeDefault * 0.675,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Icon(Icons.chevron_right_rounded, color: primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  final bool isRideActive;

  const _TrustFooter({required this.isRideActive});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 80,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isRideActive
                    ? 'rider_data_security_note'.tr
                    : 'delivery_data_security_note'.tr,
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
