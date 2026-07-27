import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/locale/app_locale_key.dart';
import '../../../helpers/networking/notification_helper.dart';
import '../../../helpers/pusher_service/pusher_controller.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../../helpers/utils/date_methods.dart';
import '../../../helpers/utils/navigator_methods.dart';
import '../../custom_widgets/custom_image/custom_image.dart';
import '../../custom_widgets/dotted_decoration/dotted_decoration.dart';
import '../../layout/order/model/delegate_order_model.dart';
import '../../layout/order/screen/order_details_delegate_screen.dart';

class OrderDelegateWidget extends StatefulWidget {
  const OrderDelegateWidget({
    super.key,
    this.isDelivered,
    this.orderItem,
    this.order,
    required this.orderId,
    this.onsuccess,
  });
  final bool? isDelivered;
  final List<DelegateItems>? orderItem;
  final DelegateOrdersModel? order;
  final int orderId;
  final VoidCallback? onsuccess;

  @override
  State<OrderDelegateWidget> createState() => _OrderDelegateWidgetState();
}

class _OrderDelegateWidgetState extends State<OrderDelegateWidget> {
  String status = 'pending';
  int? pusherDelegateId;
  late PusherController _pusherController;
  // Saved reference
  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    status = widget.order?.status ?? 'pending';
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      var jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          status = jsonData['order']['status']?.toString() ?? '';
          pusherDelegateId = int.parse(jsonData['order']['delegate_id']);

