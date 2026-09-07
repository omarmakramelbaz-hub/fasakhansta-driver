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
          final name = profile?.name?.trim().isNotEmpty == true ? profile!.name!.trim() : _t('المندوب', 'Driver');
          final area = profile?.areaTitle?.trim().isNotEmpty == true ? profile!.areaTitle!.trim() : _t('موقعك الحالي', 'Current location');
          final currentOrder = controller.currentDelegateHomeOrders.isNotEmpty ? controller.currentDelegateHomeOrders.first : null;

          return LayoutBuilder(
            builder: (context, c) {
              return RefreshIndicator(
                color: _orange,
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: c.maxWidth,
                    height: c.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 390,
                        height: 790,
                        child: Column(
                          children: [
                            _hero(area),
                            Transform.translate(
                              offset: const Offset(0, -20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  children: [
                                    _profile(name),
                                    const SizedBox(height: 13),
                                    _sectionTitle(
                                      _t('طلبات اليوم', "Today's orders"),
                                      _t('عرض الكل', 'View all'),
                                      () => context.read<DelegateBottomNavBarController>().updateIndex(1),
                                    ),
                                    const SizedBox(height: 7),
                                    _stats(controller),
                                    const SizedBox(height: 10),
                                    _currentOrder(currentOrder),
                                    const SizedBox(height: 10),
                                    const MyCurrentBalanceWidget(),
                                    const SizedBox(height: 10),
                                    _quickActions(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    return SizedBox(
      height: 154,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/delegateCover.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xff0B3A64)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xff062B50), Color(0xE80A3A65), Color(0xA30A3A65)],
              ),
            ),
          ),
          Positioned(
            right: 13,
            bottom: -2,
            child: Opacity(
              opacity: .26,
              child: SvgPicture.asset(AppImages.darkMotorCycle, width: 125),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 7, 15, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandWordmark(),
                  const Spacer(),
                  _location(area),
                  const SizedBox(width: 9),
                  InkWell(
                    onTap: () => context.read<DelegateBottomNavBarController>().updateIndex(2),
                    borderRadius: BorderRadius.circular(30),
                    child: SizedBox(
                      width: 36,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 29),
                          Positioned(
                            right: 0,
                            top: 4,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandWordmark() {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 22 - (i * 4),
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 3),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Text('GO', style: TextStyle(color: Colors.white, fontSize: 29, height: .9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ],
          ),
          const Text('DRIVE', style: TextStyle(color: Colors.white, fontSize: 20, height: .95, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          const SizedBox(height: 3),
          Text(_t('معك في كل طريق', 'With you all the way'), style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
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
          width: 143,
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.13)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: const Color(0xff0B3157).withOpacity(.90), shape: BoxShape.circle),
                child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('موقعك الحالي', 'Current location'), style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 8.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(area, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _orange, size: 19),
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
      height: 128,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE8EDF2)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffF0F3F7)),
                child: Text(_initials(name), style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('مرحباً، $name', 'Hello, $name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(_t('👋 نتمنى لك يوماً موفقاً', '👋 Have a successful day'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 10.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 87,
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(color: const Color(0xffF5F7FA), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: _navy, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontSize: 9, fontWeight: FontWeight.w800)),
                          Text(date, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 7.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (context.read<AuthController>().profile?.walletBlock == 0) const DelegateStatusWidget(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Container(width: 4, height: 21, decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 7),
        Expanded(child: Text(title, style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w900))),
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
    final cards = [
      _Stat(_t('قيد الانتظار', 'Pending'), controller.totalPending, Icons.schedule_rounded, _orange, const Color(0xffFFF2E7)),
      _Stat(_t('جاري التوصيل', 'Delivering'), controller.currentHomeOrders?.meta?.total ?? 0, Icons.local_shipping_rounded, const Color(0xff2F80ED), const Color(0xffEEF5FF)),
      _Stat(_t('مكتملة', 'Completed'), 0, Icons.check_rounded, const Color(0xff14A36A), const Color(0xffECF9F3)),
    ];
    return Row(children: [Expanded(child: cards[0]), const SizedBox(width: 7), Expanded(child: cards[1]), const SizedBox(width: 7), Expanded(child: cards[2])]);
  }

  Widget _currentOrder(DelegateOrdersModel? order) {
    return Container(
      height: 154,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE8EDF2)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(.05), blurRadius: 16, offset: const Offset(0, 7))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 7),
              Expanded(child: Text(_t('الطلب الحالي', 'Current order'), style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w900))),
              const Icon(Icons.inventory_2_outlined, color: _orange, size: 20),
            ],
          ),
          const Spacer(),
          if (order == null) ...[
            SvgPicture.asset(AppImages.noOrderIcon, width: 46, height: 46),
            const SizedBox(height: 3),
            Text(_t('لا يوجد طلب حالي حالياً', 'No current order'), style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(_t('سيظهر هنا الطلب القادم بمجرد استلامه', 'Your next accepted order will appear here'), style: const TextStyle(color: _soft, fontSize: 9.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 7),
            _orangeButton(_t('تحديث', 'Refresh'), Icons.refresh_rounded, _refreshData),
          ] else ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('${_t('طلب', 'Order')} #${order.orderNo ?? order.id ?? ''}', style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(order.resturantName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            _orangeButton(_t('عرض الطلب', 'View order'), Icons.arrow_forward_rounded, () {
              if (order.id == null) return;
              NavigatorMethods.pushNamed(context, OrderDetailsDelegateScreen.routeName, arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: order.id!));
            }),
          ],
        ],
      ),
    );
  }

  Widget _orangeButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          height: 31,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffFF8A08), Color(0xffFF6500)]), borderRadius: BorderRadius.circular(13)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)), const SizedBox(width: 7), Icon(icon, color: Colors.white, size: 18)]),
        ),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      _Action(_t('الدعم الفني', 'Support'), Icons.headset_mic_outlined, () => NavigatorMethods.pushNamed(context, HelpScreen.routeName)),
      _Action(_t('الخريطة', 'Map'), Icons.map_outlined, () => NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName)),
      _Action(_t('تقاريري', 'Reports'), Icons.bar_chart_rounded, () => NavigatorMethods.pushNamed(context, DelegateReportsScreen.routeName)),
      _Action(_t('الإعدادات', 'Settings'), Icons.settings_outlined, () => context.read<DelegateBottomNavBarController>().updateIndex(3)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('إجراءات سريعة', 'Quick actions'), style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(children: [for (int i = 0; i < actions.length; i++) ...[Expanded(child: _ActionCard(actions[i])), if (i != actions.length - 1) const SizedBox(width: 6)]]),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.count, this.icon, this.iconColor, this.background);
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 31, height: 31, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 17)),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(color: Color(0xff082A4D), fontSize: 21, height: 1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff082A4D), fontSize: 9.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Action {
  const _Action(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(this.data);
  final _Action data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 70,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffE8EDF2))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, color: const Color(0xff082A4D), size: 22),
              const SizedBox(height: 5),
              Text(data.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff082A4D), fontSize: 8.7, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
