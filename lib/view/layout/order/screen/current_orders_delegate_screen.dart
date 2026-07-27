import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../global/widget/order_delegate_widget.dart';
import '../../home/controller/delegate_home_controller.dart';

class CurrentOrdersDelegateArgs {
  final VoidCallback onPop;

  CurrentOrdersDelegateArgs({required this.onPop});
}

class CurrentOrdersDelegateScreen extends StatefulWidget {
  static const String routeName = 'CurrentOrdersDelegateScreen';
  final CurrentOrdersDelegateArgs args;
  const CurrentOrdersDelegateScreen({super.key, required this.args});

  @override
  State<CurrentOrdersDelegateScreen> createState() => _CurrentOrdersDelegateScreenState();
}

class _CurrentOrdersDelegateScreenState extends State<CurrentOrdersDelegateScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeDelegateController>(context, listen: false).initialCurrentDelegateOrders();
      Provider.of<HomeDelegateController>(context, listen: false).getCurrentDelegateOrders();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeDelegateController>(
      builder: (context, dOrderController, _) {
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) {
              widget.args.onPop.call();
            }
          },
          child: Scaffold(
            appBar: CustomAppBar(
              context,
              height: 80,
              centerTitle: false,
              leadingPadding: 40,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: AppColor.blackColor(context)),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(AppLocaleKey.currentOrders.tr(), style: AppTextStyle.text20BS(context)),
              ),
            ),
            body: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels == notification.metrics.maxScrollExtent &&
                    dOrderController.currentOrdersHasPagination &&
                    !dOrderController.currentIsPaginating) {
                  dOrderController.getCurrentDelegateOrders();
                }
                return true;
              },
              child: ApiResponseWidget(
                apiResponse: dOrderController.currentDelegateOrdersResponse,
                onReload: () => dOrderController.getCurrentDelegateOrders(),
                isEmpty: dOrderController.currentDelegateOrders.isEmpty,
                child: RefreshIndicator(
                  onRefresh: () => dOrderController.getCurrentDelegateOrders(),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 21),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(AppLocaleKey.currentOrders.tr(), style: AppTextStyle.text20BS(context)),
                              const SizedBox(width: 20),
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColor.mainAppColor(context),
                                child: Center(
                                  child: Text(
                                    dOrderController.currentOrders?.meta?.total.toString() ?? '0',
                                    style: AppTextStyle.text18BW(
                                      context,
                                    ).copyWith(height: context.locale.languageCode == 'ar' ? 1.7 : 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(dOrderController.currentDelegateOrders.length + 1, (index) {
                            if (index == dOrderController.currentDelegateOrders.length) {
                              return dOrderController.currentIsPaginating
                                  ? const Center(child: CustomLoading())
                                  : const SizedBox.shrink();
                            }
                            return OrderDelegateWidget(
                              isDelivered: false,
                              orderId: dOrderController.currentDelegateOrders[index].id!,
                              order: dOrderController.currentDelegateOrders[index],
                              orderItem: dOrderController.currentDelegateOrders[index].delegateItems,
                              onsuccess: () {
                                dOrderController.getCurrentDelegateOrders(pageNumber: 1);
                              },
                            );
                          }),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
