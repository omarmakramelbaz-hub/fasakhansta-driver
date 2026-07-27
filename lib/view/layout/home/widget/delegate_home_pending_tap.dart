import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/no_current_order_widget.dart';
import '../../../global/widget/order_delegate_widget.dart';
import '../controller/delegate_home_controller.dart';
import 'home_shimmer_widget.dart';

class DelegatePendingTapList extends StatelessWidget {
  const DelegatePendingTapList({super.key, required this.homeDelegateController, required this.onSuccess});
  final HomeDelegateController homeDelegateController;
  final VoidCallback onSuccess;
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            homeDelegateController.pendingOrdersHasPagination &&
            !homeDelegateController.pendingIsPaginating) {
          Provider.of<HomeDelegateController>(
            context,
            listen: false,
          ).getPendingDelegateHomeOrders(pageNumber: homeDelegateController.pendingOrderPage);
        }
        return true;
      },
      child: SingleChildScrollView(
        child: ApiResponseWidget(
          emptyWidget: const NoCurrentOrderWidget(),
          apiResponse: homeDelegateController.pendingDelegateOrdersResponse,
          onReload: () => homeDelegateController.getPendingDelegateHomeOrders(),
          isEmpty: homeDelegateController.pendingDelegateOrders.isEmpty,
          loadingWidget: const HomeShimmerWidget(),
          child: Column(
            children: [
              ...List.generate(homeDelegateController.pendingDelegateOrders.length + 1, (index) {
                if (index == homeDelegateController.pendingDelegateOrders.length) {
                  return homeDelegateController.pendingIsPaginating
                      ? const Center(child: CustomLoading())
                      : Container();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: OrderDelegateWidget(
                    onsuccess: onSuccess,
                    isDelivered: false,
                    orderId: homeDelegateController.pendingDelegateOrders[index].id ?? 0,
                    order: homeDelegateController.pendingDelegateOrders[index],
                    orderItem: homeDelegateController.pendingDelegateOrders[index].delegateItems,
                  ),
                );
              }),
              //  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            ],
          ),
        ),
      ),
    );
    // });
  }
}
