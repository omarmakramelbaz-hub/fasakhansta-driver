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
      final auth = context.read<AuthController>();
      auth.getProfile().then((_) {
        if (!mounted) return;
        setState(() {
          balance = auth.profile?.balance;
          minWallet = auth.profile?.minWallet;
          minWalletDisabled = auth.profile?.minWalletDisabled;
        });
      });
    });
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('balance.updated', _handleWalletUpdate);
  }

  void _handleWalletUpdate(PusherEvent event) {
    try {
      final data = jsonDecode(event.data) as Map<String, dynamic>;
      pusherWalletAmount = num.parse(data['user_balance']?.toString() ?? '0').toStringAsFixed(2);
      if (!mounted) return;
      context.read<AuthController>().getProfile().then((_) {
        if (!mounted) return;
        setState(() {
          balance = context.read<AuthController>().profile?.balance;
          minWallet = context.read<AuthController>().profile?.minWallet;
          minWalletDisabled = context.read<AuthController>().profile?.minWalletDisabled;
        });
      });
      setState(() {});
    } catch (e, s) {
      log('Wallet update error: $e');
      log('$s');
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
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              width: double.infinity,
              height: 118,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff0B3A64), navy],
                ),
                boxShadow: [BoxShadow(color: navy.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    bottom: -60,
                    child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xff2F80ED).withOpacity(.08))),
                  ),
                  Positioned(
                    left: 15,
                    top: 17,
                    child: Image.asset(
                      AppImages.walletImage,
                      width: 76,
                      height: 66,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 58),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    bottom: 11,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(.27)),
                      ),
                      child: Row(
                        children: [
                          Icon(context.locale.languageCode == 'ar' ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Colors.white, size: 17),
                          const SizedBox(width: 3),
                          Text(_t('عرض المحفظة', 'View wallet'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 16,
                    top: 12,
                    bottom: 10,
                    child: SizedBox(
                      width: 185,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 17),
                              const SizedBox(width: 6),
                              Text(_t('محفظتي', 'My wallet'), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(AppLocaleKey.myCurrentBalance.tr(), style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 9.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          balance == null
                              ? const CustomShimmer(height: 23, width: 100, radius: 7, shimmerColor: Color(0xffFF8A08))
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    AppLocaleKey.pound.tr().replaceAll('{}', pusherWalletAmount ?? balance?.toStringAsFixed(0) ?? '0'),
                                    style: const TextStyle(color: Colors.white, fontSize: 27, height: 1, fontWeight: FontWeight.w900),
                                  ),
                                ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white.withOpacity(.10))),
                            child: Text(_t('المحفظة الإلكترونية', 'Digital wallet'), style: TextStyle(color: Colors.white.withOpacity(.82), fontSize: 8.7, fontWeight: FontWeight.w700)),
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
            const SizedBox(height: 6),
            _alert(context, AppLocaleKey.pleaseChargeYourBalance.tr(args: [minWallet!.toString()])),
          ],
          if (balance! < minWalletDisabled!) ...[
            const SizedBox(height: 6),
            _alert(context, AppLocaleKey.yourAccountIsCurrentlySuspended.tr(args: [minWallet!.toString()])),
          ],
        ],
      ],
    );
  }

  Widget _alert(BuildContext context, String message) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, WalletScreen.routeName),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColor.ffebbcColor(context), border: Border.all(color: const Color(0xffF6D98A))),
          child: Row(
            children: [
              Container(width: 28, height: 28, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(9)), child: const CustomImage(path: AppImages.infoIcon, type: ImageType.svg)),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: const TextStyle(color: Color(0xff66511F), fontSize: 9.5, fontWeight: FontWeight.w600, height: 1.3))),
            ],
          ),
        ),
      ),
    );
  }
}
