import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../model/contract_model.dart';

class VendorAndDeliveryController extends ChangeNotifier {
  Future<void> deliveryRegister({
    required String fullName,
    int? nationalId,
    String? drivingLicenseNo,
    File? nationalIdImage,
    File? drivingLicenseImage,
    String? workArea,
    String? estMobile,
    String? sndMobile,
    String? vodafoneCashMobile,
    required String email,
    required VoidCallback onSuccess,
  }) async {
    NavigatorMethods.loading();
    FormData body = FormData.fromMap({
      'type': 'delegate',
      'full_name': fullName,
      'national_id': nationalId,
      'driving_license_no': drivingLicenseNo,
      if (nationalIdImage != null) 'national_id_image': await MultipartFile.fromFile(nationalIdImage.path),
      if (drivingLicenseImage != null) 'driving_license_image': await MultipartFile.fromFile(drivingLicenseImage.path),
      'location': workArea,
      'mobile': estMobile,
      if (sndMobile != null) 'another_mobile': sndMobile,
      'vodafone_cash_mobile': vodafoneCashMobile,
      'email': email,
    });
    final response = await ApiHelper.instance.post(Urls.vendorSignUp, body: body);
    NavigatorMethods.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);

      notifyListeners();
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
  //    ===============>get Contract ==============

  ApiResponse _contractApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get contractApiResponse => _contractApiResponse;

  void initialContract() {
    _contractApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _contract = null;
    notifyListeners();
  }

  ContractModel? _contract;
  ContractModel? get contract => _contract;
  Future<void> getContract({required String typeContract}) async {
    _contractApiResponse = ApiResponse(state: ResponseState.loading, data: null);
    _contract = null;
    notifyListeners();
    _contractApiResponse = await ApiHelper.instance.get('${Urls.contract}$typeContract');
    notifyListeners();
    if (_contractApiResponse.state == ResponseState.complete) {
      _contract = ContractModel.fromJson(_contractApiResponse.data['data']);

      notifyListeners();
    }
  }
}
