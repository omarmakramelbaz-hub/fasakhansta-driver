import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../helpers/images/app_images.dart';
import '../../../../../../helpers/networking/api_helper.dart';
import '../../../../../../helpers/utils/navigator_methods.dart';
import '../../../helpers/hive/hive_methods.dart';
import '../../../helpers/pusher_service/pusher_controller.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../custom_widgets/custom_image/custom_image.dart';
import '../auth/controller/auth_controller.dart';
import '../auth/screen/login_screen.dart';
import '../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'SplashScreen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColor.main2AppColor(context),
      body: const CustomImage(
        path: AppImages.delegateSplash,
        type: ImageType.asset,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Consumer<AuthController>(
            builder: (context, authController, _) {
              return ApiResponseWidget(
                loadingWidget: const SizedBox(),
                apiResponse: authController.profileResponse,
                onReload: _getData,
                isEmpty: false,
                unauthorizedWidget: const SizedBox(),
                axis: Axis.horizontal,
                child: const SizedBox(),
              );
            },
          ),
        ),
      ),
    );
  }

  void _goLogin() {
    if (!mounted || _navigated) return;
    _navigated = true;
    NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName);
  }

  void _goHome() {
    if (!mounted || _navigated) return;
    _navigated = true;
    NavigatorMethods.pushNamedAndRemoveUntil(context, DelegateBottomNavBarScreen.routeName);
  }

  void _initial() {
    if (HiveMethods.getToken() != null) {
      context.read<AuthController>().initialProfile();
      _getData();
    } else {
      Future.delayed(const Duration(milliseconds: 1200), _goLogin);
    }
  }

  Future<void> _getData() async {
    final authController = context.read<AuthController>();

    await authController.getProfile(
      onHaveId: (id, token) {
        if (!kIsWeb) {
          context.read<PusherController>().initPusher(
                channelName: 'private-user.$id',
                userId: id,
                token: token,
              );
        }
      },
      onSuccess: () {
        Future.delayed(const Duration(milliseconds: 900), _goHome);
      },
      onUnauthenticated: () {
        HiveMethods.deleteToken();
        Future.delayed(const Duration(milliseconds: 500), _goLogin);
      },
    );

    // A stale token plus a network/CORS/server error used to leave the app
    // permanently on the splash screen because only success/401 navigated.
    // Any non-success terminal state should fall back to login instead.
    final state = authController.profileResponse.state;
    if (state != ResponseState.complete && state != ResponseState.loading) {
      HiveMethods.deleteToken();
      Future.delayed(const Duration(milliseconds: 500), _goLogin);
    }
  }
}
