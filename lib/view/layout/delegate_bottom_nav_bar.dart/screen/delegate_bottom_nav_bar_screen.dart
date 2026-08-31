import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../global/chat/screen/admin_chat_screen.dart';
import '../../../global/chat/screen/chat_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../../home/screen/home_delegate_screen.dart';
import '../../home/screen/location_delegate.dart';
import '../../my_account/screen/my_account_delegate_screen.dart';
import '../../notification/model/notfication_from_firebase_model.dart';
import '../../notification/screen/notification_delegate_screen.dart';
import '../../order/screen/order_delegate_screen.dart';
import '../../order/screen/order_details_delegate_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/delegate_bottom_nav_bar_controller.dart';

class DelegateBottomNavBarScreen extends StatefulWidget {
  static const String routeName = 'DelegateBottomNavBarScreen';
  const DelegateBottomNavBarScreen({super.key});

  @override
  State<DelegateBottomNavBarScreen> createState() => _DelegateBottomNavBarScreenState();
}

class _DelegateBottomNavBarScreenState extends State<DelegateBottomNavBarScreen> {
  String? delegateAddress;
  PusherController? _pusherController;

  @override
  void initState() {
    super.initState();

    // Firebase Messaging and realtime hooks are native-runtime features in this
    // project. The GitHub Pages build is only a UI preview, so do not touch
    // them on web; doing so can throw before the first frame and leave a blank
    // grey page.
    if (!kIsWeb) {
      _initialNotification();
      _pusherController = context.read<PusherController>();
      _pusherController!.addEventListener('delegate.updated', _handleDelegateUpdated);
    }
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      var jsonData = jsonDecode(event.data) as Map<String, dynamic>;

      if (mounted) {
        var status = jsonData['order_id']['status']?.toString();
        var orderNo = jsonData['order_id']['order_no']?.toString();
        log('*************************************************************');
        log(jsonData.toString());
        if (status != null && status == 'pending') {
          SoundNotification.instance.playLongSound();
          CommonMethods.showToast(message: '${AppLocaleKey.thereIsANewOrder.tr()} $orderNo');
        } else {
          CommonMethods.showToast(message: '${AppLocaleKey.thereIsANewOrderWithStatus.tr()} $orderNo');
        }
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController?.removeEventListener('delegate.updated', _handleDelegateUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, delegateBottomNavBarController, _) => PopScope(
          canPop: delegateBottomNavBarController.screenIndex == 0,
          onPopInvoked: delegateBottomNavBarController.onWillPop,
          child: Scaffold(
            appBar: CustomAppBar(
              context,
              height: 80,
              leadingWidth: MediaQuery.of(context).size.width / 2,
              leading: InkWell(
                onTap: () {
                  NavigatorMethods.pushNamed(context, DelegateLocationScreen.routeName);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocaleKey.address.tr(),
                          style: AppTextStyle.textW16R(context).copyWith(color: AppColor.blackColor(context)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                context.watch<AuthController>().profile?.areaTitle ?? '',
                                style: AppTextStyle.text16BS(context).copyWith(color: AppColor.blackColor(context)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const SizedBox(),
              actions: const [Gap(10)],
            ),
            resizeToAvoidBottomInset: false,
            body: [
              const HomeDelegateScreen(),
              const OrdersDelegateScreen(),
              const NotificationsDelegateScreen(),
              const MyAccountDelegateScreen(),
            ][context.watch<DelegateBottomNavBarController>().screenIndex],
            bottomNavigationBar: BottomAppBar(
              color: AppColor.whiteColor(context),
              shape: const CircularNotchedRectangle(),
              notchMargin: 10,
              child: SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<DelegateBottomNavBarController>().updateIndex(0);
                            },
                            icon: SvgPicture.asset(
                              delegateBottomNavBarController.screenIndex == 0
                                  ? AppImages.homeFillIcon
                                  : AppImages.homeIcon,
                              colorFilter: ColorFilter.mode(
                                delegateBottomNavBarController.screenIndex == 0
                                    ? AppColor.mainAppColor(context)
                                    : AppColor.greyColor(context),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          Text(
                            AppLocaleKey.home.tr(),
                            style: delegateBottomNavBarController.screenIndex == 0
                                ? AppTextStyle.text14RM(context)
                                : AppTextStyle.text14RG(context),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<DelegateBottomNavBarController>().updateIndex(1);
                            },
                            icon: SvgPicture.asset(
                              delegateBottomNavBarController.screenIndex == 1
                                  ? AppImages.orderFillIcon
                                  : AppImages.ordersIcon,
                              colorFilter: ColorFilter.mode(
                                delegateBottomNavBarController.screenIndex == 1
                                    ? AppColor.mainAppColor(context)
                                    : AppColor.greyColor(context),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          Text(
                            AppLocaleKey.orders.tr(),
                            style: delegateBottomNavBarController.screenIndex == 1
                                ? AppTextStyle.text14RM(context)
                                : AppTextStyle.text14RG(context),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<DelegateBottomNavBarController>().updateIndex(2);
                            },
                            icon: SvgPicture.asset(
                              delegateBottomNavBarController.screenIndex == 2
                                  ? AppImages.notificationFillIcon
                                  : AppImages.notificationsIcon,
                              colorFilter: ColorFilter.mode(
                                delegateBottomNavBarController.screenIndex == 2
                                    ? AppColor.mainAppColor(context)
                                    : AppColor.greyColor(context),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          Text(
                            AppLocaleKey.notifications.tr(),
                            style: delegateBottomNavBarController.screenIndex == 2
                                ? AppTextStyle.text14RM(context)
                                : AppTextStyle.text14RG(context),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<DelegateBottomNavBarController>().updateIndex(3);
                            },
                            icon: SvgPicture.asset(
                              delegateBottomNavBarController.screenIndex == 3
                                  ? AppImages.accountFillIcon
                                  : AppImages.myAccountIcon,
                              colorFilter: ColorFilter.mode(
                                delegateBottomNavBarController.screenIndex == 3
                                    ? AppColor.mainAppColor(context)
                                    : AppColor.greyColor(context),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          Text(
                            AppLocaleKey.myAccount.tr(),
                            style: delegateBottomNavBarController.screenIndex == 3
                                ? AppTextStyle.text14RM(context)
                                : AppTextStyle.text14RG(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationHelper _notificationHelper = NotificationHelper();

  void _initialNotification() {
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        log('${message.notification?.title}');
        log('${message.notification?.body}');
        log(message.data.toString());
        SoundNotification.instance.stopSound();
        _onNotificationTaped(message);
      }
    });
    FirebaseMessaging.onMessage.listen((message) {
      log('${message.notification?.title}');
      log('${message.notification?.body}');
      log(message.data.toString());
      _notificationHelper.display(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      SoundNotification.instance.stopSound();
      _onNotificationTaped(message);
    });
    _requestPermission();
  }

  Future<NotificationSettings> _requestPermission() async {
    return _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _onNotificationTaped(RemoteMessage message) {
    log('Navigating to From Bottom Nav Bar');
    SoundNotification.instance.stopSound();
    final msg = json.encode(message.data);
    var body = json.decode(msg);
    final data = NotificationFromFirebaseMode.fromJson(body);
    switch (data.notificationType.toString()) {
      case '1':
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext ?? context,
          OrderDetailsDelegateScreen.routeName,
          arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: int.parse(data.orderId.toString())),
        );
        break;
      case '3':
        NavigatorMethods.pushNamed(AppRouters.navigatorKey.currentContext ?? context, WalletScreen.routeName);
        break;
      case '8':
        log('message');
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext!,
          ChatScreen.routeName,
          arguments: ChatScreenArgs(
            senderDeviceToken: data.receiverDeviceToken.toString(),
            accountType: data.accountType.toString(),
            isVendor: false,
            vendorDeviceToken: data.receiverDeviceToken.toString(),
            receiverDeviceToken: data.senderDeviceToken.toString(),
            senderName: data.receiverName.toString(),
            receiverName: data.senderName.toString(),
            orderId: data.orderId.toString(),
          ),
        );
        break;
      case '10':
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext!,
          AdminChatScreen.routeName,
          arguments: AdminChatScreenArgs(
            senderId: data.receiverId.toString(),
            receiverId: data.senderId.toString(),
            receiverDeviceToken: data.senderDeviceToken.toString(),
            senderDeviceToken: data.receiverDeviceToken.toString(),
            senderName: data.receiverName.toString(),
            receiverName: data.senderName.toString(),
            accountType: data.accountType.toString(),
            isToVendor: true,
            vendorDeviceToken: data.receiverDeviceToken.toString(),
          ),
        );
        break;
      default:
        NavigatorMethods.pushNamed(
          AppRouters.navigatorKey.currentContext ?? context,
          DelegateBottomNavBarScreen.routeName,
        );
    }
  }
}
