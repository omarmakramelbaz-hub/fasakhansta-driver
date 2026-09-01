import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../../order/model/delegate_order_model.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/delegate_home_controller.dart';
import '../widget/delegate_home_current_tap.dart';
import '../widget/delegate_home_pending_tap.dart';
import '../widget/delegate_status_widget.dart';
import '../widget/my_current_balance_card.dart';

class HomeDelegateScreen extends StatefulWidget {
  static const String routeName = 'HomeDelegateScreen';
  const HomeDelegateScreen({super.key});

  @override
  State<HomeDelegateScreen> createState() => _HomeDelegateScreenState();
}

class _HomeDelegateScreenState extends State<HomeDelegateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PusherController _pusherController;

  void _refreshData() {
    final controller = context.read<HomeDelegateController>();
    controller.initialPendingDelegateHomeOrders();
    controller.getPendingDelegateHomeOrders();
    controller.initialCurrentDelegateHomeOrders();
    controller.getCurrentDelegateHomeOrders();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      log('Event received: ${event.eventName}, Data: $decodedData');
      final orderData = decodedData['order_id'];
      if (orderData == null || !mounted) return;
      final orderModel = DelegateOrdersModel.fromJson(orderData as Map<String, dynamic>);
      _refreshData();
      if (orderModel.status == 'declined' || orderModel.status == 'cancelled') _refreshData();
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pusherController.removeEventListener('delegate.updated', _handleDelegateUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      body: Consumer<HomeDelegateController>(
        builder: (context, controller, _) {
          final name = context.watch<AuthController>().profile?.name ?? '';
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.locale.languageCode == 'ar' ? 'مرحباً، $name' : 'Welcome, $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.locale.languageCode == 'ar'
                            ? 'تابع حالتك وطلباتك وأرباحك من مكان واحد'
                            : 'Manage your status, orders and earnings in one place',
                        style: const TextStyle(
                          color: softText,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (context.read<AuthController>().profile?.walletBlock == 0) ...[
                        const DelegateStatusWidget(),
                        const SizedBox(height: 18),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocaleKey.myWallet.tr(),
                              style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
                            iconAlignment: IconAlignment.end,
                            icon: Icon(
                              Directionality.of(context).name == 'rtl'
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              size: 20,
                              color: const Color(0xffFD7201),
                            ),
                            label: Text(
                              context.locale.languageCode == 'ar' ? 'عرض المحفظة' : 'View wallet',
                              style: const TextStyle(
                                color: Color(0xffFD7201),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const MyCurrentBalanceWidget(),
                      const SizedBox(height: 22),
                      Text(
                        AppLocaleKey.todayRequests.tr(),
                        style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xffEEF0F3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(.08),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      labelColor: navy,
                      unselectedLabelColor: softText,
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      onTap: (_) => setState(() {}),
                      tabs: [
                        Tab(child: _buildTabItem(AppLocaleKey.pending.tr(), controller.totalPending, 0)),
                        Tab(
                          child: _buildTabItem(
                            AppLocaleKey.ongoing.tr(),
                            controller.currentHomeOrders?.meta?.total ?? 0,
                            1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DelegatePendingTapList(onSuccess: _refreshData, homeDelegateController: controller),
                      DelegateCurrentTapList(homeDelegateController: controller),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabItem(String label, int count, int tabIndex) {
    final selected = _tabController.index == tabIndex;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 27, minHeight: 27),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xffFD7201) : const Color(0xffDDE1E6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xff68707B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
