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
    final status = context.read<AuthController>().profile?.delegateStatus;
    if (status == null) return;
    final next = status == 'active' ? DelegateStatus.active : DelegateStatus.inactive;
    if (next != selectedStatus) setState(() => selectedStatus = next);
  }

  @override
  void dispose() {
    context.read<AuthController>().removeListener(_syncStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    final active = selectedStatus == DelegateStatus.active;
    return ChangeNotifierProvider(
      create: (_) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, controller, _) {
          return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xffFCFDFE),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xffE7ECF1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xffE8F9F1) : const Color(0xffFFF0E3),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xff15A869) : const Color(0xffFD7201),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocaleKey.delegateStatus.tr(), style: const TextStyle(color: navy, fontSize: 13.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 1),
                      Text(
                        active
                            ? (context.locale.languageCode == 'ar' ? 'أنت متاح لاستقبال الطلبات' : 'Available for orders')
                            : (context.locale.languageCode == 'ar' ? 'أنت غير متاح حالياً' : 'Currently unavailable'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff7D8490), fontSize: 8.8, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                InkWell(
                  onTap: () => _changeStatus(active ? DelegateStatus.inactive : DelegateStatus.active, controller),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 92,
                    height: 36,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(colors: [Color(0xff20BE7C), Color(0xff139B63)])
                          : const LinearGradient(colors: [Color(0xffE7EBEF), Color(0xffDCE2E8)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: active ? Alignment.centerLeft : Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              active ? AppLocaleKey.active.tr() : AppLocaleKey.inactive.tr(),
                              style: TextStyle(color: active ? Colors.white : const Color(0xff69717C), fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 220),
                          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
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
