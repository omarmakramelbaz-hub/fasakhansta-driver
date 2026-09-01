import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/no_current_order_widget.dart';
import '../../../global/widget/order_delegate_widget.dart';
import '../controller/delegate_home_controller.dart';
import 'home_shimmer_widget.dart';

class DelegateCurrentTapList extends StatelessWidget {
  const DelegateCurrentTapList({super.key, required this.homeDelegateController});
  final HomeDelegateController homeDelegateController;

  bool get _isGitHubPreview => kIsWeb && Uri.base.host.endsWith('github.io');

  @override
  Widget build(BuildContext context) {
    if (_isGitHubPreview) {
      return const NoCurrentOrderWidget();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            homeDelegateController.currentHomeOrdersHasPagination &&
            !homeDelegateController.currentHomeIsPaginating) {
          Provider.of<HomeDelegateController>(
            context,
            listen: false,
          ).getPendingDelegateHomeOrders(pageNumber: homeDelegateController.currentOrderHomePage);
        }
        return true;
      },
      child: SingleChildScrollView(
        child: ApiResponseWidget(
          emptyWidget: const NoCurrentOrderWidget(),
          apiResponse: homeDelegateController.currentDelegateHomeOrdersResponse,
          onReload: () => homeDelegateController.getPendingDelegateHomeOrders(),
          isEmpty: homeDelegateController.currentDelegateHomeOrders.isEmpty,
          loadingWidget: const HomeShimmerWidget(),
          child: Column(
            children: [
              ...List.generate(homeDelegateController.currentDelegateHomeOrders.length + 1, (index) {
                if (index == homeDelegateController.currentDelegateHomeOrders.length) {
                  return homeDelegateController.currentHomeIsPaginating
                      ? const Center(child: CustomLoading())
                      : Container();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: OrderDelegateWidget(
                    isDelivered: false,
                    orderId: homeDelegateController.currentDelegateHomeOrders[index].id ?? 0,
                    order: homeDelegateController.currentDelegateHomeOrders[index],
                    orderItem: homeDelegateController.currentDelegateHomeOrders[index].delegateItems,
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            ],
          ),
        ),
      ),
    );
  }
}
