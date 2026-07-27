import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../global/chat/screen/admin_chat_screen.dart';
import '../../auth/bottom_sheet/change_lang_bottom_sheet.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/screen/login_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/my_account_controller.dart';
import '../widget/change_phone_number.dart';
import '../widget/setting_button_widget.dart';
import 'change_password_delegate_screen.dart';
import 'contact_us_screen.dart';
import 'delegate_reports_screen.dart';
import 'personal_information_delgate_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';

class MyAccountDelegateScreen extends StatefulWidget {
  const MyAccountDelegateScreen({super.key});

  @override
  State<MyAccountDelegateScreen> createState() => _MyAccountDelegateScreenState();
}

@override
class _MyAccountDelegateScreenState extends State<MyAccountDelegateScreen> {
  bool isSwitched = true;
  String? delegateAddress;
  final formKey = GlobalKey<FormState>();
  final codeEC = TextEditingController();
  @override
  initState() {
    delegateAddress = Provider.of<AuthController>(context, listen: false).profile?.areaTitle ?? '';
    super.initState();
  }

  @override
  void dispose() {
    codeEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<AuthController>(context).profile;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            const SizedBox(height: 32),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: AppColor.whiteColor(context),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(34), topRight: Radius.circular(34)),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.greyColor(context).withOpacity(0.2),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        CustomImage(
                          path:
                              Provider.of<AuthController>(context).profile?.photoProfile == null ||
                                  Provider.of<AuthController>(context).profile?.photoProfile == ''
                              ? AppImages.userIcon
                              : Provider.of<AuthController>(context).profile?.photoProfile ?? '',
                          type:
                              Provider.of<AuthController>(context).profile?.photoProfile == null ||
                                  Provider.of<AuthController>(context).profile?.photoProfile == ''
                              ? ImageType.svg
                              : ImageType.network,
                          height: 56,
                          width: 56,
                          radius: 25,
                          fit: BoxFit.fitHeight,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  Provider.of<AuthController>(context).profile?.name ?? '',
                                  style: AppTextStyle.textD18M(context),
                                ),
                                const SizedBox(width: 10),
                                if (profile?.email == null || profile?.areaId == null)
                                  SvgPicture.asset(AppImages.onlineIcon),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SvgPicture.asset(AppImages.flagIcon),
                                const SizedBox(width: 10),
                                Text(
                                  context.watch<AuthController>().profile?.areaTitle ?? '',
                                  style: AppTextStyle.textL18R(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 29),
                  Divider(color: AppColor.greyColor(context).withOpacity(0.2), height: 2),

                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.personalInformation.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, PersonalInformationDelegateScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.changePhoneNumber.tr(),
                    onTap: () {
                      NavigatorMethods.showAppBottomSheet(
                        enableDrag: true,
                        isScrollControlled: true,
                        context,
                        const ChangePhoneNumberBottomSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.changePassword.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, ChangePasswordDelegateScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 32),

                  SettingButton(
                    title: AppLocaleKey.wallet.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, WalletScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.changeLanguage.tr(),
                    onTap: () {
                      NavigatorMethods.showAppBottomSheet(context, const ChangeLangBottomSheet());
                    },
                  ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.myReports.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, DelegateReportsScreen.routeName);
                    },
                  ),
                  // const SizedBox(
                  //   height: 32,
                  // ),
                  // SettingButton(
                  //   title: AppLocaleKey.help.tr(),
                  //   onTap: () {
                  //     NavigatorMethods.pushNamed(
                  //       context,
                  //       HelpScreen.routeName,
                  //     );
                  //   },
                  // ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.termsAndConditions.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, TermsAndConditionsScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.privacyPolicy.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, PrivacyPolicyScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 32),
                  SettingButton(
                    title: AppLocaleKey.connectWithUs.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(context, ContactUsScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 32),
                  ChangeNotifierProvider(
                    create: (context) => MyAccountController()
                      ..initialSetting()
                      ..getSetting(),
                    child: Consumer<MyAccountController>(
                      builder: (context, myAccountController, _) {
                        return SettingButton(
                          title: AppLocaleKey.connectSupport.tr(),
                          onTap: () {
                            NavigatorMethods.pushNamed(
                              context,
                              AdminChatScreen.routeName,
                              arguments: AdminChatScreenArgs(
                                senderId: context.read<AuthController>().profile!.id!.toString(),
                                receiverId: myAccountController.setting?.adminId.toString() ?? '1',
                                receiverDeviceToken: myAccountController.setting?.adminDeviceToken ?? '',
                                receiverName: 'admin',
                                senderName: context.read<AuthController>().profile?.name ?? '',
                                senderDeviceToken: '',
                                accountType: '',
                                isToVendor: false,
                                vendorDeviceToken: '',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  SettingButton(
                    title: AppLocaleKey.deleteAccount.tr(),
                    onTap: () {
                      CommonMethods.showChooseDialog(
                        context,
                        onPressed: () {
                          Navigator.pop(context);
                          NavigatorMethods.showAppDialog(
                            context,
                            Dialog(
                              elevation: 5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              child: Builder(
                                builder: (context) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColor.whiteColor(context),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    height: 200,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            CustomFormField(
                                              title: AppLocaleKey.enterVerificationCode.tr(),
                                              controller: codeEC,
                                            ),
                                            const SizedBox(height: 10),
                                            CustomButton(
                                              text: AppLocaleKey.deleteAccount.tr(),
                                              onPressed: () {
                                                context.read<AuthController>().deleteAccount(
                                                  mobileCode: codeEC.text,
                                                  onSuccess: () {
                                                    NavigatorMethods.pushNamed(context, LoginScreen.routeName);
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        message: AppLocaleKey.didYouWantToDeleteThisAccount.tr(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 31),
                    child: CustomButton(
                      onPressed: () {
                        CommonMethods.showChooseDialog(
                          context,
                          title: tr(AppLocaleKey.doYouWantToLogOut),
                          message: '',
                          onPressed: () {
                            context.read<AuthController>().logout(
                              onSuccess: () {
                                NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName);
                              },
                            );
                          },
                        );
                      },
                      prefixIcon: CustomImage(
                        path: AppImages.logOutIcon,
                        type: ImageType.svg,
                        color: AppColor.whiteColor(context),
                      ),
                      gap: 15,
                      text: AppLocaleKey.logOut.tr(),
                    ),
                  ),

                  // GestureDetector(
                  //   onTap: () {
                  // CommonMethods.showChooseDialog(
                  //   context,
                  //   title: tr(AppLocaleKey.logOut),
                  //   message: tr(AppLocaleKey.doYouWantToLogOut),
                  //   onPressed: () {
                  //     context.read<AuthController>().logout(
                  //       onSuccess: () {
                  //         NavigatorMethods.pushNamedAndRemoveUntil(
                  //             context, LoginScreen.routeName);
                  //       },
                  //     );
                  //   },
                  // );
                  //   },
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       ///      SvgPicture.asset(AppImages.arrowIcon),
                  //       const SizedBox(
                  //         width: 15,
                  //       ),

                  //       SvgPicture.asset(AppImages.logOutIcon),
                  //       const SizedBox(width: 10),
                  //       Text(

                  //         style: AppTextStyle.text18BS(context)
                  //             .copyWith(color: AppColor.redColor(context)),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 130),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
