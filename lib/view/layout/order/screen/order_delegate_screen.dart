import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../controller/delegate_order_controller.dart';
import '../model/delegate_order_model.dart';
import '../widget/on_going_orders_delegate_widget.dart';
import '../widget/previous_orders_delegate_widget.dart';
import '../widget/waiting_delegate_tap.dart';

class OrdersDelegateScreen extends StatefulWidget {
  const OrdersDelegateScreen({super.key});

  @override
  State<OrdersDelegateScreen> createState() => _OrdersDelegateScreenState();
}

class _OrdersDelegateScreenState extends State<OrdersDelegateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PusherController _pusherController; // Saved reference
  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final orderData = decodedData['order_id'];
      if (mounted) {
        var orderModel = DelegateOrdersModel.fromJson(orderData as Map<String, dynamic>);
        _loadData();
        //  context.read<DelegateOrdersController>().addOrderToTop(orderModel);
        if (orderModel.status == 'declined' || orderModel.status == 'cancelled') {
          _loadData();
        }
        //_loadData();
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _loadData() {
    final orderController = Provider.of<DelegateOrdersController>(context, listen: false);
    // Provider.of<DelegateOrdersController>(context, listen: false)
    //     .getAllDelegateOrders();
    orderController.initialDelegateCompletedOrders();
    orderController.initialDelegateOngoingOrders();
    orderController.initialDelegateWaitingOrders();
    Future.wait([
      orderController.getDelegateWaitingOrders(),
      orderController.getDelegateOngoingOrders(),
      orderController.getDelegateCompletedOrders(),
    ]);
  }

  Color _getCircleAvatarBgColor(int index) {
    return _tabController.index == index
        ? AppColor.mainAppColor(context)
        : AppColor.greyColor(context).withOpacity(0.3);
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('delegate.updated', _handleDelegateUpdated); // Use saved reference
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Consumer<DelegateOrdersController>(
          builder: (context, delegateOrderController, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //============title===============
                  Text(AppLocaleKey.orders.tr(), style: AppTextStyle.text20BS(context)),

                  TabBar(
                    controller: _tabController,
                    labelStyle: AppTextStyle.text16BM(context),
                    unselectedLabelStyle: AppTextStyle.text16RG(context),
                    indicatorColor: AppColor.mainAppColor(context),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    isScrollable: true,
                    onTap: (value) {
                      setState(() {
                        _tabController.index = value;
                      });
                    },
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocaleKey.pending.tr()),
                            const SizedBox(width: 13),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _getCircleAvatarBgColor(0),
                              child: Center(
                                child: Text(
                                  delegateOrderController.totalWaiting.toString(),
                                  style: AppTextStyle.text18BW(
                                    context,
                                  ).copyWith(height: context.locale.languageCode == 'ar' ? 1.7 : 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocaleKey.ongoing.tr()),
                            const SizedBox(width: 13),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _getCircleAvatarBgColor(1),
                              child: Center(
                                child: Text(
                                  delegateOrderController.ongoingOrders?.meta?.total.toString() ?? '0',
                                  style: AppTextStyle.text18BW(
                                    context,
                                  ).copyWith(height: context.locale.languageCode == 'ar' ? 1.7 : 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocaleKey.previous.tr()),
                            const SizedBox(width: 5),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _getCircleAvatarBgColor(2), // Change background color dynamically
                              child: Center(
                                child: Text(
                                  delegateOrderController.completedOrders?.meta?.total?.toString() ?? '0',
                                  style: AppTextStyle.text18BW(
                                    context,
                                  ).copyWith(height: context.locale.languageCode == 'ar' ? 1.7 : 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColor.greyColor(context).withOpacity(0.2)),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        WaitingOrdersDelegateWidget(delegateOrderController: delegateOrderController),
                        OnGoingOrdersDelegateWidget(delegateOrderController: delegateOrderController),
                        PreviousOrdersDelegateWidget(delegateOrderController: delegateOrderController),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
