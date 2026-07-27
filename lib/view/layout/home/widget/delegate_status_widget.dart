import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
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
    final authController = Provider.of<AuthController>(context, listen: false);

    authController.addListener(() {
      if (mounted) {
        final delegateStatus = context.read<AuthController>().profile?.delegateStatus;

        if (delegateStatus != null) {
          selectedStatus = delegateStatus == 'active' ? DelegateStatus.active : DelegateStatus.inactive;
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial check if profile is already loaded
      final delegateStatus = authController.profile?.delegateStatus;
      if (delegateStatus != null) {
        setState(() {
          selectedStatus = delegateStatus == 'active' ? DelegateStatus.active : DelegateStatus.inactive;
        });
      }
    });

    // Initialize the selectedStatus based on the current profile status
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authController = Provider.of<AuthController>(context);
    final delegateStatus = authController.profile?.delegateStatus;
    if (delegateStatus != null && selectedStatus == null) {
      setState(() {
        selectedStatus = delegateStatus == 'active' ? DelegateStatus.active : DelegateStatus.inactive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, delegateBottomNavBarController, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocaleKey.delegateStatus.tr(), style: AppTextStyle.text18BS(context)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  color: AppColor.ecececColor(context),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusButton(DelegateStatus.active, AppLocaleKey.active, delegateBottomNavBarController),
                    _buildStatusButton(DelegateStatus.inactive, AppLocaleKey.inactive, delegateBottomNavBarController),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusButton(
    DelegateStatus status,
    String label,
    DelegateBottomNavBarController delegateBottomNavBarController,
  ) {
    final isSelected = selectedStatus == status;
    return InkWell(
      onTap: () {
        setState(() => selectedStatus = status);
        SoundNotification.instance.stopSound();

        // Update the status based on selection, switching between 'active' and 'inactive'
        String newStatus = status == DelegateStatus.active ? 'active' : 'inactive';

        delegateBottomNavBarController.changeStatusOnline(
          connected: newStatus,
          onSuccess: () {
            Provider.of<AuthController>(context, listen: false).getProfile();
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.mainAppColor(context) : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(label.tr(), style: isSelected ? AppTextStyle.text14MW(context) : AppTextStyle.text14MS(context)),
      ),
    );
  }
}
