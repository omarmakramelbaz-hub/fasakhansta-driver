import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../model/delegate_order_model.dart';

class OrderHeaderWidget extends StatelessWidget {
  final DelegateOrdersModel? order;
  final bool isShipped;
  const OrderHeaderWidget({super.key, this.order, required this.isShipped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          CustomImage(
            path: order?.userLogo == null || order?.userLogo == '' ? AppImages.userIcon : order?.userLogo ?? '',
            type: order?.userLogo == null || order?.userLogo == '' ? ImageType.svg : ImageType.network,
            height: 40,
            width: 40,
            radius: 22,
            fit: BoxFit.fill,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order?.userName ?? '',
                        style: AppTextStyle.textD16M(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const CustomImage(path: AppImages.infoIcon, type: ImageType.svg),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocaleKey.orderNumber.tr().replaceAll('{}', '${order?.orderNo ?? 0}'),
                  style: AppTextStyle.text14RG(context),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColor.lightMainAppColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                  child: Text(isShipped ? AppLocaleKey.shippingOrder.tr() : AppLocaleKey.restaurantOrder.tr()),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(Icons.access_time, size: 17, color: AppColor.greyColor(context)),
                  ),
                  Text(
                    DateMethods.formatToDate(order?.createdAt?.toString() ?? ''),
                    style: AppTextStyle.text14RG(context),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    DateMethods.formatToTime(order?.createdAt?.toString() ?? ''),
                    style: AppTextStyle.text14RG(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
