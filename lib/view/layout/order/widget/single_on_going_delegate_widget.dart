import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/dotted_decoration/dotted_decoration.dart';
import '../controller/delegate_order_controller.dart';
import '../model/delegate_order_model.dart';
import '../screen/order_details_delegate_screen.dart';
import 'order_header_widget.dart';

class SingleOnGoingDelegateWidget extends StatefulWidget {
  const SingleOnGoingDelegateWidget({super.key, this.items, this.order, this.onSuccess});
  final List<DelegateItems>? items;
  final DelegateOrdersModel? order;
  final VoidCallback? onSuccess;

  @override
  State<SingleOnGoingDelegateWidget> createState() => _SingleOnGoingDelegateWidgetState();
}

class _SingleOnGoingDelegateWidgetState extends State<SingleOnGoingDelegateWidget> {
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
    return Consumer<DelegateOrdersController>(
      builder: (context, delegateOrderController, _) {
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
                    arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: widget.order?.id ?? 0),
                  );
                },
                child: Column(
                  children: [
                    OrderHeaderWidget(order: widget.order, isShipped: isShipped),
                    //===============================================================================
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
                                      child: Text(fromAddress, style: AppTextStyle.text16MG(context), maxLines: 2),
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
                                    Expanded(
                                      child: Text(toAddress, style: AppTextStyle.text16MG(context), maxLines: 2),
                                    ),
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
                            AppLocaleKey.pound.tr().replaceAll('{}', '${widget.order?.deliveryPrice} '),
                            style: AppTextStyle.text18BS(context),
                          ),
                        ],
                      ),
                    ),
                    isShipped ? const SizedBox() : Divider(thickness: 0.2, color: AppColor.textFormColor(context)),
                    widget.order?.paymentType != 'cash'
                        ? const SizedBox()
                        : isShipped
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppLocaleKey.orderCost.tr(), style: AppTextStyle.text18BS(context)),
                                Text(
                                  AppLocaleKey.pound.tr().replaceAll('{}', '${widget.order?.grandTotal} '),
                                  style: AppTextStyle.text18BS(context),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              // status == "pending"
              //     ? Padding(
              //         padding: const EdgeInsets.all(16.0),
              //         child: Row(
              //           children: [
              //             Expanded(
              //                 flex: 2,
              //                 child: CustomButton(
              //                   text: AppLocaleKey.accept.tr(),
              //                   onPressed: () {
              //                     delegateOrderController.acceptOrDeclineOrder(
              //                         orderId: delegateOrderController
              //                                 .delegateSingleOrder!.id ??
              //                             0,
              //                         status: "accept",
              //                         onSuccess: () {
              //                           delegateOrderController
              //                               .getDelegateSingleOrder(
              //                                   id: delegateOrderController
              //                                           .delegateSingleOrder!
              //                                           .id ??
              //                                       0);
              //                         });
              //                   },
              //                 )),
              //             const SizedBox(
              //               width: 16,
              //             ),
              //             Expanded(
              //               child: CustomButton(
              //                 color: const Color(0xffEEEEEE),
              //                 text: AppLocaleKey.reject.tr(),
              //                 style: AppTextStyle.text18MS(context),
              //                 onPressed: () {
              //                   delegateOrderController.acceptOrDeclineOrder(
              //                       orderId: delegateOrderController
              //                               .delegateSingleOrder!.id ??
              //                           0,
              //                       status: "declined",
              //                       onSuccess: () {
              //                         delegateOrderController
              //                             .getDelegateSingleOrder(
              //                                 id: delegateOrderController
              //                                         .delegateSingleOrder!.id ??
              //                                     0);
              //                       });
              //                 },
              //               ),
              //             ),
              //           ],
              //         ),
              //       )
              //     : status == "accepted"
              //         ? widget.order?.delegateId ==
              //                 context.read<AuthController>().profile?.id
              //             ? Padding(
              //                 padding: const EdgeInsets.all(16.0),
              //                 child: CustomButton(
              //                   text:
              //                       AppLocaleKey.receivedOrderFromResturant.tr(),
              //                   onPressed: () {
              //                     delegateOrderController.getDelegateSingleOrder(
              //                         id: widget.order!.id ?? 0);
              //                   },
              //                 ),
              //               )
              //             : status == "shipped"
              //                 ? Padding(
              //                     padding: const EdgeInsets.all(16.0),
              //                     child: CustomButton(
              //                       onPressed: () {
              //                         delegateOrderController
              //                             .completeOrderDelegate(
              //                                 orderId: delegateOrderController
              //                                         .delegateSingleOrder!.id ??
              //                                     0,
              //                                 onSuccess: () {
              //                                   widget.onSuccess!.call();
              //                                 });
              //                       },
              //                       text:
              //                           AppLocaleKey.deliverOrderToCustomer.tr(),
              //                       color: AppColor.greenColor(context),
              //                     ),
              //                   )
              //                 : status == "completed"
              //                     ? Padding(
              //                         padding: const EdgeInsets.symmetric(
              //                             horizontal: 16, vertical: 23),
              //                         child: CustomButton(
              //                           color: AppColor.lightGreyColor(context),
              //                           text: AppLocaleKey
              //                               .deliveredOrderToCustomer
              //                               .tr(),
              //                           style: AppTextStyle.text18BS(context),
              //                         ))
              //                     : const SizedBox()
              //         : Padding(
              //             padding: const EdgeInsets.symmetric(
              //                 horizontal: 16, vertical: 23),
              //             child: CustomButton(
              //               color: AppColor.lightGreyColor(context),
              //               text: AppLocaleKey.acceptedByAnotherDelegate.tr(),
              //               style: AppTextStyle.text18BS(context),
              //             )),
            ],
          ),
        );
      },
    );
  }
}
