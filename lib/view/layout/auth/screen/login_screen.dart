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
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxHeight < 860;
          final veryCompact = viewport.maxHeight < 740;
          final logoSize = veryCompact ? 118.0 : (compact ? 150.0 : 182.0);
          final topSpace = veryCompact ? 6.0 : (compact ? 12.0 : 18.0);

          return Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _LoginBackgroundPainter())),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    veryCompact ? 2 : 6,
                    18,
                    MediaQuery.viewInsetsOf(context).bottom + (veryCompact ? 16 : 24),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 520,
                        minHeight: viewport.maxHeight - MediaQuery.paddingOf(context).vertical - 34,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(height: topSpace),
                            Image.asset(
                              AppImages.appIcon,
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            SizedBox(height: veryCompact ? 3 : (compact ? 5 : 8)),
                            Text(
                              _isArabic ? 'مرحباً بك' : 'Welcome',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: navy,
                                fontSize: veryCompact ? 25 : (compact ? 27 : 30),
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 4 : 7),
                            Text(
                              AppLocaleKey.welcomePleaseEnterYourAccountDetails.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: softText,
                                fontSize: veryCompact ? 13.5 : (compact ? 14.5 : 16),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 10 : (compact ? 14 : 20)),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                compact ? 17 : 20,
                                compact ? 16 : 21,
                                compact ? 17 : 20,
                                compact ? 16 : 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.975),
                                borderRadius: BorderRadius.circular(compact ? 25 : 28),
                                border: Border.all(color: const Color(0xffEEF0F2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: navy.withOpacity(.075),
                                    blurRadius: compact ? 22 : 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppLocaleKey.mobileNumber.tr(),
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 15.5 : 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _isArabic
                                        ? 'يرجى إدخال الرقم بدون الـ 0'
                                        : 'Please enter the number without the leading 0',
                                    style: TextStyle(
                                      color: softText,
                                      fontSize: compact ? 12.5 : 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 7 : 10),
                                  CustomFormField(
                                    controller: _mobileEc,
                                    validator: (v) => validatePhone(v, country: _country),
                                    keyboardType: TextInputType.phone,
                                    textDirection: ui.TextDirection.ltr,
                                    hintText: '10XXXXXXXX',
                                    radius: 16,
                                    hasShadow: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: compact ? 12 : 14,
                                      horizontal: 12,
                                    ),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    prefixIcon: Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 12, end: 7),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_country?.flagEmoji ?? '🇪🇬'}  +${_country?.phoneCode ?? '20'}',
                                            textDirection: ui.TextDirection.ltr,
                                            style: TextStyle(
                                              color: navy,
                                              fontSize: compact ? 15.5 : 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(width: 1, height: 24, color: const Color(0xffE1E3E7)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 12 : 17),
                                  Text(
                                    AppLocaleKey.password.tr(),
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: compact ? 15.5 : 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 7 : 9),
                                  CustomFormField(
                                    controller: _passwordEc,
                                    isPassword: true,
                                    textDirection: ui.TextDirection.ltr,
                                    radius: 16,
                                    hasShadow: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: compact ? 12 : 14,
                                      horizontal: 12,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: Color(0xffA8ADB5),
                                    ),
                                  ),
                                  Align(
                                    alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {
                                        NavigatorMethods.pushNamed(context, ForgetPasswordScreen.routeName);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColor.mainAppColor(context),
                                        padding: EdgeInsets.only(top: compact ? 4 : 6, bottom: compact ? 3 : 5),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                                        style: TextStyle(
                                          color: AppColor.mainAppColor(context),
                                          fontSize: compact ? 13.5 : 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 10 : 15),
                                  CustomButton(
                                    height: compact ? 51 : 56,
                                    radius: 17,
                                    hasShadow: true,
                                    text: AppLocaleKey.login.tr(),
                                    suffixIcon: const Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 17 : 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColor.mainAppColor(context).withOpacity(.24),
                                        blurRadius: 16,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                    onPressed: _login,
                                  ),
                                  SizedBox(height: compact ? 14 : 20),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(color: Color(0xffE4E6E9), height: 1)),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                                  SizedBox(height: compact ? 12 : 17),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _isArabic ? 'للتسجيل للمرة الأولى' : 'First time here?',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: const Color(0xff5F6670),
                                            fontSize: compact ? 13.5 : 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Flexible(
                                        child: OutlinedButton.icon(
                                          onPressed: _openRegistration,
                                          icon: Icon(
                                            Icons.person_add_alt_1_rounded,
                                            color: AppColor.mainAppColor(context),
                                            size: compact ? 18 : 20,
                                          ),
                                          label: Text(
                                            _isArabic ? 'إنشاء حساب جديد' : 'Create new account',
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: AppColor.mainAppColor(context),
                                              fontSize: compact ? 13.5 : 14.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: compact ? 12 : 15,
                                              vertical: compact ? 10 : 12,
                                            ),
                                            side: BorderSide(color: AppColor.mainAppColor(context), width: 1.4),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: veryCompact ? 26 : (compact ? 38 : 62)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

    final topGlow = Paint()..color = orange.withOpacity(.08);
    final topAccent = Paint()..color = orange.withOpacity(.96);
    final bottomOrange = Paint()..color = orange.withOpacity(.94);
    final bottomNavy = Paint()..color = navy;

    final glowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .52, 0)
      ..quadraticBezierTo(size.width * .25, 32, 0, 142)
      ..close();
    canvas.drawPath(glowPath, topGlow);

    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .31, 0)
      ..quadraticBezierTo(size.width * .14, 25, 0, 84)
      ..close();
    canvas.drawPath(topPath, topAccent);

    final navyPath = Path()
      ..moveTo(size.width * .24, size.height)
      ..quadraticBezierTo(size.width * .66, size.height - 80, size.width, size.height - 112)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(navyPath, bottomNavy);

    final orangePath = Path()
      ..moveTo(size.width * .10, size.height)
      ..quadraticBezierTo(size.width * .58, size.height - 96, size.width, size.height - 137)
      ..lineTo(size.width, size.height - 111)
      ..quadraticBezierTo(size.width * .68, size.height - 73, size.width * .33, size.height)
      ..close();
    canvas.drawPath(orangePath, bottomOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
