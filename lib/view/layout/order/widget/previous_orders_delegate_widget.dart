import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/no_current_order_widget.dart';
import '../controller/delegate_order_controller.dart';
import 'single_previous_order_delegate.dart';

class PreviousOrdersDelegateWidget extends StatelessWidget {
  PreviousOrdersDelegateWidget({super.key, required this.delegateOrderController});
  final DelegateOrdersController delegateOrderController;

  final orderNumberPreviousEc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // final delegateOrderController = delegateOrderController;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            delegateOrderController.completedOrdersHasPagination &&
            !delegateOrderController.completedIsPaginating) {
          Provider.of<DelegateOrdersController>(
            context,
            listen: false,
          ).getDelegateCompletedOrders(pageNumber: delegateOrderController.completedOrderPage);
        }
        return true;
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomFormField(
              controller: orderNumberPreviousEc,
              hintText: AppLocaleKey.searchForARequest.tr(),
              suffixIcon: InkWell(
                onTap: () {
                  SoundNotification.instance.stopSound();
                  delegateOrderController.completedOrderPage = 1;
                  delegateOrderController.getDelegateCompletedOrders(orderNo: int.parse(orderNumberPreviousEc.text));
                },
                child: const Icon(Icons.search),
              ),
              onFieldSubmitted: (value) {
                delegateOrderController.completedOrderPage = 1;
                delegateOrderController.getDelegateCompletedOrders(orderNo: int.parse(value));
              },
              onChanged: (value) {
                if (value.isEmpty) {
                  delegateOrderController.completedOrderPage = 1;
                  delegateOrderController.getDelegateCompletedOrders();
                }
              },
            ),
            const SizedBox(height: 20),
            ApiResponseWidget(
              apiResponse: delegateOrderController.delegateCompletedOrdersResponse,
              onReload: () => delegateOrderController.getDelegateCompletedOrders(),
              isEmpty: delegateOrderController.delegateCompletedOrders.isEmpty,
              emptyWidget: const NoCurrentOrderWidget(),
              child: Column(
                children: [
                  ...List.generate(delegateOrderController.delegateCompletedOrders.length + 1, (index) {
                    if (index == delegateOrderController.delegateCompletedOrders.length) {
                      return delegateOrderController.completedIsPaginating
                          ? const Center(child: CustomLoading())
                          : const SizedBox.shrink();
                    }
                    return SinglePreviousDelegateOrderItem(
                      items: delegateOrderController.delegateCompletedOrders[index].delegateItems,
                      order: delegateOrderController.delegateCompletedOrders[index],
                      orderId: delegateOrderController.delegateCompletedOrders[index].id!,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
