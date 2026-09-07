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
    final active = selectedStatus == DelegateStatus.active;

    return ChangeNotifierProvider(
      create: (_) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, controller, _) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xffFCFDFE),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xffE8EDF2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? const Color(0xffE8F9F1) : const Color(0xffFFF0E3),
                        ),
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? const Color(0xff15A869) : const Color(0xffFD7201),
                            boxShadow: [
                              BoxShadow(
                                color: (active ? const Color(0xff15A869) : const Color(0xffFD7201)).withOpacity(.24),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocaleKey.delegateStatus.tr(),
                              style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              active
                                  ? (context.locale.languageCode == 'ar'
                                      ? 'أنت متاح لاستقبال الطلبات'
                                      : 'You are available for orders')
                                  : (context.locale.languageCode == 'ar'
                                      ? 'أنت غير متاح حالياً'
                                      : 'You are currently unavailable'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff7D8490),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _PremiumStatusToggle(
                  active: active,
                  activeLabel: AppLocaleKey.active.tr(),
                  inactiveLabel: AppLocaleKey.inactive.tr(),
                  onTap: () => _changeStatus(
                    active ? DelegateStatus.inactive : DelegateStatus.active,
                    controller,
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

class _PremiumStatusToggle extends StatelessWidget {
  const _PremiumStatusToggle({
    required this.active,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.onTap,
  });

  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          width: 108,
          height: 46,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff20BE7C), Color(0xff139B63)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffE7EBEF), Color(0xffDCE2E8)],
                  ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xff16A36A).withOpacity(.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Align(
                alignment: active ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: active ? 15 : 8,
                    right: active ? 8 : 11,
                  ),
                  child: Text(
                    active ? activeLabel : inactiveLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xff69717C),
                      fontSize: active ? 13 : 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOutCubic,
                alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
