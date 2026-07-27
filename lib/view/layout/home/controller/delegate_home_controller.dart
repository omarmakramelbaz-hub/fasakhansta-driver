// ignore_for_file: unnecessary_getters_setters

import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../order/model/delegate_order_model.dart';
import '../../order/model/delegate_pagination_model.dart';

class HomeDelegateController extends ChangeNotifier {
  void initialCurrentDelegateOrders() {
    _currentDelegateOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _currentDelegateOrders = [];
    _currentOrders = null;
    _currentOrderPage = 1;
    _currentOrdersHasPagination = true;
    _currentIsPaginating = false;
    notifyListeners();
  }

  ApiResponse _currentDelegateOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get currentDelegateOrdersResponse => _currentDelegateOrdersResponse;

  List<DelegateOrdersModel> _currentDelegateOrders = [];
  List<DelegateOrdersModel> get currentDelegateOrders => _currentDelegateOrders;
  DelegateModel? _currentOrders;
  DelegateModel? get currentOrders => _currentOrders;

  int _currentOrderPage = 1;
  int get currentOrderPage => _currentOrderPage;

  set currentOrderPage(int value) {
    _currentOrderPage = value;
  }

  bool _currentOrdersHasPagination = true;
  bool get currentOrdersHasPagination => _currentOrdersHasPagination;
  bool _currentIsPaginating = false;
  bool get currentIsPaginating => _currentIsPaginating;

  Future<void> getCurrentDelegateOrders({int? pageNumber}) async {
    if (_currentOrderPage == 1) {
      _currentDelegateOrdersResponse = ApiResponse(state: ResponseState.loading, data: null);
      _currentDelegateOrders = [];
      _currentOrders = null;
      notifyListeners();
    } else {
      _currentIsPaginating = true;
      notifyListeners();
    }

    _currentDelegateOrdersResponse = await ApiHelper.instance.get(
      Urls.delegateHomeCurrentOrders,
      queryParameters: {'page': pageNumber ?? _currentOrderPage},
    );
    notifyListeners();

    if (_currentDelegateOrdersResponse.state == ResponseState.complete) {
      Iterable iterable = _currentDelegateOrdersResponse.data['data']['data'];

      _currentOrders = DelegateModel.fromJson(_currentDelegateOrdersResponse.data['data']);

      if (_currentOrderPage == _currentDelegateOrdersResponse.data['data']['meta']['last_page']) {
        _currentOrdersHasPagination = false;
        // CommonMethods.showToast(message: "No more orders");
        // notifyListeners();
      } else {
        _currentOrderPage++;
        _currentOrdersHasPagination = true;
        notifyListeners();
      }
      _currentDelegateOrders.addAll(iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList());

      notifyListeners();
    }

    _currentIsPaginating = false;
    notifyListeners();
  }

  //============================ home current orders orders ===================================
  void initialCurrentDelegateOrdersHome() {
    _currentDelegateOrdersHomeResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _currentDelegateOrdersHome = null;
    notifyListeners();
  }

  ApiResponse _currentDelegateOrdersHomeResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get currentDelegateOrdersHomeResponse => _currentDelegateOrdersHomeResponse;

  DelegateOrdersModel? _currentDelegateOrdersHome;
  DelegateOrdersModel? get currentDelegateOrdersHome => _currentDelegateOrdersHome;
  Future<void> getCurrentDelegateOrdersHome() async {
    _currentDelegateOrdersHomeResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();

    _currentDelegateOrdersHomeResponse = await ApiHelper.instance.get(Urls.delegateCurrentOrdersHome);
    notifyListeners();

    // Check if the response is complete and data is not null and is a Map
    if (_currentDelegateOrdersHomeResponse.state == ResponseState.complete &&
        _currentDelegateOrdersHomeResponse.data != null &&
        _currentDelegateOrdersHomeResponse.data is Map<String, dynamic>) {
      if (_currentDelegateOrdersHomeResponse.data['data'] != null) {
        // Ensure the 'data' key exists in the map before accessing it
        if (_currentDelegateOrdersHomeResponse.data.containsKey('data')) {
          _currentDelegateOrdersHome = DelegateOrdersModel.fromJson(_currentDelegateOrdersHomeResponse.data['data']);
        } else {
          // Handle the case where 'data' key is not present
          log("Key 'data' not found in responsse");
        }
      } else {
        _currentDelegateOrdersHome = null;
      }
    } else {
      // Handle the case where the data is null or not a Map
      log('Response data is null or not a Map<String, dynamic>');
    }

    notifyListeners();
  }

