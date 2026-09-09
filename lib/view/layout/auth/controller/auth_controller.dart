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
  bool get _isGitHubPreview => kIsWeb && Uri.base.host.endsWith('github.io');

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
      _profile = ProfileModel.fromJson(_profileResponse.data['data']);

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

    FormData body = FormData.fromMap({
      'mobile': mobile,
      'fcm_id': fcmId,
      'password': password,
      'account_type': 'delegate',
    });

    // Login must never carry an old Authorization token.
    final response = await ApiHelper.instance.post(
      Urls.login,
      body: body,
      hasToken: false,
    );

    if (response.state == ResponseState.complete) {
      final token = response.data['data']['token']?.toString();
      final accountType = response.data['data']['account_type']?.toString() ?? '';
      final id = response.data['data']['id'];

      if (token == null || token.isEmpty) {
        NavigatorMethods.loadingOff();
        CommonMethods.showError(
          message: 'تعذر حفظ جلسة تسجيل الدخول',
          apiResponse: ApiResponse(
            state: ResponseState.error,
            data: const {'message': 'تعذر حفظ جلسة تسجيل الدخول'},
          ),
        );
        return;
      }

      await HiveMethods.updateToken(token);

      if (id != null) {
        onHaveId?.call(id, token);
      }

      // On GitHub Pages, profile loading must not block opening the web preview.
      // Browser networking/CORS can differ from Android/iOS even after login succeeds.
      if (_isGitHubPreview) {
        try {
          await getProfile();
        } catch (_) {
          // The preview can still open with the safe fallback labels in Home.
        }
        NavigatorMethods.loadingOff();
        CommonMethods.showToast(message: response.data['message']?.toString() ?? 'تم تسجيل الدخول');
        onSuccess.call(accountType.isEmpty ? 'delegate' : accountType);
        notifyListeners();
        return;
      }

      await getProfile();
      NavigatorMethods.loadingOff();

      if (_profileResponse.state != ResponseState.complete) {
        CommonMethods.showError(
          message: _profileResponse.data['message'] ?? 'حدث خطأ',
          apiResponse: _profileResponse,
        );
        return;
      }

      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call(accountType);
      notifyListeners();
    } else if (_isGitHubPreview) {
      // GitHub Pages is our UI review build. If the browser cannot reach the live
      // API (for example because of browser CORS), still allow the UI preview to open.
      NavigatorMethods.loadingOff();
      CommonMethods.showToast(message: 'تم فتح وضع معاينة Drivers');
      onSuccess.call('delegate');
      notifyListeners();
    } else {
      NavigatorMethods.loadingOff();
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
