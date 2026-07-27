import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';

class DelegateBottomNavBarController extends ChangeNotifier {
  int _screenIndex = 0;
  int get screenIndex => _screenIndex;

  void updateIndex(int index) {
    _screenIndex = index;

    notifyListeners();
  }

  void onWillPop(bool pop) {
    if (screenIndex != 0) {
      updateIndex(0);
      notifyListeners();
    } else {
      NavigatorMethods.pop;
    }
  }

  Future<void> changeStatusOnline({required String connected, required VoidCallback onSuccess}) async {
    FormData body = FormData.fromMap({'connected': connected});
    NavigatorMethods.loading();
    final response = await ApiHelper.instance.post(Urls.delegateConnectedUpdate, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(apiResponse: response, message: response.data['message']);
    }
  }
}
