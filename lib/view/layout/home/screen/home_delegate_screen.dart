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
  static const _navy2 = Color(0xff0D426F);
  static const _orange = Color(0xffFD7201);
  static const _soft = Color(0xff7D8490);

  bool get _ar => context.locale.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

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
    _pusherController.addEventListener('delegate.updated', _onPusher);
  }

  void _onPusher(PusherEvent event) {
    try {
      json.decode(event.data);
      if (mounted) _refreshData();
    } catch (e, s) {
      log('Home pusher error: $e');
      log('$s');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('delegate.updated', _onPusher);
    super.dispose();
  }

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (p.isEmpty) return 'GO';
    if (p.length == 1) return p.first.characters.first.toUpperCase();
    return '${p.first.characters.first}${p[1].characters.first}'.toUpperCase();
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

          return LayoutBuilder(
            builder: (context, c) {
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 390,
                    height: c.maxHeight * 390 / (c.maxWidth < 390 ? c.maxWidth : 390),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _hero(area),
                            const SizedBox(height: 83),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                child: Column(
                                  children: [
                                    _sectionTitle(
                                      _t('طلبات اليوم', "Today's orders"),
                                      _t('عرض الكل', 'View all'),
                                      () => context.read<DelegateBottomNavBarController>().updateIndex(1),
                                    ),
                                    const SizedBox(height: 6),
                                    _stats(controller),
                                    const Spacer(),
                                    _currentOrder(currentOrder),
                                    const Spacer(),
                                    const MyCurrentBalanceWidget(),
                                    const Spacer(),
                                    _quickActions(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 124,
                          child: _profile(name),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _hero(String area) {
    return Container(
      height: 176,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff062645), Color(0xff0B3A64), Color(0xff15527F)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -35,
            top: -60,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.035)),
            ),
          ),
          Positioned(
            right: -42,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _orange.withOpacity(.07)),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _RoadGlowPainter()),
          ),
          Positioned(
            right: 12,
            bottom: -1,
            child: Opacity(
              opacity: .42,
              child: SvgPicture.asset(AppImages.darkMotorCycle, width: 122),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned(left: 17, top: 5, child: _brandWordmark()),
                Positioned(left: 120, right: 59, top: 6, child: _location(area)),
                Positioned(
                  right: 15,
                  top: 8,
                  child: InkWell(
                    onTap: () => context.read<DelegateBottomNavBarController>().updateIndex(2),
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      width: 39,
                      height: 47,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 29),
                          Positioned(
                            right: 1,
                            top: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandWordmark() {
    return SizedBox(
      width: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 20 - (i * 3),
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 3),
                    decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text('GO', style: TextStyle(color: Colors.white, fontSize: 29, height: .9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 27),
            child: Text('DRIVE', style: TextStyle(color: Colors.white, fontSize: 19, height: .95, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 4),
          Text(_t('معك في كل طريق', 'With you all the way'), style: TextStyle(color: Colors.white.withOpacity(.88), fontSize: 9.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _location(String area) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.16)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: const Color(0xff0A3157).withOpacity(.92), shape: BoxShape.circle),
                child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('موقعك الحالي', 'Current location'), style: TextStyle(color: Colors.white.withOpacity(.70), fontSize: 8.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(area, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _orange, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profile(String name) {
    final now = DateTime.now();
    String day;
    String date;
    try {
      day = intl.DateFormat('EEEE', _ar ? 'ar' : 'en').format(now);
      date = intl.DateFormat('d MMMM yyyy', _ar ? 'ar' : 'en').format(now);
    } catch (_) {
      day = '${now.day}/${now.month}';
      date = '${now.day}/${now.month}/${now.year}';
    }

    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xffE7EBF0)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(.11), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffF0F3F7)),
                child: Text(_initials(name), style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('مرحباً، $name', 'Hello, $name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(_t('👋 نتمنى لك يوماً موفقاً', '👋 Have a successful day'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 82,
                height: 43,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(color: const Color(0xffF5F7FA), borderRadius: BorderRadius.circular(13)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: _navy, size: 17),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontSize: 8.7, fontWeight: FontWeight.w800)),
                          Text(date, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 7.2, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (context.read<AuthController>().profile?.walletBlock == 0) const DelegateStatusWidget(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 7),
        Expanded(child: Text(title, style: const TextStyle(color: _navy, fontSize: 16.5, fontWeight: FontWeight.w900))),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Row(
              children: [
                Icon(_ar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: _orange, size: 18),
                Text(action, style: const TextStyle(color: _orange, fontSize: 10.5, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stats(HomeDelegateController controller) {
    return Row(
      children: [
        Expanded(child: _Stat(_t('قيد الانتظار', 'Pending'), controller.totalPending, Icons.schedule_rounded, _orange, const Color(0xffFFF2E7))),
        const SizedBox(width: 7),
        Expanded(child: _Stat(_t('جاري التوصيل', 'Delivering'), controller.currentHomeOrders?.meta?.total ?? 0, Icons.local_shipping_rounded, const Color(0xff2F80ED), const Color(0xffEEF5FF))),
        const SizedBox(width: 7),
        Expanded(child: _Stat(_t('مكتملة', 'Completed'), 0, Icons.check_rounded, const Color(0xff14A36A), const Color(0xffECF9F3))),
      ],
    );
  }

  Widget _currentOrder(DelegateOrdersModel? order) {
    return Container(
      height: 119,
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xffE7EBF0)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(.055), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 4, height: 19, decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 6),
              Expanded(child: Text(_t('الطلب الحالي', 'Current order'), style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w900))),
              const Icon(Icons.inventory_2_outlined, color: _orange, size: 18),
            ],
          ),
          const SizedBox(height: 5),
          if (order == null) ...[
            Row(
              children: [
                Container(
                  width: 58,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xffF7F9FB), borderRadius: BorderRadius.circular(16)),
                  child: SvgPicture.asset(AppImages.noOrderIcon, width: 38, height: 38),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('لا يوجد طلب حالي حالياً', 'No current order'), style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(_t('سيظهر هنا الطلب القادم بمجرد استلامه', 'Your next accepted order will appear here'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 9.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _refreshData,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 82,
                    height: 39,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xffFF8A08), Color(0xffFF6500)]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(_t('تحديث', 'Refresh'), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(color: const Color(0xffFFF2E7), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.delivery_dining_rounded, color: _orange, size: 25),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_t('طلب', 'Order')} #${order.orderNo ?? order.id ?? ''}', style: const TextStyle(color: _navy, fontSize: 12.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(order.resturantName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 9.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: order.id == null
                      ? null
                      : () => NavigatorMethods.pushNamed(
                            context,
                            OrderDetailsDelegateScreen.routeName,
                            arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: order.id!),
                          ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: Text(_t('عرض الطلب', 'View order'), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      _Quick(_t('الدعم الفني', 'Support'), Icons.headset_mic_outlined, () => NavigatorMethods.pushNamed(context, HelpScreen.routeName)),
      _Quick(_t('الخريطة', 'Map'), Icons.map_outlined, () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName)),
      _Quick(_t('تقاريري', 'Reports'), Icons.bar_chart_rounded, () => NavigatorMethods.pushNamed(context, DelegateReportsScreen.routeName)),
      _Quick(_t('الإعدادات', 'Settings'), Icons.settings_outlined, () => context.read<DelegateBottomNavBarController>().updateIndex(3)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('إجراءات سريعة', 'Quick actions'), style: const TextStyle(color: _navy, fontSize: 15.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              Expanded(child: _QuickCard(data: actions[i])),
              if (i != actions.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _RoadGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(.045)..strokeWidth = 1.2;
    for (int i = 0; i < 6; i++) {
      final x = 210.0 + (i * 27);
      canvas.drawLine(Offset(x, 0), Offset(x - 35, size.height), p);
    }
    final road = Paint()..color = Colors.white.withOpacity(.035);
    final path = Path()
      ..moveTo(size.width * .45, size.height)
      ..lineTo(size.width * .66, size.height)
      ..lineTo(size.width * .60, size.height * .48)
      ..lineTo(size.width * .52, size.height * .48)
      ..close();
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.count, this.icon, this.iconColor, this.bg);
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 17)),
          const SizedBox(width: 7),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: const TextStyle(color: Color(0xff082A4D), fontSize: 18, height: 1, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              SizedBox(width: 56, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff082A4D), fontSize: 8.8, fontWeight: FontWeight.w800))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Quick {
  const _Quick(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.data});
  final _Quick data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE7EBF0)),
            boxShadow: [BoxShadow(color: const Color(0xff082A4D).withOpacity(.035), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, color: const Color(0xff082A4D), size: 21),
              const SizedBox(height: 4),
              Text(data.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff082A4D), fontSize: 8.4, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
