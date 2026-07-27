import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../global/widget/no_notification_widget.dart';
import '../controller/notifications_delegate_Controller.dart';
import '../model/notifications_model.dart';
import '../widget/notification_delegate_widget.dart';

class NotificationsDelegateScreen extends StatefulWidget {
  const NotificationsDelegateScreen({super.key});

  @override
  State<NotificationsDelegateScreen> createState() => _NotificationsDelegateScreenState();
}

class _NotificationsDelegateScreenState extends State<NotificationsDelegateScreen> {
  late PusherController _pusherController;
  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsDelegateController>().initialNotifications();
      context.read<NotificationsDelegateController>().getNotifications().then((value) => setState(() {}));
    });
    _pusherController.addEventListener('notification.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      var jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      log('Notification updated: $jsonData');
      if (mounted) {
        var notification = NotificationsModel.fromJson(jsonData);
        context.read<NotificationsDelegateController>().addNotificationToTop(notification);
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NotificationsDelegateController>(
        builder: (context, notificationsController, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Text(
            //   tr(AppLocaleKey.today),
            //   style: AppTextStyle.text18BS(context),
            // ),
            const SizedBox(height: 30),

            ApiResponseWidget(
              apiResponse: notificationsController.notificationsResponse,
              onReload: () => notificationsController.getNotifications(),
              isEmpty: notificationsController.notifications.isEmpty,
              emptyWidget: const NoNotificationWidget(),
              child: Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColor.whiteColor(context),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(36), topLeft: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.greyColor(context).withOpacity(.2),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 20),
                        // Text(
                        //   "اليوم ",
                        //   style: AppTextStyle.text16MS(context),
                        // ),
                        const SizedBox(height: 25),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await notificationsController.getNotifications();
                            },
                            child: ListView.separated(
                              itemCount: notificationsController.notifications.length,
                              itemBuilder: (context, index) {
                                return NotificationDelegateWidget(
                                  notificationType:
                                      notificationsController
                                          .notifications[index]
                                          .data
                                          ?.notificationData
                                          ?.notificationType ??
                                      0,
                                  notification: notificationsController.notifications[index],
                                  orderId:
                                      notificationsController.notifications[index].data?.notificationData?.orderId ?? 0,
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) =>
                                  const Padding(padding: EdgeInsets.only(bottom: 25)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
