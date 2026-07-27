import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../helpers/locale/app_locale_key.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../custom_widgets/custom_image/custom_image.dart';
import '../../layout/order/model/delegate_order_model.dart';

class OrderDelegateDetailsItemWidget extends StatelessWidget {
  const OrderDelegateDetailsItemWidget({super.key, required this.items});

  final DelegateItems? items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
      child: Row(
        children: [
          CustomImage(
            height: 83,
            width: 120,
            radius: 12,
            path: items?.resturantProduct?.productImage ?? '',
            type: ImageType.network,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: items?.resturantProduct?.productName, style: AppTextStyle.text16RS(context)),
                  const TextSpan(text: '\n\n'),
                  TextSpan(
                    text: AppLocaleKey.pound.tr().replaceAll('{}', '${items?.price}'),
                    style: AppTextStyle.text16RG(context),
                  ),
                  const TextSpan(text: '\n'),
                  items?.productFeatureName != null
                      ? TextSpan(
                          text: AppLocaleKey.quantity.tr().replaceAll('{}', ''),
                          style: AppTextStyle.text16RG(context),
                        )
                      : const TextSpan(text: ''),
                  TextSpan(
                    text: items?.productFeatureName == 'kilo'
                        ? AppLocaleKey.kilo.tr()
                        : items?.productFeatureName == 'quarter'
                        ? AppLocaleKey.quarter.tr()
                        : items?.productFeatureName == 'half'
                        ? AppLocaleKey.half.tr()
                        : '',
                    style: AppTextStyle.text16RG(context),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 26,
            width: 45,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: AppColor.lightGreyColor(context)),
            child: Center(
              child: Text(
                '${items?.qty}',
                style: AppTextStyle.text18BS(context).copyWith(height: context.locale.languageCode == 'ar' ? 1.7 : 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
