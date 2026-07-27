import 'package:flutter/material.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/utils/general_const.dart';
import '../custom_image/custom_image.dart';

class CustomAuthAppBar extends PreferredSize {
  final double height;
  final double radius;
  final double elevation;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;
  final Color? appBarColor;
  final Color? shadowColor;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;
  final bool automaticallyImplyLeading;
  final BuildContext context;
  final BorderRadiusGeometry? borderRadius;
  CustomAuthAppBar(
    this.context, {
    super.key,
    this.height = 110,
    this.radius = genRadius,
    this.elevation = 0,
    this.leading,
    this.actions,
    this.title,
    this.appBarColor,
    this.centerTitle,
    this.bottom,
    this.leadingWidth,
    this.shadowColor,
    this.automaticallyImplyLeading = true,
    this.borderRadius,
  }) : super(
         preferredSize: Size.fromHeight(height),
         child: AppBar(
           elevation: elevation,
           backgroundColor: AppColor.whiteColor(context),
           toolbarHeight: height,
           automaticallyImplyLeading: automaticallyImplyLeading,
           shadowColor: shadowColor,
           centerTitle: centerTitle,
           title: title ?? const CustomImage(path: AppImages.appIcon, type: ImageType.asset, height: 60),
           leading: automaticallyImplyLeading && Navigator.canPop(context) && leading == null
               ? Center(
                   child: IconButton(
                     onPressed: Navigator.canPop(context)
                         ? () {
                             Navigator.pop(context);
                           }
                         : null,
                     icon: Icon(Icons.arrow_back_ios_rounded, color: AppColor.whiteColor(context)),
                   ),
                 )
               : leading,
           actions: actions ?? [const SizedBox(width: 16)],
           // [
           //   GestureDetector(
           //     onTap: () {
           //       NavigatorMethods.showAppBottomSheet(
           //           context, const ChangeLangBottomSheet());
           //     },
           //     child: const Padding(
           //       padding: EdgeInsets.symmetric(horizontal: 16),
           //       child: CustomImage(
           //         path: AppImages.languageIcon,
           //         type: ImageType.svg,
           //         height: 27,
           //       ),
           //     ),
           //   ),
           // ],
           leadingWidth: leadingWidth,
           // flexibleSpace: Container(
           //   decoration: BoxDecoration(
           //     borderRadius: borderRadius ??
           //         BorderRadius.vertical(
           //           bottom: Radius.circular(radius),
           //         ),
           //     gradient: LinearGradient(
           //       begin: Alignment.topCenter,
           //       end: Alignment.bottomCenter,
           //       colors: <Color>[
           //         AppColor.main2AppColor(context),
           //         AppColor.main2AppColor(context)
           //       ],
           //     ),
           //   ),
           // ),
           shape: RoundedRectangleBorder(
             borderRadius: borderRadius ?? BorderRadius.vertical(bottom: Radius.circular(radius)),
           ),
           bottom: bottom,
         ),
       );
}
