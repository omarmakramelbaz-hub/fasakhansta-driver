import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../my_account/model/areas_model.dart';
import '../model/profile_model.dart';

class AuthController extends ChangeNotifier {
  ///                           profile                                     //
  void initialProfile() {
    _profileResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _profile = null;
    //notifyListeners();
  }

  ApiResponse _profileResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get profileResponse => _profileResponse;
  ProfileModel? _profile;
  ProfileModel? get profile => _profile;
  Future<void> getProfile({
    void Function(int id, String token)? onHaveId,
    VoidCallback? onSuccess,
    VoidCallback? onUnauthenticated,
  }) async {
    _profileResponse = ApiResponse(state: ResponseState.loading, data: null);
    //notifyListeners();
    _profileResponse = await ApiHelper.instance.get(Urls.profile);
    notifyListeners();
    if (_profileResponse.state == ResponseState.complete) {
      _profile = ProfileModel.fromJson(_profileResponse.data['data']);
      HiveMethods.updateLat(double.parse(_profile!.lat ?? '0'));
      HiveMethods.updateLan(double.parse(_profile!.lng ?? '0'));
      if (_profile?.id != null) {
        onHaveId?.call(_profile!.id!, _profile!.token!);
      }
      notifyListeners();
      onSuccess?.call();
    }
    if (_profileResponse.state == ResponseState.unauthorized) {
      notifyListeners();
      onUnauthenticated?.call();
    }
  }

  //                               login                                       //
  Future<void> login({
    required String mobile,
    required String password,
    required Function(String accountType) onSuccess,
    void Function(int id, String token)? onHaveId,
  }) async {
    NavigatorMethods.loading();

    // Firebase is intentionally not initialized in the GitHub Pages UI preview.
    // Calling FirebaseMessaging.getToken() there leaves the login loader stuck.
    // Use an empty FCM id on Web; native Android/iOS still sends the real token.
    String fcmId = '';
    if (!kIsWeb) {
      try {
        fcmId = await FirebaseMessaging.instance
                .getToken()
                .timeout(const Duration(seconds: 5)) ??
            '';
      } catch (_) {
        // Login must not be blocked if FCM is temporarily unavailable.
        fcmId = '';
      }
    }

    FormData body = FormData.fromMap({
      'mobile': mobile,
      'fcm_id': fcmId,
      'password': password,
      'account_type': 'delegate',
    });
    final response = await ApiHelper.instance.post(Urls.login, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      HiveMethods.updateToken(response.data['data']['token']);
      if (response.data['data']['id'] != null && response.data['data']['token'] != null) {
        onHaveId?.call(response.data['data']['id'], response.data['data']['token']);
      }

      getProfile();
      CommonMethods.showToast(message: response.data['message']);

      onSuccess.call(response.data['data']['account_type']);

      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> logout({required VoidCallback onSuccess}) async {
    NavigatorMethods.loading();
    final response = await ApiHelper.instance.post(Urls.vendorLogout);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      _profile = null;

      HiveMethods.deleteToken();
      notifyListeners();
      onSuccess.call();
    } else {
      onSuccess.call();

      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //================================== areas =============================
  void initialAreas() {
    _areasResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _areas = [];
    notifyListeners();
  }

  ApiResponse _areasResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get areasResponse => _areasResponse;

  List<AreasModel> _areas = [];
  List<AreasModel> get areas => _areas;

  Future<void> getAreas() async {
    _areasResponse = ApiResponse(state: ResponseState.loading, data: null);
    _areas = [];
    notifyListeners();
    _areasResponse = await ApiHelper.instance.get(Urls.areas);
    notifyListeners();

    if (_areasResponse.state == ResponseState.complete) {
      Iterable iterable = _areasResponse.data['data'];
      _areas = iterable.map((e) => AreasModel.fromJson(e)).toList();
      notifyListeners();
    }
  }
  //=================================== update vendor location =============================

  Future<void> updateVendorLocation({
    required int resturantId,
    required num lat,
    required num lng,
    required String countryName,
    required String cityName,
    required String address,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();

    FormData body = FormData.fromMap({
      'lat': lat,
      'lng': lng,
      'country_name': countryName,
      'city_name': cityName,
      'address': address,
    });
    final response = await ApiHelper.instance.post(
      '${Urls.updateVendorLocation}$resturantId/resturant-location',
      body: body,
    );
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> updateDelegateLocation({required num lat, required num lng, required VoidCallback onSuccess}) async {
    NavigatorMethods.loading();

    FormData body = FormData.fromMap({'lat': lat, 'lng': lng});
    final response = await ApiHelper.instance.post(Urls.updatePosition, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  // ==================================== delete account =============================
  Future<void> deleteAccount({required String mobileCode, required VoidCallback onSuccess}) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({'password': mobileCode});
    final response = await ApiHelper.instance.post(Urls.deleteAccount, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
}
