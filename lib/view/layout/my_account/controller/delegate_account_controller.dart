import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../model/help_model.dart';
import '../model/reports_model.dart';
import '../model/setting_model.dart';

class DelegateAccountController extends ChangeNotifier {
  //            Help               //
  void initialHelp() {
    _helpResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _help = [];
    notifyListeners();
  }

  ApiResponse _helpResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get helpResponse => _helpResponse;
  List<HelpModel> _help = [];
  List<HelpModel> get help => _help;

  Future<void> getHelp() async {
    _helpResponse = ApiResponse(state: ResponseState.loading, data: null);
    _help = [];
    notifyListeners();
    _helpResponse = await ApiHelper.instance.get(Urls.vendorHelp);
    notifyListeners();
    if (_helpResponse.state == ResponseState.complete) {
      Iterable iterable = _helpResponse.data['data'];
      _help = iterable.map((e) => HelpModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  //                 Setting               //
  void initialSetting() {
    _settingResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _setting = null;
    notifyListeners();
  }

  ApiResponse _settingResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get settingResponse => _settingResponse;
  SettingModel? _setting;
  SettingModel? get setting => _setting;

  Future<void> getSetting() async {
    _settingResponse = ApiResponse(state: ResponseState.loading, data: null);
    _setting = null;
    notifyListeners();
    _settingResponse = await ApiHelper.instance.get(Urls.vendorSetting);
    notifyListeners();
    if (_settingResponse.state == ResponseState.complete) {
      _setting = SettingModel.fromJson(_settingResponse.data['data']);
      notifyListeners();
    }
  }

  Future<void> storeContact({
    required String name,
    required String email,
    required String message,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({'name': name, 'email': email, 'message': message});
    final response = await ApiHelper.instance.post(Urls.vendorStoreContact, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': passwordConfirmation,
    });
    final response = await ApiHelper.instance.post(Urls.vendorChangePassword, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
  //======================================= reports ============================

  void initialDelegateReports() {
    _reportsResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _reports = null;
    notifyListeners();
  }

  ApiResponse _reportsResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get reportsResponse => _reportsResponse;

  ReportsModel? _reports;
  ReportsModel? get reports => _reports;
  Future<void> getDelegateReports({required String reportType}) async {
    _reportsResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();
    _reportsResponse = await ApiHelper.instance.get(Urls.delegateReports, queryParameters: {'report_type': reportType});
    notifyListeners();
    if (_reportsResponse.state == ResponseState.complete) {
      _reports = ReportsModel.fromJson(_reportsResponse.data['data']);
      notifyListeners();
    }
  }

  // ========================== update profile info ==============================

  Future<void> updateVendorProfileInfo({
    required String name,
    File? restaurantCover,
    required String restaurantName,
    required int restaurantAreaId,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({
      'name': name,
      if (restaurantCover != null) 'resturant_logo': await MultipartFile.fromFile(restaurantCover.path),
      'resturant_name': restaurantName,
      'resturant_area_id': restaurantAreaId,
    });
    final response = await ApiHelper.instance.post(Urls.updateVendorProfile, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);

      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
}
