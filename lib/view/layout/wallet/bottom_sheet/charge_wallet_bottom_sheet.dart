import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import '../../../global/bottom_sheet/app_bottom_sheet.dart';
import '../../auth/controller/auth_controller.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/wallet_controller.dart';
import '../widget/chooseVCashOrVisaWidget.dart';

class ChargeWalletBottomSheet extends StatefulWidget {
  const ChargeWalletBottomSheet({super.key, required this.walletController, required this.myAccountController});
  final WalletController walletController;
  final MyAccountController myAccountController;

  @override
  State<ChargeWalletBottomSheet> createState() => _ChargeWalletBottomSheetState();
}

class _ChargeWalletBottomSheetState extends State<ChargeWalletBottomSheet> {
  final chargeWalletFormKey = GlobalKey<FormState>();
  final chargeAmountEc = TextEditingController();
  final chargeAmountFocusNode = FocusNode();

  Future<void> _openPaymentPage(BuildContext context, String link) async {
    final uri = Uri.tryParse(link.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme.toLowerCase() != 'http' && uri.scheme.toLowerCase() != 'https')) {
      CommonMethods.showError(message: 'تعذر فتح صفحة الدفع. رابط الدفع غير صالح.');
      return;
    }

    log('Opening payment URL: $link');

    // webview_flutter has no web implementation in this project. On the web
    // preview open the gateway in the browser instead of trying to build a
    // mobile WebView route, which previously made the payment page appear to
    // do nothing.
    if (kIsWeb) {
      final opened = await launchUrl(uri, webOnlyWindowName: '_self');
      if (!opened) {
        CommonMethods.showError(message: 'تعذر فتح صفحة الدفع. حاول مرة أخرى.');
      }
      return;
    }

    if (!context.mounted) return;

    // Push the payment page directly on Android/iOS. This deliberately avoids
    // NavigatorMethods.currentRoute because that global value can stay stale
    // after the WebView pops itself and block a later payment attempt.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CustomPaymentWebViewScreen(
          args: PaymentArgs(
            url: link,
            onFailed: () {},
            onSuccess: () {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
              widget.walletController.getWallet();
              widget.walletController.getRedirect();
              context.read<AuthController>().getProfile();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: chargeWalletFormKey,
              child: AppBottomSheet(
                title: AppLocaleKey.walletCharging.tr(),
                children: [
                  CustomFormField(
                    title: AppLocaleKey.chargeAmount.tr(),
                    controller: chargeAmountEc,
                    keyboardType: TextInputType.number,
                    focusNode: chargeAmountFocusNode,
                    onFieldSubmitted: (p0) {
                      chargeAmountFocusNode.unfocus();
                    },
                    validator: (p0) {
                      if (p0 == null || p0.isEmpty) {
                        return AppLocaleKey.enterAmount.tr();
                      } else if (p0.contains('.') ||
                          p0.contains(',') ||
                          p0.contains('-') ||
                          p0.contains('+') ||
                          p0.contains(' ') ||
                          p0.contains('*') ||
                          p0.contains('/')) {
                        return AppLocaleKey.enterAmount.tr();
                      } else if (double.tryParse(p0)! < 50) {
                        return AppLocaleKey.minimumChargeAmount.tr().replaceAll('{}', '50');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 21),
                  ChooseVCashOrVisaWidget(myAccountController: widget.myAccountController),
                  const SizedBox(height: 21),
                  Builder(
                    builder: (context) {
                      return CustomButton(
                        text: AppLocaleKey.payNow.tr(),
                        onPressed: () {
                          final valid = chargeWalletFormKey.currentState?.validate() ?? false;
                          if (!valid) return;

                          if (widget.walletController.selectedPayment == null) {
                            CommonMethods.showError(message: AppLocaleKey.youMustChoosePaymentMethod.tr());
                            return;
                          }

                          context.read<WalletController>().chargingWallet(
                            amount: chargeAmountEc.text,
                            onSuccess: (link) {
                              _openPaymentPage(context, link);
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
