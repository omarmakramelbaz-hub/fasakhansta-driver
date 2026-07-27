import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/no_current_order_widget.dart';
import '../controller/delegate_order_controller.dart';
import 'filter_search_delegate_bottom_sheet.dart';
import 'single_on_going_delegate_widget.dart';

class OnGoingOrdersDelegateWidget extends StatelessWidget {
  OnGoingOrdersDelegateWidget({super.key, required this.delegateOrderController});
  final DelegateOrdersController delegateOrderController;
  final searchNumberEc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //final delegateOrderController = delegateOrderController;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            delegateOrderController.onGoingOrdersHasPagination &&
            !delegateOrderController.onGoingIsPaginating) {
          Provider.of<DelegateOrdersController>(
            context,
            listen: false,
          ).getDelegateOngoingOrders(pageNumber: delegateOrderController.ongoingOrderPage);
        }
        return true;
      },
      child: SingleChildScrollView(
        child: RefreshIndicator(
          onRefresh: () async {
            delegateOrderController.getDelegateOngoingOrders(pageNumber: 1);
          },
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomFormField(
                      controller: searchNumberEc,
                      keyboardType: TextInputType.number,
                      hintText: AppLocaleKey.searchForARequest.tr(),
                      suffixIcon: InkWell(
                        onTap: () {
                          SoundNotification.instance.stopSound();
                          delegateOrderController.ongoingOrderPage = 1;
                          delegateOrderController.getDelegateOngoingOrders(orderNo: int.parse(searchNumberEc.text));
                        },
                        child: const Icon(Icons.search),
                      ),
                      onFieldSubmitted: (value) {
                        delegateOrderController.ongoingOrderPage = 1;
                        delegateOrderController.getDelegateOngoingOrders(orderNo: int.parse(value));
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          delegateOrderController.ongoingOrderPage = 1;
                          delegateOrderController.getDelegateOngoingOrders();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 11),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColor.mainAppColor(context),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.tune_rounded, color: AppColor.whiteColor(context)),
                        onPressed: () {
                          NavigatorMethods.showAppBottomSheet(
                            enableDrag: true,
                            isScrollControlled: true,
                            context,
                            ChangeNotifierProvider.value(
                              value: delegateOrderController,
                              builder: (context, child) => const FilterSearchDelegateBottomSheet(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ApiResponseWidget(
                apiResponse: delegateOrderController.delegateOngoingOrdersResponse,
                onReload: () => delegateOrderController.getDelegateOngoingOrders(),
                isEmpty: delegateOrderController.delegateOngoingOrders.isEmpty,
                emptyWidget: const NoCurrentOrderWidget(),
                child: Column(
                  children: [
                    ...List.generate(delegateOrderController.delegateOngoingOrders.length + 1, (index) {
                      if (index == delegateOrderController.delegateOngoingOrders.length) {
                        return delegateOrderController.onGoingIsPaginating
                            ? const Center(child: CustomLoading())
                            : const SizedBox.shrink();
                      }
                      return SingleOnGoingDelegateWidget(
                        order: delegateOrderController.delegateOngoingOrders[index],
                        items: delegateOrderController.delegateOngoingOrders[index].delegateItems,
                        onSuccess: () {
                          delegateOrderController.getDelegateOngoingOrders(pageNumber: 1);
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
