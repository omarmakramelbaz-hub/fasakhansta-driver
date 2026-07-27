import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../../global/widget/custom_image_container.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/controller/auth_delegate_controller.dart';

class PersonalInformationDelegateScreen extends StatefulWidget {
  static const String routeName = 'PersonalInformationDelegateScreen';

  const PersonalInformationDelegateScreen({super.key});

  @override
  State<PersonalInformationDelegateScreen> createState() => _PersonalInformationDelegateScreenState();
}

class _PersonalInformationDelegateScreenState extends State<PersonalInformationDelegateScreen> with ValidationMixin {
  final _nameEc = TextEditingController();
  final _mobileEc = TextEditingController();
  final _emailEc = TextEditingController();

  // int? _country;

  final delegateFees = TextEditingController();
  String? delegateAddress;

  File? _delegateImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false).initialProfile();
      Provider.of<AuthController>(context, listen: false).getProfile().then((value) {
        _nameEc.text = context.read<AuthController>().profile?.name ?? '';
        _emailEc.text = context.read<AuthController>().profile?.email ?? '';
        _mobileEc.text = context.read<AuthController>().profile?.mobile ?? '';
        delegateFees.text = '${context.read<AuthController>().profile?.delegateFees.toString() ?? ""} %';
      });
    });
    // if (Provider.of<AuthController>(context, listen: false)
    //         .profile
    //         ?.areaTitle ==
    //     null) {
    //   delegateAddress = Provider.of<AuthController>(context, listen: false)
    //       .profile
    //       ?.userAddresses
    //       ?.first
    //       .cityName;
    // } else {
    // delegateAddress = Provider.of<AuthController>(context, listen: false)
    //         .profile
    //         ?.areaTitle ??
    //     "";
    // }
  }

  @override
  void dispose() {
    super.dispose();
    _nameEc.dispose();
    _emailEc.dispose();
    _mobileEc.dispose();
    delegateFees.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColor.blackColor(context)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            appBarColor: AppColor.whiteColor(context),
            context,
            height: 80,
            centerTitle: false,
            leadingPadding: 40,
            title: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(AppLocaleKey.personalInformation.tr(), style: AppTextStyle.text20BS(context)),
            ),
          ),
          body: ApiResponseWidget(
            apiResponse: authController.profileResponse,
            onReload: () => authController.getProfile(),
            isEmpty: authController.profile == null,
            child: PageContainer(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: AppColor.whiteColor(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(34),
                          topRight: Radius.circular(34),
                        ),
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
                                InkWell(
                                  onTap: () {},
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColor.mainAppColor(context).withOpacity(0.3),
                                    child: CustomImage(
                                      height: 60,
                                      width: 60,
                                      radius: 30,
                                      path: authController.profile?.photoProfile ?? '',
                                      type: ImageType.network,
                                      fit: BoxFit.fitHeight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(authController.profile?.name ?? '', style: AppTextStyle.text18BS(context)),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const CustomImage(path: AppImages.egyptIcon, type: ImageType.svg),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.watch<AuthController>().profile?.areaTitle ?? '',
                                          style: AppTextStyle.text18RS(context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // GestureDetector(
                                //   onTap: () {
                                //     context
                                //         .read<AuthDelegateController>()
                                //         .updateDelegateInfo(
                                //           name: _nameEc.text,
                                //           email: _emailEc.text,
                                //           id: _country ?? 1,
                                //           onSuccess: () {
                                //              Navigator.pop(context);
                                //             authController.getProfile();
                                //           },
                                //         );
                                //   },
                                //   child: Row(
                                //     children: [
                                //       SvgPicture.asset(AppImages.editIcon),
                                //       const SizedBox(
                                //         width: 8,
                                //       ),
                                //       Text(
                                //         AppLocaleKey.save.tr(),
                                //         style: AppTextStyle.text16RG(context),
                                //       ),
                                //     ],
                                //   ),
                                // )
                              ],
                            ),
                          ),
                          const SizedBox(height: 29),
                          Divider(color: AppColor.greyColor(context).withOpacity(0.2), height: 2),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomFormField(controller: _nameEc, title: AppLocaleKey.name.tr()),
                                const SizedBox(height: 24),
                                Text(AppLocaleKey.logoImage.tr()),
                                const SizedBox(height: 10),
                                CustomImageContainer(
                                  bgImage: authController.profile?.photoProfile,
                                  image: _delegateImage,
                                  onSuccess: (v) {
                                    setState(() {
                                      _delegateImage = v;
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                                CustomFormField(controller: _mobileEc, title: AppLocaleKey.phone.tr(), readOnly: true),
                                const SizedBox(height: 24),
                                CustomFormField(controller: _emailEc, title: AppLocaleKey.email.tr()),
                                const SizedBox(height: 24),
                                CustomFormField(
                                  readOnly: true,
                                  controller: delegateFees,
                                  title: AppLocaleKey.delegateSubscriptionFee.tr(),
                                ),

                                // const SizedBox(
                                //   height: 24,
                                // ),
                                // Consumer<AuthDelegateController>(
                                //   builder: (BuildContext context,
                                //           authDelegateController, _) =>
                                //       CustomSingleSelect(
                                //           validator: validateEmptyDropDown,
                                //           apiResponse:
                                //               authDelegateController.areaResponse,
                                //           onReload: () =>
                                //               authDelegateController.getArea(),
                                //           value: _country ??
                                //               (authDelegateController
                                //                       .area.isNotEmpty
                                //                   ? authController.areas[0].id ?? 0
                                //                   : 0),
                                //           onChanged: (value) {
                                //             setState(
                                //               () {
                                //                 _country = value;
                                //               },
                                //             );
                                //           },
                                //           title: AppLocaleKey.country.tr(),
                                //           items: authDelegateController.area
                                //               .map((e) => CustomSelectItem(
                                //                   value: e.id, name: e.title ?? ""))
                                //               .toList()),
                                // ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(20.0),
            child: CustomButton(
              text: AppLocaleKey.saveChanges.tr(),
              onPressed: () {
                // if (_delegateImage != null) {
                //   context.read<AuthDelegateController>().updateDelegatePhoto(
                //       photoProfile: _delegateImage, onSuccess: () {});
                // }
                context.read<AuthDelegateController>().updateDelegateInfo(
                  name: _nameEc.text,
                  email: _emailEc.text,
                  // id: _country ?? 1,
                  photoProfile: _delegateImage,
                  onSuccess: () {
                    Navigator.pop(context);
                    authController.getProfile();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
