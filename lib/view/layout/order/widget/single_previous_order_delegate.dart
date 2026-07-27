import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/dotted_decoration/dotted_decoration.dart';
import '../model/delegate_order_model.dart';
import '../screen/order_details_delegate_screen.dart';
import 'order_header_widget.dart';

class SinglePreviousDelegateOrderItem extends StatelessWidget {
  const SinglePreviousDelegateOrderItem({super.key, this.items, this.order, required this.orderId});

  final List<DelegateItems>? items;
  final DelegateOrdersModel? order;
  final int orderId;

  @override
  Widget build(BuildContext context) {
    // final delegateId = order?.delegateId;
    // final currentUserId = context.read<AuthController>().profile?.id;
    // final isCurrentUserDelegate = delegateId == currentUserId;

    // final isOutRestaurantAndCashPayment =
    //     order?.delegateFromOut == "out_resturant" &&
    //         order?.paymentType == "cash";

    // final isPaidBefore = order?.hasTransferedBefore == 0;

    final bool isShipped = order?.type == 'shipping';
    final String fromAddress;
    final String toAddress;
    if (isShipped) {
      fromAddress = order?.fromAddress ?? '';
      toAddress = order?.toAddress ?? '';
    } else {
      fromAddress = " ${order?.userAddress?.cityName ?? ""} ,${order?.userAddress?.streetName ?? ""}";
      if (order?.delegateItems?.isNotEmpty == true) {
        toAddress = "${order?.resturantLocation ?? ""} ,${order?.delegateItems?.first.resturantCityName ?? ""}";
      } else {
        toAddress = " ${order?.resturantLocation ?? ""} ";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.textFormBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              SoundNotification.instance.stopSound();
              NavigatorMethods.pushNamed(
                context,
                OrderDetailsDelegateScreen.routeName,
                arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: orderId),
              );
            },
            child: Column(
              children: [
                _buildOrderHeader(context, isShipped),
                _buildOrderDetails(context, isShipped, fromAddress, toAddress),
                _buildOrderCost(context),
              ],
            ),
          ),
          // _buildBottomActions(context, isCurrentUserDelegate,
          //     isOutRestaurantAndCashPayment, isPaidBefore),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, bool isShipped) {
    return OrderHeaderWidget(order: order, isShipped: isShipped);
  }

  Widget _buildOrderDetails(BuildContext context, bool isShipped, String fromAddress, String toAddress) {
    return Column(
      children: [
        Container(decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5])),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationInfo(context, AppLocaleKey.receivingAddress.tr(), fromAddress, isShipped),
            _buildLocationInfo(context, AppLocaleKey.deliveryLocation.tr(), toAddress, isShipped),
          ],
        ),
        const SizedBox(height: 10),
        Divider(thickness: 0.2, color: AppColor.textFormColor(context)),
      ],
    );
  }

  Widget _buildLocationInfo(BuildContext context, String label, String? location, bool isShipped) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Text(label, style: AppTextStyle.text16MS(context)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomImage(path: AppImages.locationIcon, type: ImageType.svg),
                const SizedBox(width: 5),
                Expanded(child: Text(location ?? '', style: AppTextStyle.text16MG(context), maxLines: 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCost(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocaleKey.deliveryCost.tr(), style: AppTextStyle.text18BS(context)),
          Text(
            AppLocaleKey.pound.tr().replaceAll('{}', '${order?.deliveryPrice?.toStringAsFixed(2)} '),
            style: AppTextStyle.text18BS(context),
          ),
        ],
      ),
    );
  }

  // Widget _buildBottomActions(
  //      bool isCurrentUserDelegate, bool isOutRestaurantAndCashPayment, bool isPaidBefore) {
  //   if (isCurrentUserDelegate && isOutRestaurantAndCashPayment && isPaidBefore) {
  //     return _buildDefaultAction();
  //   } else {
  //     return _buildDefaultAction();
  //   }
  // }
  //
  // Widget _buildCashPaymentActions() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 5),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           flex: 2,
  //           child: Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 23),
  //             child: CustomButton(
  //               color: AppColor.lightGreyColor(context),
  //               text: AppLocaleKey.deliveredToCustomer.tr(),
  //               style: AppTextStyle.text16BS(context),
  //               onPressed: () {
  //                 log(order?.delegateId.toString() ?? '');
  //                 log(context.read<AuthController>().profile?.id.toString() ??
  //                     '');
  //               },
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           flex: 1,
  //           child: ChangeNotifierProvider(
  //             create: (context) => DelegateOrdersController(),
  //             child: Consumer<DelegateOrdersController>(
  //               builder: (context, delegateOrderController, _) {
  //                 return CustomButton(
  //                   style: AppTextStyle.text16BW(context),
  //                   text: AppLocaleKey.payToDelegate.tr(),
  //                   onPressed: () {
  //                     delegateOrderController.delegateTransferOrderPrice(
  //                       orderId: order?.id ?? 0,
  //                       onSuccess: () {},
  //                     );
  //                   },
  //                 );
  //               },
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildDefaultAction() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 23),
  //     child: CustomButton(
  //       color: AppColor.lightGreyColor(),
  //       text: AppLocaleKey.deliveredOrderToCustomer.tr(),
  //       style: AppTextStyle.text18BS(context),
  //     ),
  //   );
  // }
}
