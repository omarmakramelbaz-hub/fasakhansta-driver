import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/country_code_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_auth_app_bar.dart';
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
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        widget.args.onSuccess.call();
      },
      child: Consumer<DelegateAccountController>(
        builder: (context, delegateAccountController, child) {
          bool hideInputs = delegateAccountController.setting?.delegateVendorSmallInfo == '1';
          return Scaffold(
            appBar: CustomAuthAppBar(context),
            body: ApiResponseWidget(
              apiResponse: delegateAccountController.settingResponse,
              onReload: () => delegateAccountController.getSetting(),
              isEmpty: delegateAccountController.setting == null,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(AppLocaleKey.startAsDeliveryMan.tr(), style: AppTextStyle.text20BS(context)),
                        ),
                        const SizedBox(height: 23),
                        CustomFormField(
                          controller: _nameQuadrilateralEc,
                          title: AppLocaleKey.nameQuadrilateral.tr(),
                          validator: validateNameFourthly,
                          focusNode: _nameQuadrilateralFocusNode,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_nationalIdFocusNode);
                          },
                        ),
                        hideInputs ? Container() : const SizedBox(height: 23),
                        hideInputs
                            ? Container()
                            : CustomFormField(
                                controller: _nationalIdEc,
                                title: AppLocaleKey.nationalId.tr(),
                                validator: validateNationalId,
                                keyboardType: TextInputType.number,
                                focusNode: _nationalIdFocusNode,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_drivingLicenseFocusNode);
                                },
                              ),
                        hideInputs ? Container() : const SizedBox(height: 23),
                        hideInputs
                            ? Container()
                            : CustomFormField(
                                controller: _drivingLicenseNumberEc,
                                title: AppLocaleKey.drivingLicenseNumber.tr(),
                                validator: validateEmptyField,
                                keyboardType: TextInputType.number,
                                focusNode: _drivingLicenseFocusNode,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_workAreaFocusNode);
                                },
                              ),

                        hideInputs ? Container() : const SizedBox(height: 23),

                        hideInputs
                            ? Container()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppLocaleKey.nationalIdImage.tr(), style: AppTextStyle.text16RS(context)),
                                  const SizedBox(width: 1),
                                  Text(AppLocaleKey.drivingLicense.tr(), style: AppTextStyle.text16RS(context)),
                                  const SizedBox(width: 1),
                                ],
                              ),
                        hideInputs ? Container() : const SizedBox(height: 15),
                        //========================== images (nationalIdImage, taxNumberImage ) ===========================
                        hideInputs
                            ? Container()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomImageContainer(
                                    image: _nationalIdImage,
                                    onSuccess: (v) {
                                      setState(() {
                                        _nationalIdImage = v;
                                      });
                                    },
                                  ),
                                  CustomImageContainer(
                                    image: _drivingLicenseImage,
                                    onSuccess: (v) {
                                      setState(() {
                                        _drivingLicenseImage = v;
                                      });
                                    },
                                  ),
                                ],
                              ),
                        hideInputs ? Container() : const SizedBox(height: 23),
                        hideInputs
                            ? Container()
                            : CustomFormField(
                                controller: _workAreaEc,
                                title: AppLocaleKey.workArea.tr(),
                                validator: validateEmptyField,
                                focusNode: _workAreaFocusNode,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_phoneNumberOneFocusNode);
                                },
                              ),
                        const SizedBox(height: 23),
                        CustomFormField(
                          validator: (v) => validatePhone(v, country: _country),
                          controller: _phoneNumberOneEc,
                          title: AppLocaleKey.firstPhoneNumber.tr(),
                          keyboardType: TextInputType.phone,
                          country: _country,
                          focusNode: _phoneNumberOneFocusNode,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_phoneNumberTwoFocusNode);
                          },
                        ),
                        hideInputs ? Container() : const SizedBox(height: 23),
                        hideInputs
                            ? Container()
                            : CustomFormField(
                                //    validator: (v) => validatePhone(v, country: _country),
                                controller: _phoneNumberTwoEc,
                                title: AppLocaleKey.secondPhoneNumber.tr(),
                                keyboardType: TextInputType.phone,
                                country: _country,
                                focusNode: _phoneNumberTwoFocusNode,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_vodafoneCashFocusNode);
                                },
                              ),
                        hideInputs ? Container() : const SizedBox(height: 23),
                        hideInputs
                            ? Container()
                            : CustomFormField(
                                validator: (v) => validateVCash(v, country: _country),
                                controller: _vodafoneCashNumber,
                                title: AppLocaleKey.vodafonCashNumber.tr(),
                                keyboardType: TextInputType.phone,
                                country: _country,
                                focusNode: _vodafoneCashFocusNode,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_emailFocusNode);
                                },
                              ),
                        const SizedBox(height: 23),
                        CustomFormField(
                          validator: validateEmptyField,
                          controller: _emailEc,
                          title: AppLocaleKey.email.tr(),
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocusNode,
                          onFieldSubmitted: (_) {},
                        ),
                        const SizedBox(height: 23),
                        ChangeNotifierProvider(
                          create: (context) => VendorAndDeliveryController(),
                          child: Builder(
                            builder: (context) {
                              return CustomButton(
                                text: AppLocaleKey.next.tr(),
                                onPressed: () {
                                  if (!hideInputs) {
                                    if (_nationalIdImage == null || _drivingLicenseImage == null) {
                                      CommonMethods.showError(message: AppLocaleKey.youMustAddAllImages.tr());
                                    }
                                  }
                                  if (hideInputs) {
                                    NavigatorMethods.pushNamed(
                                      context,
                                      ContractDeliveryScreen.routeName,
                                      arguments: ContractDeliveryArgs(
                                        name: _nameQuadrilateralEc.text,
                                        nationalId: _nationalIdEc.text.toString(),
                                        drivingLicenseNo: _drivingLicenseNumberEc.text,
                                        email: _emailEc.text,
                                        mobile: _phoneNumberOneEc.text,
                                        vodafoneCash: _vodafoneCashNumber.text,
                                        onConfirm: () {
                                          context.read<VendorAndDeliveryController>().deliveryRegister(
                                            fullName: _nameQuadrilateralEc.text,
                                            drivingLicenseImage: _drivingLicenseImage,
                                            nationalId: int.tryParse(_nationalIdEc.text.toString()),
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

                                  if (_formKey.currentState!.validate() &&
                                      _nationalIdImage != null &&
                                      _drivingLicenseImage != null) {
                                    NavigatorMethods.pushNamed(
                                      context,
                                      ContractDeliveryScreen.routeName,
                                      arguments: ContractDeliveryArgs(
                                        name: _nameQuadrilateralEc.text,
                                        nationalId: _nationalIdEc.text.toString(),
                                        drivingLicenseNo: _drivingLicenseNumberEc.text,
                                        email: _emailEc.text,
                                        mobile: _phoneNumberOneEc.text,
                                        vodafoneCash: _vodafoneCashNumber.text,
                                        onConfirm: () {
                                          context.read<VendorAndDeliveryController>().deliveryRegister(
                                            fullName: _nameQuadrilateralEc.text,
                                            drivingLicenseImage: _drivingLicenseImage!,
                                            nationalId: int.tryParse(_nationalIdEc.text.toString())!,
                                            drivingLicenseNo: _drivingLicenseNumberEc.text,
                                            nationalIdImage: _nationalIdImage!,
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
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