          log('================> $pusherDelegateId');
        });
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void updateStatus(String newStatus) {
    setState(() {
      status = newStatus;
      log('Status updated to =============================> $newStatus <=======================');
    });
  }

  @override
  Widget build(BuildContext context) {
    // final status = widget.order?.status;
    final bool isShipped = widget.order?.type == 'shipping';
    final String fromAddress;
    final String toAddress;
    if (isShipped) {
      fromAddress = widget.order?.fromAddress ?? '';
      toAddress = widget.order?.toAddress ?? '';
    } else {
      fromAddress = widget.order?.resturantLocation ?? '';
      toAddress = "${widget.order?.userAddress?.addressName ?? ""} ,${widget.order?.userAddress?.streetName ?? ""}";
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
                arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: widget.orderId),
              );
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      CustomImage(
                        path: widget.order?.userLogo == null || widget.order?.userLogo == ''
                            ? AppImages.userIcon
                            : widget.order?.userLogo ?? '',
                        type: widget.order?.userLogo == null || widget.order?.userLogo == ''
                            ? ImageType.svg
                            : ImageType.network,
                        height: 50,
                        width: 50,
                        radius: 25,
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
                                  child: Text(widget.order?.userName ?? '', style: AppTextStyle.textD16M(context)),
                                ),
                                const SizedBox(width: 20),
                                const CustomImage(path: AppImages.infoIcon, type: ImageType.svg),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLocaleKey.orderNumber.tr().replaceAll('{}', widget.order?.orderNo ?? ''),
                              style: AppTextStyle.text14RG(context),
                            ),
                          ],
                        ),
                      ),
                      // const Expanded(child: SizedBox()),
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
                              child: Text(
                                isShipped ? AppLocaleKey.shippingOrder.tr() : AppLocaleKey.restaurantOrder.tr(),
                              ),
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
                                DateMethods.formatToDate(widget.order?.createdAt?.toString() ?? ''),
                                style: AppTextStyle.text14RG(context),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                DateMethods.formatToTime(widget.order?.createdAt?.toString() ?? ''),
                                style: AppTextStyle.text14RG(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                //===============================================================================
                //================================ Location =====================================
                Container(decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5])),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            child: Text(AppLocaleKey.receivingAddress.tr(), style: AppTextStyle.text16MS(context)),
                          ),
                          const SizedBox(height: 10),
                          //Location
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomImage(path: AppImages.locationIcon, type: ImageType.svg),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    fromAddress,
                                    // "${order?.delegateItems?.first.resturantCityName ?? ""}\t- \t${order?.userAddress?.streetName ?? ""}\t- \t${order?.userAddress?.addressName ?? ""}",
                                    style: AppTextStyle.text16MG(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            child: Text(AppLocaleKey.deliveryLocation.tr(), style: AppTextStyle.text16MS(context)),
                          ),
                          const SizedBox(height: 10),
                          //Location
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomImage(path: AppImages.locationIcon, type: ImageType.svg),
                                const SizedBox(width: 5),
                                Expanded(child: Text(toAddress, style: AppTextStyle.text16MG(context))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(thickness: 0.2, color: AppColor.textFormColor(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocaleKey.deliveryCost.tr(), style: AppTextStyle.text18BS(context)),
                      Text(
                        AppLocaleKey.pound.tr().replaceAll('{}', '${widget.order?.deliveryPrice?.toStringAsFixed(0)} '),
                        style: AppTextStyle.text18BS(context),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 0.2, color: AppColor.textFormColor(context)),
                widget.order?.paymentType != 'cash'
                    ? Container()
                    : isShipped
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocaleKey.orderCost.tr(), style: AppTextStyle.text18BS(context)),
                            Text(
                              AppLocaleKey.pound.tr().replaceAll(
                                '{}',
                                '${widget.order?.grandTotal?.toStringAsFixed(0)} ',
                              ),
                              style: AppTextStyle.text18BS(context),
                            ),
                          ],
                        ),
                      ),
                Divider(thickness: 0.2, color: AppColor.textFormColor(context)),
              ],
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 23),
          //   child: _buildActionButton(),
          // )
        ],
      ),
    );
  }

  // Widget _buildActionButton() {
  //   return ChangeNotifierProvider(
  //     create: (context) => DelegateOrdersController(),
  //     child: Consumer<DelegateOrdersController>(
  //       builder: (context, controller, _) {
  //         if (widget.isDelivered == true) {
  //           return _buildDeliveredButtons(controller);
  //         }
  //         return _buildPendingButtons(controller);
  //       },
  //     ),
  //   );
  // }

  // Widget _buildDeliveredButtons(DelegateOrdersController controller) {
  //   switch (status) {
  //     case "shipped":
  //       return _actionButton(
  //         text: AppLocaleKey.deliverOrderToCustomer.tr(),
  //         color: AppColor.greenColor(context),
  //         onPressed: () => controller.completeOrderDelegate(
  //           orderId: widget.orderId,
  //           onSuccess: widget.onsuccess!,
  //         ),
  //       );
  //     case "completed":
  //       return _actionButton(
  //         text: AppLocaleKey.deliveredOrderToCustomer.tr(),
  //         color: AppColor.lightGreyColor(context),
  //         style: AppTextStyle.text18BS(context),
  //       );
  //     case "accepted":
  //       return _actionButton(
  //         text: AppLocaleKey.receivedOrderFromResturant.tr(),
  //         onPressed: widget.onsuccess,
  //       );
  //     default:
  //       return const SizedBox();
  //   }
  // }

  // Widget _buildPendingButtons(DelegateOrdersController controller) {
  //   bool isPending = status == "pending" || status == "another_delegate";
  //   bool hasNoStatus = widget.order?.delegateHasStatus == null;

  //   if (isPending && hasNoStatus) {
  //     return Row(
  //       children: [
  //         Expanded(
  //           flex: 2,
  //           child: _actionButton(
  //             text: AppLocaleKey.accept.tr(),
  //             onPressed: () {
  //               SoundNotification.instance.stopSound();
  //               controller.acceptOrDeclineOrder(
  //                 orderId: widget.orderId,
  //                 status: "accept",
  //                 onSuccess: widget.onsuccess!,
  //               );
  //             },
  //           ),
  //         ),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: _actionButton(
  //             text: AppLocaleKey.reject.tr(),
  //             color: const Color(0xffEEEEEE),
  //             style: AppTextStyle.text18MS(context),
  //             onPressed: () {
  //               SoundNotification.instance.stopSound();
  //               controller.acceptOrDeclineOrder(
  //                 orderId: widget.orderId,
  //                 status: "declined",
  //                 onSuccess: widget.onsuccess!,
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     );
  //   }

  //   if (isPending && !hasNoStatus) {
  //     return _actionButton(
  //       text: AppLocaleKey.waitToBeAccepted.tr(),
  //       onPressed: () {},
  //     );
  //   }

  //   return const SizedBox();
  // }

  // Widget _actionButton({
  //   required String text,
  //   VoidCallback? onPressed,
  //   Color? color,
  //   TextStyle? style,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: CustomButton(
  //       text: text,
  //       onPressed: onPressed,
  //       color: color,
  //       style: style,
  //     ),
  //   );
  // }
}
