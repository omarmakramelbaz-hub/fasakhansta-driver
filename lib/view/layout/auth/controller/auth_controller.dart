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
  void initialProfile() {
    _profileResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _profile = null;
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
    _profileResponse = await ApiHelper.instance.get(Urls.profile);
    notifyListeners();

    if (_profileResponse.state == ResponseState.complete) {
      final dynamic payload = _profileResponse.data;
      final dynamic data = payload is Map ? payload['data'] : null;
      if (data is Map<String, dynamic>) {
        _profile = ProfileModel.fromJson(data);
      } else if (data is Map) {
        _profile = ProfileModel.fromJson(Map<String, dynamic>.from(data));
      } else {
        _profile = null;
        _profileResponse = ApiResponse(
          state: ResponseState.error,
          data: const {'message': 'تعذر تحميل بيانات الحساب'},
        );
        notifyListeners();
        return;
      }

      final lat = double.tryParse(_profile?.lat?.toString() ?? '');
      final lng = double.tryParse(_profile?.lng?.toString() ?? '');
      if (lat != null) HiveMethods.updateLat(lat);
      if (lng != null) HiveMethods.updateLan(lng);

      if (_profile?.id != null && _profile?.token != null) {
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

  Future<void> login({
    required String mobile,
    required String password,
    required Function(String accountType) onSuccess,
    void Function(int id, String token)? onHaveId,
  }) async {
    NavigatorMethods.loading();

    String fcmId = '';
    if (!kIsWeb) {
      try {
        fcmId = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 5)) ?? '';
      } catch (_) {
        fcmId = '';
      }
    }

    final FormData body = FormData.fromMap({
      'mobile': mobile,
      'fcm_id': fcmId,
      'password': password,
      'account_type': 'delegate',
    });

    // Login must not carry a stale bearer token from an older session.
    final response = await ApiHelper.instance.post(
      Urls.login,
      body: body,
      hasToken: false,
    );

    if (response.state == ResponseState.complete) {
      final dynamic payload = response.data;
      final dynamic data = payload is Map ? payload['data'] : null;
      final String token = data is Map ? (data['token']?.toString().trim() ?? '') : '';
      final String accountType = data is Map ? (data['account_type']?.toString().trim() ?? '') : '';
      final dynamic id = data is Map ? data['id'] : null;

      if (token.isEmpty) {
        NavigatorMethods.loadingOff();
        CommonMethods.showError(message: 'تعذر حفظ جلسة تسجيل الدخول');
        return;
      }

      // This await is essential on Flutter Web: wallet/profile/report requests must
      // not start until IndexedDB has persisted the bearer token.
      await HiveMethods.updateToken(token);

      if (id is int) {
        onHaveId?.call(id, token);
      } else if (id != null) {
        final parsedId = int.tryParse(id.toString());
        if (parsedId != null) onHaveId?.call(parsedId, token);
      }

      NavigatorMethods.loadingOff();
      CommonMethods.showToast(
        message: payload is Map ? (payload['message']?.toString() ?? 'تم تسجيل الدخول') : 'تم تسجيل الدخول',
      );

      // Open the authenticated app immediately. Profile is refreshed afterwards;
      // it must never block wallet/orders/reports from using the valid token.
      onSuccess.call(accountType.isEmpty ? 'delegate' : accountType);
      notifyListeners();
      getProfile();
      return;
    }

    NavigatorMethods.loadingOff();
    final dynamic payload = response.data;
    final String message = payload is Map ? (payload['message']?.toString().trim() ?? '') : '';
    CommonMethods.showError(
      message: message.isNotEmpty ? message : 'تعذر تسجيل الدخول. حاول مرة أخرى.',
      apiResponse: response,
    );
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
    final response = await ApiHelper.instance.post('${Urls.updateVendorLocation}$resturantId/resturant-location', body: body);
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
