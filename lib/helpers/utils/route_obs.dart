import 'navigator_methods.dart';
import 'package:flutter/material.dart';

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    NavigatorMethods.currentRoute = previousRoute?.settings.name ?? '';
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    NavigatorMethods.currentRoute = route.settings.name ?? '';
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    NavigatorMethods.currentRoute = newRoute?.settings.name ?? '';
  }
}
