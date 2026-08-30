import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/country_code_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';
import '../controller/auth_controller.dart';
import 'forget_password_screen.dart';
import 'regester_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = 'LoginScreen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ValidationMixin {
  final _mobileEc = TextEditingController();
  final _passwordEc = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Country? _country;

  bool get _isArabic => context.locale.languageCode == 'ar';

  @override
  void initState() {
    _country = CountryCodeMethods.getByCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _mobileEc.dispose();
    _passwordEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _LoginBackgroundPainter())),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    MediaQuery.viewInsetsOf(context).bottom + 42,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            Image.asset(
                              AppImages.appIcon,
                              width: 174,
                              height: 174,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isArabic ? 'مرحباً بك' : 'Welcome',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 31,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLocaleKey.welcomePleaseEnterYourAccountDetails.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: softText,
                                fontSize: 17,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(22, 25, 22, 24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.97),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xffF0F1F3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff082A4D).withOpacity(.08),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppLocaleKey.mobileNumber.tr(),
                                    style: const TextStyle(
                                      color: navy,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _isArabic
                                        ? 'يرجى إدخال الرقم بدون الـ 0'
                                        : 'Please enter the number without the leading 0',
                                    style: const TextStyle(
                                      color: softText,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 11),
                                  CustomFormField(
                                    controller: _mobileEc,
                                    validator: (v) => validatePhone(v, country: _country),
                                    keyboardType: TextInputType.phone,
                                    textDirection: ui.TextDirection.ltr,
                                    hintText: '10XXXXXXXX',
                                    radius: 17,
                                    hasShadow: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 13),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    prefixIcon: Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_country?.flagEmoji ?? '🇪🇬'}  +${_country?.phoneCode ?? '20'}',
                                            textDirection: ui.TextDirection.ltr,
                                            style: const TextStyle(
                                              color: navy,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(width: 1, height: 26, color: const Color(0xffE1E3E7)),
                                          const SizedBox(width: 2),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    AppLocaleKey.password.tr(),
                                    style: const TextStyle(
                                      color: navy,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  CustomFormField(
                                    controller: _passwordEc,
                                    title: null,
                                    isPassword: true,
                                    textDirection: ui.TextDirection.ltr,
                                    radius: 17,
                                    hasShadow: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 13),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 21,
                                      color: Color(0xffA8ADB5),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {
                                        NavigatorMethods.pushNamed(context, ForgetPasswordScreen.routeName);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColor.mainAppColor(context),
                                        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                                        style: TextStyle(
                                          color: AppColor.mainAppColor(context),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 19),
                                  CustomButton(
                                    height: 58,
                                    radius: 18,
                                    hasShadow: true,
                                    text: AppLocaleKey.login.tr(),
                                    suffixIcon: const Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 23,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColor.mainAppColor(context).withOpacity(.26),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    onPressed: _login,
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(color: Color(0xffE4E6E9), height: 1)),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 9),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xffAAB0B8),
                                        ),
                                      ),
                                      const Expanded(child: Divider(color: Color(0xffE4E6E9), height: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 10,
                                    children: [
                                      Text(
                                        _isArabic ? 'للتسجيل للمرة الأولى' : 'First time here?',
                                        style: const TextStyle(
                                          color: Color(0xff5F6670),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _openRegistration,
                                        icon: Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: AppColor.mainAppColor(context),
                                          size: 21,
                                        ),
                                        label: Text(
                                          _isArabic ? 'إنشاء حساب جديد' : 'Create new account',
                                          style: TextStyle(
                                            color: AppColor.mainAppColor(context),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                                          side: BorderSide(color: AppColor.mainAppColor(context), width: 1.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthController>().login(
      onHaveId: (id, token) {
        context.read<PusherController>().initPusher(
          channelName: 'private-user.$id',
          userId: id,
          token: token,
        );
      },
      mobile: _mobileEc.text.removeZero(),
      password: _passwordEc.text,
      onSuccess: (accountType) {
        if (accountType == 'delegate') {
          NavigatorMethods.pushNamedAndRemoveUntil(context, DelegateBottomNavBarScreen.routeName);
        }
      },
    );
  }

  void _openRegistration() {
    NavigatorMethods.pushNamed(
      context,
      RegisterAsDeliveryScreen.routeName,
      arguments: RegisterAsDeliveryScreenArgs(
        onSuccess: () {
          setState(() {});
        },
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);
    const navy = Color(0xff082A4D);

    final topGlow = Paint()..color = orange.withOpacity(.09);
    final topAccent = Paint()..color = orange.withOpacity(.95);
    final bottomOrange = Paint()..color = orange.withOpacity(.92);
    final bottomNavy = Paint()..color = navy;

    final glowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .48, 0)
      ..quadraticBezierTo(size.width * .27, 34, 0, 150)
      ..close();
    canvas.drawPath(glowPath, topGlow);

    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .31, 0)
      ..quadraticBezierTo(size.width * .16, 28, 0, 92)
      ..close();
    canvas.drawPath(topPath, topAccent);

    final navyPath = Path()
      ..moveTo(size.width * .40, size.height)
      ..quadraticBezierTo(size.width * .72, size.height - 88, size.width, size.height - 118)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(navyPath, bottomNavy);

    final orangePath = Path()
      ..moveTo(size.width * .30, size.height)
      ..quadraticBezierTo(size.width * .66, size.height - 105, size.width, size.height - 145)
      ..lineTo(size.width, size.height - 125)
      ..quadraticBezierTo(size.width * .70, size.height - 82, size.width * .44, size.height)
      ..close();
    canvas.drawPath(orangePath, bottomOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