  //============================ ongoing orders ==============================
  void initialOngoingDelegateOrdersHome() {
    _ongoingDelegateOrdersHomeResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _ongoingDelegateOrdersHome = null;
    notifyListeners();
  }

  ApiResponse _ongoingDelegateOrdersHomeResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get ongoingDelegateOrdersHomeResponse => _ongoingDelegateOrdersHomeResponse;

  DelegateOrdersModel? _ongoingDelegateOrdersHome;
  DelegateOrdersModel? get ongoingDelegateOrdersHome => _ongoingDelegateOrdersHome;

  Future<void> getOngoingDelegateOrdersHome() async {
    _ongoingDelegateOrdersHomeResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();
    _ongoingDelegateOrdersHomeResponse = await ApiHelper.instance.get(Urls.delegateOngoingOrdersHome);
    notifyListeners();
    if (_ongoingDelegateOrdersHomeResponse.state == ResponseState.complete) {
      if (_ongoingDelegateOrdersHomeResponse.data['data'] != null) {
        _ongoingDelegateOrdersHome = DelegateOrdersModel.fromJson(_ongoingDelegateOrdersHomeResponse.data['data']);
        notifyListeners();
      } else {
        _ongoingDelegateOrdersHome = null;
      }
    }
  }

  //============================ delegate pending  home ==============================
  void addOrderToTop(DelegateOrdersModel delegateOrdersModel) {
    // Check if the order already exists in the list
    final exists = _pendingDelegateOrders.any((order) => order.id == delegateOrdersModel.id);

    if (!exists) {
      updateTotalPending((pendingOrders?.meta?.total ?? 0) + 1);
      _pendingDelegateOrders.insert(0, delegateOrdersModel);
      // Update the total count (if required)
      pendingOrders?.meta?.total = (pendingOrders?.meta?.total ?? 0) + 1;
      notifyListeners(); // Notify listeners to update the UI
    } else {
      log('Order with ID ${delegateOrdersModel.id} already exists.');
    }
  }

  int totalPending = 0;

  void updateTotalPending(int value) {
    totalPending = value;
    notifyListeners(); // Notify the UI to rebuild
  }

  void initialPendingDelegateHomeOrders() {
    _pendingDelegateOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _pendingDelegateOrders = [];
    _pendingOrders = null;
    _pendingOrderPage = 1;
    _pendingOrdersHasPagination = true;
    _pendingIsPaginating = false;
    notifyListeners();
  }

  ApiResponse _pendingDelegateOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get pendingDelegateOrdersResponse => _pendingDelegateOrdersResponse;

  List<DelegateOrdersModel> _pendingDelegateOrders = [];
  List<DelegateOrdersModel> get pendingDelegateOrders => _pendingDelegateOrders;
  DelegateModel? _pendingOrders;
  DelegateModel? get pendingOrders => _pendingOrders;

  int _pendingOrderPage = 1;
  int get pendingOrderPage => _pendingOrderPage;

  set pendingOrderPage(int value) {
    _pendingOrderPage = value;
  }

  bool _pendingOrdersHasPagination = true;
  bool get pendingOrdersHasPagination => _pendingOrdersHasPagination;
  bool _pendingIsPaginating = false;
  bool get pendingIsPaginating => _pendingIsPaginating;

