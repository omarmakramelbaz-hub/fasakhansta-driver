import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../model/area_model.dart';

class AuthDelegateController extends ChangeNotifier {
  ///                           profile                                     //

  Future<void> updateDelegateInfo({
    required String name,
    required String email,
    // required int id,
    File? photoProfile,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({
      'name': name,
      'email': email,
      // 'area_id': id,
      'photo_profile': photoProfile != null ? await MultipartFile.fromFile(photoProfile.path) : null,
    });
    final response = await ApiHelper.instance.post(Urls.delegateUpdateProfile, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  void initialArea() {
    _areaResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _area = [];
    notifyListeners();
  }

  ApiResponse _areaResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get areaResponse => _areaResponse;
  List<AreaModel> _area = [];
  List<AreaModel> get area => _area;

  Future<void> getArea() async {
    _areaResponse = ApiResponse(state: ResponseState.loading, data: null);
    _area = [];
    notifyListeners();
    _areaResponse = await ApiHelper.instance.get(Urls.areas);
    notifyListeners();
    if (_areaResponse.state == ResponseState.complete) {
      Iterable iterable = _areaResponse.data['data'];
      _area = iterable.map((e) => AreaModel.fromJson(e)).toList();
      notifyListeners();
    }
  }
  //================================= update Photo Profile ======================

  Future<void> updateDelegatePhoto({File? photoProfile, required VoidCallback onSuccess}) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({
      'photo_profile': photoProfile != null ? await MultipartFile.fromFile(photoProfile.path) : null,
    });
    final response = await ApiHelper.instance.post(Urls.delegateUpdateProfile, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
}
