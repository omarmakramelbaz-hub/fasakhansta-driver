import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../auth/controller/auth_controller.dart';
import '../../wallet/screen/wallet_screen.dart';

class MyCurrentBalanceWidget extends StatefulWidget {
  const MyCurrentBalanceWidget({super.key});

  @override
  State<MyCurrentBalanceWidget> createState() => _MyCurrentBalanceWidgetState();
}

class _MyCurrentBalanceWidgetState extends State<MyCurrentBalanceWidget> {
  num? balance;
  num? minWallet;
  num? minWalletDisabled;
  late PusherController _pusherController;
  String? pusherWalletAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      authController.getProfile().then((_) {
        if (!mounted) return;
        setState(() {
          balance = authController.profile?.balance;
          minWallet = authController.profile?.minWallet;
          minWalletDisabled = authController.profile?.minWalletDisabled;
        });
      });
    });
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('balance.updated', _handleWalletUpdate);
  }

  void _handleWalletUpdate(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      log('Wallet updated: $jsonData');
      final amount = jsonData['user_balance']?.toString() ?? '0';
      pusherWalletAmount = num.parse(amount).toStringAsFixed(2);
      if (mounted) {
        context.read<AuthController>().getProfile().then((_) {
          if (!mounted) return;
          setState(() {
            balance = context.read<AuthController>().profile?.balance;
            minWallet = context.read<AuthController>().profile?.minWallet;
            minWalletDisabled = context.read<AuthController>().profile?.minWalletDisabled;
          });
        });
        setState(() {});
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('balance.updated', _handleWalletUpdate);
    super.dispose();
  }

  String _t(String ar, String en) => context.locale.languageCode == 'ar' ? ar : en;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const orange = Color(0xffFD7201);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
            borderRadius: BorderRadius.circular(27),
            child: Ink(
              width: double.infinity,
              height: 182,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff0B3A64), navy],
                ),
                boxShadow: [
                  BoxShadow(color: navy.withOpacity(.21), blurRadius: 26, offset: const Offset(0, 12)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -52,
                    top: -82,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.035)),
                    ),
                  ),
                  Positioned(
                    right: -36,
                    bottom: -70,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xff2F80ED).withOpacity(.08)),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    top: 22,
                    child: Image.asset(
                      AppImages.walletImage,
                      width: 91,
                      height: 86,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(22)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 38),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 19,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.04),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(.28)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            context.locale.languageCode == 'ar' ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _t('عرض المحفظة', 'View wallet'),
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 18,
                    top: 17,
                    bottom: 16,
                    child: SizedBox(
                      width: 205,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 19),
                              const SizedBox(width: 7),
                              Text(
                                _t('محفظتي', 'My wallet'),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.arrow_outward_rounded, color: Colors.white.withOpacity(.58), size: 16),
                              const SizedBox(width: 5),
                              Text(
                                AppLocaleKey.myCurrentBalance.tr(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.73),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          balance == null
                              ? const CustomShimmer(
                                  height: 31,
                                  width: 122,
                                  radius: 8,
                                  shimmerColor: Color(0xffFF8A08),
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    AppLocaleKey.pound.tr().replaceAll(
                                      '{}',
                                      pusherWalletAmount ?? balance?.toStringAsFixed(0) ?? '0',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 31,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                          const Spacer(),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.08),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: Colors.white.withOpacity(.12)),
                              ),
                              child: Text(
                                _t('المحفظة الإلكترونية', 'Digital wallet'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.82),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
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
        ),
        if (balance != null && minWallet != null && minWalletDisabled != null) ...[
          if (balance! >= minWalletDisabled! && balance! <= minWallet!) ...[
            const SizedBox(height: 12),
            _buildAlertContainer(context, AppLocaleKey.pleaseChargeYourBalance.tr(args: [minWallet!.toString()])),
          ],
          if (balance! < minWalletDisabled!) ...[
            const SizedBox(height: 12),
            _buildAlertContainer(context, AppLocaleKey.yourAccountIsCurrentlySuspended.tr(args: [minWallet!.toString()])),
          ],
        ],
      ],
    );
  }

  Widget _buildAlertContainer(BuildContext context, String message) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, WalletScreen.routeName),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColor.ffebbcColor(context),
            border: Border.all(color: const Color(0xffF6D98A)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CustomImage(path: AppImages.infoIcon, type: ImageType.svg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xff66511F),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
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
