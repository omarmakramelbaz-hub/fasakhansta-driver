import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
            borderRadius: BorderRadius.circular(26),
            child: Ink(
              width: double.infinity,
              height: 156,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff082A4D), Color(0xff123C65)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff082A4D).withOpacity(.20),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    top: -38,
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.05),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 35,
                    bottom: -58,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xffFD7201).withOpacity(.16),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocaleKey.myCurrentBalance.tr(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.74),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_outward_rounded, color: Colors.white.withOpacity(.65), size: 17),
                              ],
                            ),
                            const SizedBox(height: 13),
                            balance == null
                                ? const CustomShimmer(
                                    height: 26,
                                    width: 120,
                                    radius: 7,
                                    shimmerColor: Color(0xffFF8A08),
                                  )
                                : Text(
                                    AppLocaleKey.pound.tr().replaceAll(
                                      '{}',
                                      pusherWalletAmount ?? balance?.toStringAsFixed(0) ?? '0',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                            const SizedBox(height: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.09),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(.10)),
                              ),
                              child: Text(
                                context.locale.languageCode == 'ar' ? 'المحفظة الإلكترونية' : 'Digital wallet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.78),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xffFF9A1A), Color(0xffFF6500)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffFD7201).withOpacity(.30),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          AppImages.walletIcon,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ],
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