  Future<void> getPendingDelegateHomeOrders({int? pageNumber}) async {
    if (_pendingOrderPage == 1) {
      _pendingDelegateOrdersResponse = ApiResponse(state: ResponseState.loading, data: null);
      _pendingDelegateOrders = [];
      _pendingOrders = null;
      notifyListeners();
    } else {
      _pendingIsPaginating = true;
      notifyListeners();
    }

    _pendingDelegateOrdersResponse = await ApiHelper.instance.get(
      Urls.delegateHomePendingOrders,
      queryParameters: {'page': pageNumber ?? _pendingOrderPage},
    );
    notifyListeners();

    if (_pendingDelegateOrdersResponse.state == ResponseState.complete) {
      Iterable iterable = _pendingDelegateOrdersResponse.data['data']['data'];
      totalPending = _pendingDelegateOrdersResponse.data['data']['meta']['total'];

      _pendingOrders = DelegateModel.fromJson(_pendingDelegateOrdersResponse.data['data']);

      if (_pendingOrderPage == _pendingDelegateOrdersResponse.data['data']['meta']['last_page']) {
        _pendingOrdersHasPagination = false;
        // CommonMethods.showToast(message: "No more orders");
        // notifyListeners();
      } else {
        _pendingOrderPage++;
        _pendingOrdersHasPagination = true;
        notifyListeners();
      }
      _pendingDelegateOrders.addAll(iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList());

      notifyListeners();
    }

    _pendingIsPaginating = false;
    notifyListeners();
  }
  //================================== delegate current home ==============================

  void initialCurrentDelegateHomeOrders() {
    _currentDelegateHomeOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _currentDelegateHomeOrders = [];
    _currentHomeOrders = null;
    _currentOrderPage = 1;
    _currentHomeOrdersHasPagination = true;
    _currentHomeIsPaginating = false;
    notifyListeners();
  }

  ApiResponse _currentDelegateHomeOrdersResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get currentDelegateHomeOrdersResponse => _currentDelegateHomeOrdersResponse;

  List<DelegateOrdersModel> _currentDelegateHomeOrders = [];
  List<DelegateOrdersModel> get currentDelegateHomeOrders => _currentDelegateHomeOrders;
  DelegateModel? _currentHomeOrders;
  DelegateModel? get currentHomeOrders => _currentHomeOrders;

  int _currentOrderHomePage = 1;
  int get currentOrderHomePage => _currentOrderHomePage;

  set currentOrderHomePage(int value) {
    _currentOrderHomePage = value;
  }

  bool _currentHomeOrdersHasPagination = true;
  bool get currentHomeOrdersHasPagination => _currentHomeOrdersHasPagination;
  bool _currentHomeIsPaginating = false;
  bool get currentHomeIsPaginating => _currentHomeIsPaginating;

  Future<void> getCurrentDelegateHomeOrders({int? pageNumber}) async {
    if (_currentOrderPage == 1) {
      _currentDelegateHomeOrdersResponse = ApiResponse(state: ResponseState.loading, data: null);
      _currentDelegateHomeOrders = [];
      _currentHomeOrders = null;
      notifyListeners();
    } else {
      _currentHomeIsPaginating = true;
      notifyListeners();
    }

    _currentDelegateHomeOrdersResponse = await ApiHelper.instance.get(
      Urls.delegateHomeCurrentOrder,
      queryParameters: {'page': pageNumber ?? _currentOrderHomePage},
    );
    notifyListeners();

    if (_currentDelegateHomeOrdersResponse.state == ResponseState.complete) {
      Iterable iterable = _currentDelegateHomeOrdersResponse.data['data']['data'];

      _currentHomeOrders = DelegateModel.fromJson(_currentDelegateHomeOrdersResponse.data['data']);

      if (_currentOrderHomePage == _currentDelegateHomeOrdersResponse.data['data']['meta']['last_page']) {
        _currentHomeOrdersHasPagination = false;
        // CommonMethods.showToast(message: "No more orders");
        // notifyListeners();
      } else {
        _currentOrderHomePage++;
        _currentHomeOrdersHasPagination = true;
        notifyListeners();
      }
      _currentDelegateHomeOrders.addAll(iterable.map((e) => DelegateOrdersModel.fromJson(e)).toList());

      notifyListeners();
    }

    _currentHomeIsPaginating = false;
    notifyListeners();
  }
}
