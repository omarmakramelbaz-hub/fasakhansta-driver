import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../model/notifications_model.dart';

class NotificationDelegateWidget extends StatelessWidget {
  final NotificationsModel notification;
  final int orderId;
  final int notificationType;
  const NotificationDelegateWidget({
    super.key,
    required this.notification,
    required this.orderId,
    required this.notificationType,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        SoundNotification.instance.stopSound();
        log('tapped');
        notificationType == 1
            ? NavigatorMethods.pushNamed(
                context,
                OrderDetailsDelegateScreen.routeName,
                arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: orderId),
              )
            : notificationType == 3
            ? NavigatorMethods.pushNamed(context, WalletScreen.routeName)
            : null;

        // NavigatorMethods.pushNamed(
        //     context, OrderDetailsDelegateScreen.routeName,
        //     arguments: OrderDetailsDelegateScreenArgs(orderId: orderId));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomImage(
                path: notification.data?.logo ?? '',
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.width * 0.1,
                radius: 25,
                fit: BoxFit.cover,
                type: ImageType.network,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(notification.data?.title ?? '', style: AppTextStyle.text16MS(context))),
              SvgPicture.asset(AppImages.timeIcon),
              const SizedBox(width: 10),
              Text(
                DateMethods.timeAgo(notification.createdAt ?? AppLocaleKey.now.tr(), context),
                style: AppTextStyle.text16RM(context),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 5,
              //   ),
              //   child: CircleAvatar(
              //     backgroundColor: AppColor.mainAppColor(context),
              //     radius: 6,
              //   ),
              // ),
              const SizedBox(width: 10),
              Expanded(child: Text(notification.data?.text ?? '', style: AppTextStyle.text16MS(context))),
            ],
          ),
        ],
      ),
    );
  }
}
