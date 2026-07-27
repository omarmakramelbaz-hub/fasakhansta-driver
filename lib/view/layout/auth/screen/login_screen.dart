import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/country_code_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_auth_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';
import '../controller/auth_controller.dart';
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
  @override
  void initState() {
    _country = CountryCodeMethods.getByCode('20');
    super.initState();
  }

  @override
  dispose() {
    _mobileEc.dispose();
    _passwordEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAuthAppBar(context),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(AppLocaleKey.welcomeBack.tr(), style: AppTextStyle.textD20B(context)),
                  const SizedBox(width: 10),
                ],
              ),
              const Gap(15),
              Text(AppLocaleKey.welcomePleaseEnterYourAccountDetails.tr(), style: AppTextStyle.textL18R(context)),
              const Gap(25),
              CustomFormField(
                controller: _mobileEc,
                validator: (v) => validatePhone(v, country: _country),
                country: _country,
                title: AppLocaleKey.mobileNumber.tr(),
                keyboardType: TextInputType.number,
              ),
              const Gap(25),
              CustomFormField(
                controller: _passwordEc,
                // validator: validatePassword,
                title: AppLocaleKey.password.tr(),
                isPassword: true,
              ),
              const Gap(25),
              // Text(
              //   AppLocaleKey.userType.tr(),
              // ),
              const Gap(10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: AppLocaleKey.login.tr(),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
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
              },
            ),
            const Gap(15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocaleKey.doNotHaveAccount.tr(), style: AppTextStyle.textD16M(context)),
                TextButton(
                  onPressed: () {
                    NavigatorMethods.pushNamed(
                      context,
                      RegisterAsDeliveryScreen.routeName,
                      arguments: RegisterAsDeliveryScreenArgs(
                        onSuccess: () {
                          setState(() {});
                        },
                      ),
                    );
                  },
                  child: Text(
                    AppLocaleKey.createAccount.tr(),
                    style: AppTextStyle.textD16M(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold, color: AppColor.mainAppColor(context)),
                  ),
                ),
              ],
            ),
            const Gap(15),
          ],
        ),
      ),
    );
  }
}
