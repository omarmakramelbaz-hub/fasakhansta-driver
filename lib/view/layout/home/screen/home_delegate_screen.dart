import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../../order/model/delegate_order_model.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/delegate_home_controller.dart';
import '../widget/delegate_home_current_tap.dart';
import '../widget/delegate_home_pending_tap.dart';
import '../widget/delegate_status_widget.dart';
import '../widget/lable_and_more_widget.dart';
import '../widget/my_current_balance_card.dart';

class HomeDelegateScreen extends StatefulWidget {
  static const String routeName = 'HomeDelegateScreen';
  const HomeDelegateScreen({super.key});

  @override
  State<HomeDelegateScreen> createState() => _HomeDelegateScreenState();
}

class _HomeDelegateScreenState extends State<HomeDelegateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PusherController? _pusherController;
  int? totalPending;

  bool get _isGitHubPreview => kIsWeb && Uri.base.host.endsWith('github.io');

  void _refreshData() {
    if (_isGitHubPreview) return;
    Provider.of<HomeDelegateController>(context, listen: false).initialPendingDelegateHomeOrders();
    Provider.of<HomeDelegateController>(context, listen: false).getPendingDelegateHomeOrders();
    Provider.of<HomeDelegateController>(context, listen: false).initialCurrentDelegateHomeOrders();
    Provider.of<HomeDelegateController>(context, listen: false).getCurrentDelegateHomeOrders();
  }

  @override
  void initState() {
    final authController = context.read<AuthController>();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isGitHubPreview) return;
      if (authController.profile?.photoProfile == '') {
        CommonMethods.showCompleteInfoDialog(context: context);
      }
      _refreshData();
    });

    if (!_isGitHubPreview) {
      _pusherController = context.read<PusherController>();
      _pusherController!.addEventListener('delegate.updated', _handleDelegateUpdated);
    }
    super.initState();
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      log('Event received:===============================> ${event.eventName}, Data: $decodedData');

      final orderData = decodedData['order_id'];
      if (orderData == null) return;

      if (mounted) {
        var orderModel = DelegateOrdersModel.fromJson(orderData as Map<String, dynamic>);
        _refreshData();
        if (orderModel.status == 'declined' || orderModel.status == 'cancelled') {
          _refreshData();
        }
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pusherController?.removeEventListener('delegate.updated', _handleDelegateUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeDelegateController>(
        builder: (context, homeDelegateController, _) {
          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        if (!_isGitHubPreview && context.read<AuthController>().profile?.walletBlock == 0) ...[
                          const DelegateStatusWidget(),
                        ],
                        const SizedBox(height: 20),
                        LabelAndMoreWidget(
                          title: AppLocaleKey.myWallet.tr(),
                          onPressed: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
                        ),
                        const MyCurrentBalanceWidget(),
                        const SizedBox(height: 10),
                        Text(AppLocaleKey.todayRequests.tr(), style: AppTextStyle.text16BS(context)),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColor.mainAppColor(context),
                  indicatorColor: AppColor.mainAppColor(context),
                  unselectedLabelColor: AppColor.greyColor(context),
                  indicatorPadding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: AppTextStyle.text14BS(context).copyWith(color: AppColor.mainAppColor(context)),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  onTap: (value) {
                    setState(() => _tabController.index = value);
                  },
                  tabs: [
                    Tab(child: _buildTabItem(context, AppLocaleKey.pending.tr(), homeDelegateController.totalPending, 0)),
                    Tab(
                      child: _buildTabItem(
                        context,
                        AppLocaleKey.ongoing.tr(),
                        homeDelegateController.currentHomeOrders?.meta?.total ?? 0,
                        1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DelegatePendingTapList(
                        onSuccess: () => _refreshData(),
                        homeDelegateController: homeDelegateController,
                      ),
                      DelegateCurrentTapList(homeDelegateController: homeDelegateController),
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

  Widget _buildTabItem(BuildContext context, String label, int count, int tabIndex) {
    final bool isSelected = _tabController.index == tabIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 13),
        CircleAvatar(
          radius: 14,
          backgroundColor: isSelected ? AppColor.mainAppColor(context) : AppColor.lightGreyColor(context),
          child: Center(
            child: Text(
              count.toString(),
              style: AppTextStyle.text16BW(context).copyWith(height: context.locale.languageCode == 'ar' ? 1.7 : 1),
            ),
          ),
        ),
      ],
    );
  }
}
