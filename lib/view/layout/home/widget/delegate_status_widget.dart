import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/controller/delegate_bottom_nav_bar_controller.dart';

class DelegateStatusWidget extends StatefulWidget {
  const DelegateStatusWidget({super.key});

  @override
  State<DelegateStatusWidget> createState() => _DelegateStatusWidgetState();
}

enum DelegateStatus { active, inactive }

class _DelegateStatusWidgetState extends State<DelegateStatusWidget> {
  DelegateStatus? selectedStatus;

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    authController.addListener(_syncStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStatus());
  }

  void _syncStatus() {
    if (!mounted) return;
    final delegateStatus = context.read<AuthController>().profile?.delegateStatus;
    if (delegateStatus == null) return;
    final next = delegateStatus == 'active' ? DelegateStatus.active : DelegateStatus.inactive;
    if (selectedStatus != next) setState(() => selectedStatus = next);
  }

  @override
  void dispose() {
    context.read<AuthController>().removeListener(_syncStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);

    return ChangeNotifierProvider(
      create: (_) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, controller, _) {
          final active = selectedStatus == DelegateStatus.active;
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffECEEF1)),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(.07),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xffEAF8F2) : const Color(0xffFFF0E3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        active ? Icons.delivery_dining_rounded : Icons.pause_circle_outline_rounded,
                        color: active ? const Color(0xff16A36A) : const Color(0xffFD7201),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocaleKey.delegateStatus.tr(),
                            style: const TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            active
                                ? (context.locale.languageCode == 'ar' ? 'أنت متاح لاستقبال الطلبات' : 'You are available for orders')
                                : (context.locale.languageCode == 'ar' ? 'أنت غير متاح حالياً' : 'You are currently unavailable'),
                            style: const TextStyle(
                              color: Color(0xff7D8490),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xffF3F5F7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatusButton(
                          label: AppLocaleKey.active.tr(),
                          selected: selectedStatus == DelegateStatus.active,
                          active: true,
                          onTap: () => _changeStatus(DelegateStatus.active, controller),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StatusButton(
                          label: AppLocaleKey.inactive.tr(),
                          selected: selectedStatus == DelegateStatus.inactive,
                          active: false,
                          onTap: () => _changeStatus(DelegateStatus.inactive, controller),
                        ),
                      ),
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

  void _changeStatus(DelegateStatus status, DelegateBottomNavBarController controller) {
    setState(() => selectedStatus = status);
    SoundNotification.instance.stopSound();
    controller.changeStatusOnline(
      connected: status == DelegateStatus.active ? 'active' : 'inactive',
      onSuccess: () => context.read<AuthController>().getProfile(),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.selected,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: active
                        ? const [Color(0xff20B97A), Color(0xff159663)]
                        : const [Color(0xffFF8A08), Color(0xffFF6500)],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: (active ? const Color(0xff16A36A) : const Color(0xffFD7201)).withOpacity(.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xff7D8490),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
