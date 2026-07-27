import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/no_current_order_widget.dart';
import '../controller/delegate_order_controller.dart';
import 'single_on_going_delegate_widget.dart';

class WaitingOrdersDelegateWidget extends StatelessWidget {
  WaitingOrdersDelegateWidget({super.key, required this.delegateOrderController});
  final DelegateOrdersController delegateOrderController;

  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // final delegateOrderController = delegateOrderController;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            delegateOrderController.waitingOrdersHasPagination &&
            !delegateOrderController.waitingIsPaginating) {
          delegateOrderController.getDelegateWaitingOrders(pageNumber: delegateOrderController.waitingOrderPage);
        }
        return true;
      },
      child: SingleChildScrollView(
        child: RefreshIndicator(
          onRefresh: () async {
            await delegateOrderController.getDelegateWaitingOrders(pageNumber: 1);
          },
          child: Column(
            children: [
              const SizedBox(height: 20),
              CustomFormField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    delegateOrderController.waitingOrderPage = 1;
                    delegateOrderController.getDelegateWaitingOrders(orderNo: int.parse(value));
                  }
                },
                hintText: AppLocaleKey.searchForARequest.tr(),
                suffixIcon: InkWell(
                  onTap: () {
                    SoundNotification.instance.stopSound();
                    if (_searchController.text.isNotEmpty) {
                      delegateOrderController.waitingOrderPage = 1;
                      delegateOrderController.getDelegateWaitingOrders();
                    }
                  },
                  child: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              ApiResponseWidget(
                apiResponse: delegateOrderController.delegateWaitingOrdersResponse,
                onReload: () => delegateOrderController.getDelegateWaitingOrders(),
                isEmpty: delegateOrderController.delegateWaitingOrders.isEmpty,
                emptyWidget: const NoCurrentOrderWidget(),
                child: Column(
                  children: [
                    ...List.generate(delegateOrderController.delegateWaitingOrders.length + 1, (index) {
                      if (index == delegateOrderController.delegateWaitingOrders.length) {
                        return delegateOrderController.waitingIsPaginating
                            ? const Center(child: CustomLoading())
                            : const SizedBox.shrink();
                      }
                      return SingleOnGoingDelegateWidget(
                        order: delegateOrderController.delegateWaitingOrders[index],
                        items: delegateOrderController.delegateWaitingOrders[index].delegateItems,
                        onSuccess: () {
                          delegateOrderController.getDelegateWaitingOrders(pageNumber: 1);
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
