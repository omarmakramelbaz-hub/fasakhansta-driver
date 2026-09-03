import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../helpers/networking/api_helper.dart';
import '../../../../../../helpers/utils/navigator_methods.dart';
import '../../../helpers/hive/hive_methods.dart';
import '../../../helpers/pusher_service/pusher_controller.dart';
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(child: _GoDriveOpening()),
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
    NavigatorMethods.pushNamedAndRemoveUntil(
      context,
      DelegateBottomNavBarScreen.routeName,
    );
  }

  void _initial() {
    if (HiveMethods.getToken() != null) {
      context.read<AuthController>().initialProfile();
      _getData();
    } else {
      Future.delayed(const Duration(milliseconds: 800), _goLogin);
    }
  }

  Future<void> _getData() async {
    final authController = context.read<AuthController>();

    try {
      await authController
          .getProfile(
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
              Future.delayed(const Duration(milliseconds: 500), _goHome);
            },
            onUnauthenticated: () {
              HiveMethods.deleteToken();
              Future.delayed(const Duration(milliseconds: 250), _goLogin);
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      HiveMethods.deleteToken();
      _goLogin();
      return;
    } catch (_) {
      HiveMethods.deleteToken();
      _goLogin();
      return;
    }

    final state = authController.profileResponse.state;
    if (state != ResponseState.complete && state != ResponseState.loading) {
      HiveMethods.deleteToken();
      _goLogin();
    }
  }
}

class _GoDriveOpening extends StatelessWidget {
  const _GoDriveOpening();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: 600,
          height: 1301,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _SplashTile('assets/images/go_drive_splash_01.webp', 130),
              SizedBox(
                width: 600,
                height: 130,
                child: ColoredBox(color: Colors.white),
              ),
              _SplashTile('assets/images/go_drive_splash_03.webp', 130),
              _SplashTile('assets/images/go_drive_splash_04.webp', 130),
              _SplashTile('assets/images/go_drive_splash_05.webp', 130),
              _SplashTile('assets/images/go_drive_splash_06.webp', 131),
              _SplashTile('assets/images/go_drive_splash_07.webp', 130),
              _SplashTile('assets/images/go_drive_splash_08.webp', 130),
              _SplashTile('assets/images/go_drive_splash_09.webp', 130),
              _SplashTile('assets/images/go_drive_splash_10.webp', 130),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashTile extends StatelessWidget {
  const _SplashTile(this.path, this.tileHeight);

  final String path;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      height: tileHeight,
      child: Image.asset(
        path,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        isAntiAlias: true,
      ),
    );
  }
}
