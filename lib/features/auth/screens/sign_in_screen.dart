import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/helper/custom_validator_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/enums.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/features/auth/widgets/mili_auth_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRideActive = AppConstants.appMode == AppMode.ride;
    final config = Get.find<SplashController>().configModel;
    final registrationEnabled = isRideActive
        ? (config?.toggleRiderRegistration ?? false)
        : (config?.toggleDmRegistration ?? false);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: GetBuilder<AuthController>(
          builder: (authController) {
            void submit() {
              if (!authController.isLoading) {
                _login(
                  authController,
                  _phoneController,
                  _passwordController,
                  _countryDialCode!,
                  _countryCode!,
                  context,
                );
              }
            }

            return MiliAuthLayout(
              logoAsset: Images.brandMark,
              children: [
                MiliAuthIntro(
                  title: 'auth_ui_title'.tr,
                  subtitle: isRideActive
                      ? 'rider_login_subtitle'.tr
                      : 'auth_ui_courier_subtitle'.tr,
                ),
                MiliAuthField(
                  label: 'phone_number'.tr,
                  hint: 'auth_ui_phone_hint'.tr,
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  nextFocus: _passwordFocus,
                  inputType: TextInputType.phone,
                  isPhone: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9+]')),
                  ],
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  countryDialCode:
                      _countryCode ??
                      CountryCode.fromCountryCode(
                        Get.find<SplashController>().configModel!.country!,
                      ).code,
                  onCountryChanged: (countryCode) {
                    _countryDialCode = countryCode.dialCode;
                    _countryCode = countryCode.code;
                  },
                ),
                const SizedBox(height: 18),
                MiliAuthField(
                  label: 'password'.tr,
                  hint: 'enter_password'.tr,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  inputAction: TextInputAction.done,
                  inputType: TextInputType.visiblePassword,
                  isPassword: true,
                  onSubmit: (_) => submit(),
                ),
                MiliAuthOptions(
                  remember: authController.isActiveRememberMe,
                  onRemember: authController.toggleRememberMe,
                  onForgot: () => Get.toNamed(RouteHelper.getForgotPassRoute()),
                ),
                MiliAuthSubmit(
                  loading: authController.isLoading,
                  label: 'log_in'.tr,
                  onPressed: submit,
                ),
                if (registrationEnabled)
                  MiliAuthSecondary(
                    label: 'delivery_registration_cta_action'.tr,
                    description: 'delivery_registration_cta_title'.tr,
                    icon: Icons.delivery_dining_outlined,
                    onPressed: () => Get.toNamed(
                      RouteHelper.getDeliverymanRegistrationRoute(),
                    ),
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
