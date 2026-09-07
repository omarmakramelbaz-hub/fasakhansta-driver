import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/controller/delegate_bottom_nav_bar_controller.dart';
import '../../my_account/screen/delegate_reports_screen.dart';
import '../../my_account/screen/help_screen.dart';
import '../../order/model/delegate_order_model.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../controller/delegate_home_controller.dart';
import '../widget/delegate_status_widget.dart';
import '../widget/my_current_balance_card.dart';
import 'location_delegate.dart';

class HomeDelegateScreen extends StatefulWidget {
  static const String routeName = 'HomeDelegateScreen';
  const HomeDelegateScreen({super.key});

  @override
  State<HomeDelegateScreen> createState() => _HomeDelegateScreenState();
}

class _HomeDelegateScreenState extends State<HomeDelegateScreen> {
  late PusherController _pusherController;

  static const _navy = Color(0xff082A4D);
  static const _navyLight = Color(0xff123F6B);
  static const _orange = Color(0xffFD7201);
  static const _softText = Color(0xff7D8490);

  bool get _isArabic => context.locale.languageCode == 'ar';

  String _t(String ar, String en) => _isArabic ? ar : en;

  Future<void> _refreshData() async {
    final controller = context.read<HomeDelegateController>();
    controller.initialPendingDelegateHomeOrders();
    controller.initialCurrentDelegateHomeOrders();
    await Future.wait([
      controller.getPendingDelegateHomeOrders(),
      controller.getCurrentDelegateHomeOrders(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final data = json.decode(event.data) as Map<String, dynamic>;
      log('Event received: ${event.eventName}, Data: $data');
      if (!mounted || data['order_id'] == null) return;
      _refreshData();
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('delegate.updated', _handleDelegateUpdated);
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'GO';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      body: Consumer<HomeDelegateController>(
        builder: (context, controller, _) {
          final profile = context.watch<AuthController>().profile;
          final name = profile?.name?.trim().isNotEmpty == true
              ? profile!.name!.trim()
              : _t('المندوب', 'Driver');
          final area = profile?.areaTitle?.trim().isNotEmpty == true
              ? profile!.areaTitle!.trim()
              : _t('موقعك الحالي', 'Current location');
          final currentOrder = controller.currentDelegateHomeOrders.isNotEmpty
              ? controller.currentDelegateHomeOrders.first
              : null;

          return RefreshIndicator(
            color: _orange,
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  _heroHeader(area),
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _profileCard(name),
                          const SizedBox(height: 22),
                          _sectionTitle(
                            title: _t('طلبات اليوم', "Today's orders"),
                            action: _t('عرض الكل', 'View all'),
                            onTap: () => context.read<DelegateBottomNavBarController>().updateIndex(1),
                          ),
                          const SizedBox(height: 12),
                          _todayStats(controller),
                          const SizedBox(height: 18),
                          _currentOrderCard(currentOrder),
                          const SizedBox(height: 18),
                          const MyCurrentBalanceWidget(),
                          const SizedBox(height: 22),
                          _quickActions(),
                          const SizedBox(height: 116),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroHeader(String area) {
    final logo = SizedBox(
      width: 102,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/go_drive_logo_hd.webp',
            width: 100,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'GO\nDRIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                height: .82,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _t('معك في كل طريق', 'With you all the way'),
            maxLines: 1,
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final location = Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(.10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xff0B3157).withOpacity(.84),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('موقعك الحالي', 'Current location'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(.72),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: _orange, size: 22),
              ],
            ),
          ),
        ),
      ),
    );

    final bell = GestureDetector(
      onTap: () => context.read<DelegateBottomNavBarController>().updateIndex(2),
      child: SizedBox(
        width: 42,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30),
            Positioned(
              right: 2,
              top: 3,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      height: 224,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyLight, _navy],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -62,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.035)),
            ),
          ),
          Positioned(
            left: -74,
            bottom: -105,
            child: Container(
              width: 255,
              height: 255,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _orange.withOpacity(.055)),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 13,
            child: Opacity(
              opacity: .25,
              child: SvgPicture.asset(AppImages.darkMotorCycle, width: 145, fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _isArabic
                    ? [bell, const SizedBox(width: 10), location, const SizedBox(width: 10), logo]
                    : [logo, const SizedBox(width: 10), location, const SizedBox(width: 10), bell],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(String name) {
    final now = DateTime.now();
    String day;
    String date;
    try {
      day = intl.DateFormat('EEEE', _isArabic ? 'ar' : 'en').format(now);
      date = intl.DateFormat('d MMMM yyyy', _isArabic ? 'ar' : 'en').format(now);
    } catch (_) {
      day = '${now.day}/${now.month}';
      date = '${now.day}/${now.month}/${now.year}';
    }

    final avatar = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xffF0F3F7), Color(0xffE5EAF0)]),
      ),
      child: Text(
        _initials(name),
        style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900),
      ),
    );

    final greeting = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('مرحباً، $name', 'Hello, $name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _navy, fontSize: 21, height: 1.25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            _t('👋 نتمنى لك يوماً موفقاً', '👋 Have a successful day'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _softText, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );

    final dateCard = Container(
      width: 98,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(color: const Color(0xffF5F7FA), borderRadius: BorderRadius.circular(17)),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: _navy, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _navy, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _softText, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffE9EDF2)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(.08), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Row(
            children: _isArabic
                ? [dateCard, const SizedBox(width: 9), greeting, const SizedBox(width: 12), avatar]
                : [avatar, const SizedBox(width: 12), greeting, const SizedBox(width: 9), dateCard],
          ),
          const SizedBox(height: 16),
          if (context.read<AuthController>().profile?.walletBlock == 0) const DelegateStatusWidget(),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String action, required VoidCallback onTap}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900))),
        TextButton.icon(
          onPressed: onTap,
          iconAlignment: IconAlignment.end,
          icon: Icon(_isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: _orange, size: 20),
          label: Text(action, style: const TextStyle(color: _orange, fontSize: 12.5, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _todayStats(HomeDelegateController controller) {
    final cards = <Widget>[
      _TodayStatCard(
        label: _t('قيد الانتظار', 'Pending'),
        count: controller.totalPending,
        icon: Icons.schedule_rounded,
        iconColor: _orange,
        background: const Color(0xffFFF2E7),
      ),
      _TodayStatCard(
        label: _t('جاري التوصيل', 'Delivering'),
        count: controller.currentHomeOrders?.meta?.total ?? 0,
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xff2F80ED),
        background: const Color(0xffEEF5FF),
      ),
      _TodayStatCard(
        label: _t('مكتملة', 'Completed'),
        count: 0,
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xff14A36A),
        background: const Color(0xffECF9F3),
      ),
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
        const SizedBox(width: 10),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _currentOrderCard(DelegateOrdersModel? order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xffE9EDF2)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(.055), blurRadius: 22, offset: const Offset(0, 9))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 23,
                decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_t('الطلب الحالي', 'Current order'), style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              const Icon(Icons.inventory_2_outlined, color: _orange, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          if (order == null) ...[
            SvgPicture.asset(AppImages.noOrderIcon, width: 72, height: 72),
            const SizedBox(height: 10),
            Text(
              _t('لا يوجد طلب حالي حالياً', 'No current order'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              _t('سيظهر هنا الطلب القادم بمجرد استلامه', 'Your next accepted order will appear here'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _softText, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            _OrangeActionButton(label: _t('تحديث', 'Refresh'), icon: Icons.refresh_rounded, onTap: _refreshData),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xffF7F9FB), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_t('طلب', 'Order')} #${order.orderNo ?? order.id ?? ''}',
                    style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: _orange, size: 19),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          order.resturantName ?? _t('الطلب الحالي', 'Current order'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _navy, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if ((order.toAddress ?? order.userLocation ?? '').isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xff2F80ED), size: 19),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            order.toAddress ?? order.userLocation ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _softText, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _OrangeActionButton(
              label: _t('عرض الطلب', 'View order'),
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                if (order.id == null) return;
                NavigatorMethods.pushNamed(
                  context,
                  OrderDetailsDelegateScreen.routeName,
                  arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: order.id!),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      _QuickActionData(
        label: _t('الدعم الفني', 'Support'),
        icon: Icons.headset_mic_outlined,
        onTap: () => NavigatorMethods.pushNamed(context, HelpScreen.routeName),
      ),
      _QuickActionData(
        label: _t('الخريطة', 'Map'),
        icon: Icons.map_outlined,
        onTap: () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName),
      ),
      _QuickActionData(
        label: _t('تقاريري', 'Reports'),
        icon: Icons.bar_chart_rounded,
        onTap: () => NavigatorMethods.pushNamed(context, DelegateReportsScreen.routeName),
      ),
      _QuickActionData(
        label: _t('الإعدادات', 'Settings'),
        icon: Icons.settings_outlined,
        onTap: () => context.read<DelegateBottomNavBarController>().updateIndex(3),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(_t('إجراءات سريعة', 'Quick actions'), style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              Expanded(child: _QuickActionCard(data: actions[i])),
              if (i != actions.length - 1) const SizedBox(width: 9),
            ],
          ],
        ),
      ],
    );
  }
}

class _TodayStatCard extends StatelessWidget {
  const _TodayStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withOpacity(.88)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text('$count', style: const TextStyle(color: Color(0xff082A4D), fontSize: 25, height: 1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff082A4D), fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _OrangeActionButton extends StatelessWidget {
  const _OrangeActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xffFF8A08), Color(0xffFF6500)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: const Color(0xffFD7201).withOpacity(.22), blurRadius: 16, offset: const Offset(0, 7))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(width: 9),
              Icon(icon, color: Colors.white, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data});
  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xffE9EDF2)),
            boxShadow: [BoxShadow(color: const Color(0xff082A4D).withOpacity(.04), blurRadius: 16, offset: const Offset(0, 7))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, color: const Color(0xff082A4D), size: 27),
              const SizedBox(height: 8),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xff082A4D), fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
