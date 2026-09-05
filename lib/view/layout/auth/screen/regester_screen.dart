import 'dart:io';
import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/country_code_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../../global/widget/custom_image_container.dart';
import '../../my_account/controller/delegate_account_controller.dart';
import '../controller/delegate_controller.dart';
import 'contract_delivery_screen.dart';
import 'login_screen.dart';

class RegisterAsDeliveryScreenArgs {
  final VoidCallback onSuccess;

  RegisterAsDeliveryScreenArgs({required this.onSuccess});
}

class RegisterAsDeliveryScreen extends StatefulWidget {
  static const String routeName = 'RegisterAsDeliveryScreen';

  final RegisterAsDeliveryScreenArgs args;
  const RegisterAsDeliveryScreen({super.key, required this.args});

  @override
  State<RegisterAsDeliveryScreen> createState() => _RegisterAsDeliveryScreenState();
}

class _RegisterAsDeliveryScreenState extends State<RegisterAsDeliveryScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameQuadrilateralEc = TextEditingController();
  final _nationalIdEc = TextEditingController();
  final _drivingLicenseNumberEc = TextEditingController();
  final _workAreaEc = TextEditingController();
  final _phoneNumberOneEc = TextEditingController();
  final _phoneNumberTwoEc = TextEditingController();
  final _vodafoneCashNumber = TextEditingController();
  final _emailEc = TextEditingController();
  File? _nationalIdImage;
  File? _drivingLicenseImage;
  Country? _country;

  // FocusNodes
  final _nameQuadrilateralFocusNode = FocusNode();
  final _nationalIdFocusNode = FocusNode();
  final _drivingLicenseFocusNode = FocusNode();
  final _workAreaFocusNode = FocusNode();
  final _phoneNumberOneFocusNode = FocusNode();
  final _phoneNumberTwoFocusNode = FocusNode();
  final _vodafoneCashFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  bool get _isArabic => context.locale.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _country = CountryCodeMethods.getByCode('20');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DelegateAccountController>().initialSetting();
      context.read<DelegateAccountController>().getSetting();
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameQuadrilateralEc.dispose();
    _nationalIdEc.dispose();
    _drivingLicenseNumberEc.dispose();
    _workAreaEc.dispose();
    _phoneNumberOneEc.dispose();
    _phoneNumberTwoEc.dispose();
    _vodafoneCashNumber.dispose();
    _emailEc.dispose();

    // Dispose FocusNodes
    _nameQuadrilateralFocusNode.dispose();
    _nationalIdFocusNode.dispose();
    _drivingLicenseFocusNode.dispose();
    _workAreaFocusNode.dispose();
    _phoneNumberOneFocusNode.dispose();
    _phoneNumberTwoFocusNode.dispose();
    _vodafoneCashFocusNode.dispose();
    _emailFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);
    final screenSize = MediaQuery.sizeOf(context);
    final compact = screenSize.height < 860;
    final horizontalPadding = screenSize.width < 420 ? 18.0 : 24.0;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        widget.args.onSuccess.call();
      },
      child: Consumer<DelegateAccountController>(
        builder: (context, delegateAccountController, child) {
          final hideInputs = delegateAccountController.setting?.delegateVendorSmallInfo != '0';
          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: _RegisterBackgroundPainter())),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 34),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Align(
                                  alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: 43,
                                    height: 43,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.96),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xffEEF0F2)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: navy.withOpacity(.08),
                                          blurRadius: 13,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: () => Navigator.maybePop(context),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        _isArabic
                                            ? Icons.arrow_forward_ios_rounded
                                            : Icons.arrow_back_ios_new_rounded,
                                        color: navy,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 3 : 7),
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/go_drive_logo_hd.webp',
                                    width: compact ? 112 : 132,
                                    height: compact ? 112 : 132,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                SizedBox(height: compact ? 7 : 10),
                                Text(
                                  AppLocaleKey.startAsDeliveryMan.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: compact ? 25 : 29,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isArabic
                                      ? 'أنشئ حسابك وابدأ استقبال طلبات التوصيل'
                                      : 'Create your account and start receiving deliveries',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: softText,
                                    fontSize: compact ? 14 : 15.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: compact ? 12 : 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: orange.withOpacity(.09),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    _isArabic ? 'الخطوة ١ من ٢  •  بيانات الحساب' : 'Step 1 of 2  •  Account details',
                                    style: TextStyle(
                                      color: orange,
                                      fontSize: compact ? 12.5 : 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 14 : 20),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.fromLTRB(
                                    compact ? 19 : 25,
                                    compact ? 21 : 27,
                                    compact ? 19 : 25,
                                    compact ? 20 : 25,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.985),
                                    borderRadius: BorderRadius.circular(compact ? 27 : 31),
                                    border: Border.all(color: const Color(0xffF0F1F3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: navy.withOpacity(.09),
                                        blurRadius: compact ? 25 : 34,
                                        offset: const Offset(0, 13),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildField(
                                        compact: compact,
                                        controller: _nameQuadrilateralEc,
                                        title: AppLocaleKey.nameQuadrilateral.tr(),
                                        validator: validateNameFourthly,
                                        focusNode: _nameQuadrilateralFocusNode,
                                        suffixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          color: Color(0xffAEB3BA),
                                          size: 23,
                                        ),
                                        onSubmitted: (_) {
                                          FocusScope.of(context).requestFocus(
                                            hideInputs ? _phoneNumberOneFocusNode : _nationalIdFocusNode,
                                          );
                                        },
                                      ),
                                      if (!hideInputs) ...[
                                        _fieldGap(compact),
                                        _buildField(
                                          compact: compact,
                                          controller: _nationalIdEc,
                                          title: AppLocaleKey.nationalId.tr(),
                                          validator: validateNationalId,
                                          keyboardType: TextInputType.number,
                                          textDirection: ui.TextDirection.ltr,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          focusNode: _nationalIdFocusNode,
                                          suffixIcon: const Icon(
                                            Icons.badge_outlined,
                                            color: Color(0xffAEB3BA),
                                            size: 22,
                                          ),
                                          onSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_drivingLicenseFocusNode);
                                          },
                                        ),
                                        _fieldGap(compact),
                                        _buildField(
                                          compact: compact,
                                          controller: _drivingLicenseNumberEc,
                                          title: AppLocaleKey.drivingLicenseNumber.tr(),
                                          validator: validateEmptyField,
                                          keyboardType: TextInputType.number,
                                          textDirection: ui.TextDirection.ltr,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          focusNode: _drivingLicenseFocusNode,
                                          suffixIcon: const Icon(
                                            Icons.credit_card_rounded,
                                            color: Color(0xffAEB3BA),
                                            size: 22,
                                          ),
                                          onSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_workAreaFocusNode);
                                          },
                                        ),
                                        _fieldGap(compact),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    AppLocaleKey.nationalIdImage.tr(),
                                                    textAlign: TextAlign.center,
                                                    style: _uploadTitleStyle(compact),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  CustomImageContainer(
                                                    image: _nationalIdImage,
                                                    onSuccess: (value) {
                                                      setState(() => _nationalIdImage = value);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    AppLocaleKey.drivingLicense.tr(),
                                                    textAlign: TextAlign.center,
                                                    style: _uploadTitleStyle(compact),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  CustomImageContainer(
                                                    image: _drivingLicenseImage,
                                                    onSuccess: (value) {
                                                      setState(() => _drivingLicenseImage = value);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        _fieldGap(compact),
                                        _buildField(
                                          compact: compact,
                                          controller: _workAreaEc,
                                          title: AppLocaleKey.workArea.tr(),
                                          validator: validateEmptyField,
                                          focusNode: _workAreaFocusNode,
                                          suffixIcon: const Icon(
                                            Icons.location_on_outlined,
                                            color: Color(0xffAEB3BA),
                                            size: 23,
                                          ),
                                          onSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_phoneNumberOneFocusNode);
                                          },
                                        ),
                                      ],
                                      _fieldGap(compact),
                                      _buildField(
                                        compact: compact,
                                        controller: _phoneNumberOneEc,
                                        title: _isArabic ? 'رقم الهاتف الأساسي' : AppLocaleKey.firstPhoneNumber.tr(),
                                        validator: (value) => validatePhone(value, country: _country),
                                        keyboardType: TextInputType.phone,
                                        textDirection: ui.TextDirection.ltr,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        focusNode: _phoneNumberOneFocusNode,
                                        showCountry: true,
                                        hintText: '10XXXXXXXX',
                                        suffixIcon: const Icon(
                                          Icons.phone_in_talk_outlined,
                                          color: Color(0xffAEB3BA),
                                          size: 23,
                                        ),
                                        onSubmitted: (_) {
                                          FocusScope.of(context).requestFocus(
                                            hideInputs ? _emailFocusNode : _phoneNumberTwoFocusNode,
                                          );
                                        },
                                      ),
                                      if (!hideInputs) ...[
                                        _fieldGap(compact),
                                        _buildField(
                                          compact: compact,
                                          controller: _phoneNumberTwoEc,
                                          title: _isArabic ? 'رقم هاتف إضافي' : AppLocaleKey.secondPhoneNumber.tr(),
                                          keyboardType: TextInputType.phone,
                                          textDirection: ui.TextDirection.ltr,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          focusNode: _phoneNumberTwoFocusNode,
                                          showCountry: true,
                                          hintText: '10XXXXXXXX',
                                          suffixIcon: const Icon(
                                            Icons.phone_outlined,
                                            color: Color(0xffAEB3BA),
                                            size: 23,
                                          ),
                                          onSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_vodafoneCashFocusNode);
                                          },
                                        ),
                                        _fieldGap(compact),
                                        _buildField(
                                          compact: compact,
                                          controller: _vodafoneCashNumber,
                                          title: AppLocaleKey.vodafonCashNumber.tr(),
                                          validator: (value) => validateVCash(value, country: _country),
                                          keyboardType: TextInputType.phone,
                                          textDirection: ui.TextDirection.ltr,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          focusNode: _vodafoneCashFocusNode,
                                          showCountry: true,
                                          hintText: '10XXXXXXXX',
                                          suffixIcon: const Icon(
                                            Icons.account_balance_wallet_outlined,
                                            color: Color(0xffAEB3BA),
                                            size: 22,
                                          ),
                                          onSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_emailFocusNode);
                                          },
                                        ),
                                      ],
                                      _fieldGap(compact),
                                      _buildField(
                                        compact: compact,
                                        controller: _emailEc,
                                        title: AppLocaleKey.email.tr(),
                                        validator: validateEmail,
                                        keyboardType: TextInputType.emailAddress,
                                        textDirection: ui.TextDirection.ltr,
                                        focusNode: _emailFocusNode,
                                        hintText: 'name@example.com',
                                        suffixIcon: const Icon(
                                          Icons.alternate_email_rounded,
                                          color: Color(0xffAEB3BA),
                                          size: 22,
                                        ),
                                      ),
                                      SizedBox(height: compact ? 21 : 27),
                                      ChangeNotifierProvider(
                                        create: (context) => VendorAndDeliveryController(),
                                        child: Builder(
                                          builder: (providerContext) {
                                            return CustomButton(
                                              height: compact ? 56 : 61,
                                              radius: 19,
                                              text: AppLocaleKey.next.tr(),
                                              gradient: const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Color(0xffFF8A08), Color(0xffFF6500)],
                                              ),
                                              suffixIcon: const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: compact ? 19 : 21,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: orange.withOpacity(.28),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                              onPressed: () {
                                                _continueRegistration(providerContext, hideInputs);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(height: compact ? 17 : 22),
                                      Directionality(
                                        textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 1,
                                          children: [
                                            Text(
                                              _isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                                              style: TextStyle(
                                                color: const Color(0xff646B75),
                                                fontSize: compact ? 14.5 : 15.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.maybePop(context),
                                              style: TextButton.styleFrom(
                                                foregroundColor: orange,
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                _isArabic ? 'تسجيل الدخول' : 'Sign in',
                                                style: TextStyle(
                                                  color: orange,
                                                  fontSize: compact ? 15 : 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 38 : 58),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required bool compact,
    required TextEditingController controller,
    required String title,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    ui.TextDirection? textDirection,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
    bool showCountry = false,
    String? hintText,
  }) {
    const navy = Color(0xff082A4D);

    return CustomFormField(
      controller: controller,
      title: title,
      titleStyle: TextStyle(
        color: navy,
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w700,
      ),
      validator: validator,
      keyboardType: keyboardType,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      hintText: hintText,
      radius: 17,
      hasShadow: false,
      fillColor: Colors.white,
      focusColor: const Color(0xffFD7201),
      unFocusColor: const Color(0xffDADDE2),
      textStyle: TextStyle(
        color: navy,
        fontSize: compact ? 16 : 17,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: const Color(0xffADB1B8),
        fontSize: compact ? 15.5 : 16.5,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: compact ? 15 : 18,
        horizontal: 13,
      ),
      prefixIcon: showCountry ? _countryPrefix(compact) : null,
      suffixIcon: suffixIcon,
    );
  }

  Widget _countryPrefix(bool compact) {
    const navy = Color(0xff082A4D);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 13, end: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_country?.flagEmoji ?? '🇪🇬'}  +${_country?.phoneCode ?? '20'}',
            textDirection: ui.TextDirection.ltr,
            style: TextStyle(
              color: navy,
              fontSize: compact ? 16 : 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: Color(0xffAEB3BA),
          ),
          const SizedBox(width: 7),
          Container(width: 1, height: 26, color: const Color(0xffE1E3E7)),
        ],
      ),
    );
  }

  Widget _fieldGap(bool compact) => SizedBox(height: compact ? 18 : 23);

  TextStyle _uploadTitleStyle(bool compact) {
    return TextStyle(
      color: const Color(0xff082A4D),
      fontSize: compact ? 14 : 15.5,
      fontWeight: FontWeight.w700,
    );
  }

  void _continueRegistration(BuildContext providerContext, bool hideInputs) {
    if (!_formKey.currentState!.validate()) return;

    if (!hideInputs && (_nationalIdImage == null || _drivingLicenseImage == null)) {
      CommonMethods.showError(message: AppLocaleKey.youMustAddAllImages.tr());
      return;
    }

    NavigatorMethods.pushNamed(
      context,
      ContractDeliveryScreen.routeName,
      arguments: ContractDeliveryArgs(
        name: _nameQuadrilateralEc.text,
        nationalId: _nationalIdEc.text,
        drivingLicenseNo: _drivingLicenseNumberEc.text,
        email: _emailEc.text,
        mobile: _phoneNumberOneEc.text,
        vodafoneCash: _vodafoneCashNumber.text,
        onConfirm: () {
          providerContext.read<VendorAndDeliveryController>().deliveryRegister(
            fullName: _nameQuadrilateralEc.text,
            drivingLicenseImage: _drivingLicenseImage,
            nationalId: int.tryParse(_nationalIdEc.text),
            drivingLicenseNo: _drivingLicenseNumberEc.text,
            nationalIdImage: _nationalIdImage,
            workArea: _workAreaEc.text,
            estMobile: _phoneNumberOneEc.text,
            sndMobile: _phoneNumberTwoEc.text,
            vodafoneCashMobile: _vodafoneCashNumber.text,
            email: _emailEc.text,
            onSuccess: () {
              NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName);
            },
          );
        },
      ),
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
  const _RegisterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);

    final topGlow = Paint()..color = orange.withOpacity(.11);
    final topAccent = Paint()..color = orange;
    final bottomGlow = Paint()..color = orange.withOpacity(.14);
    final bottomAccent = Paint()..color = orange;

    final glowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .50, 0)
      ..quadraticBezierTo(size.width * .23, 38, 0, 157)
      ..close();
    canvas.drawPath(glowPath, topGlow);

    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .37, 0)
      ..quadraticBezierTo(size.width * .16, 31, 0, 112)
      ..close();
    canvas.drawPath(topPath, topAccent);

    final lowerGlowPath = Path()
      ..moveTo(size.width, size.height * .77)
      ..quadraticBezierTo(size.width * .91, size.height * .87, size.width * .70, size.height * .93)
      ..quadraticBezierTo(size.width * .49, size.height * .99, size.width * .28, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(lowerGlowPath, bottomGlow);

    final lowerAccentPath = Path()
      ..moveTo(size.width, size.height * .86)
      ..quadraticBezierTo(size.width * .86, size.height * .95, size.width * .62, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(lowerAccentPath, bottomAccent);

    final wavePaint = Paint()
      ..color = orange.withOpacity(.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    for (var index = 0; index < 6; index++) {
      final y = size.height * .30 + (index * 12);
      final wavePath = Path()
        ..moveTo(0, y)
        ..cubicTo(size.width * .18, y - 9, size.width * .32, y + 8, size.width * .50, y)
        ..cubicTo(size.width * .67, y - 8, size.width * .84, y + 9, size.width, y - 1);
      canvas.drawPath(wavePath, wavePaint);
    }

    _drawBird(canvas, Offset(size.width * .18, size.height * .16), 9, orange.withOpacity(.28));
    _drawBird(canvas, Offset(size.width * .83, size.height * .13), 10, orange.withOpacity(.28));
    _drawBird(canvas, Offset(size.width * .89, size.height * .21), 7, orange.withOpacity(.22));
  }

  void _drawBird(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx - radius * .45, center.dy - radius * .60, center.dx, center.dy)
      ..quadraticBezierTo(center.dx + radius * .45, center.dy - radius * .60, center.dx + radius, center.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
