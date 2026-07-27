import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';

class LocationService {
  static Future<void> updatePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    await _sendPositionToServer(position);
  }

  static Future<void> _sendPositionToServer(Position position) async {
    try {
      FormData body = FormData.fromMap({'lat': position.latitude, 'lng': position.longitude});
      final response = await ApiHelper.instance.post(Urls.updatePosition, body: body);

      if (response.state == ResponseState.complete) {
        log('Update Position Successfully');
      } else {
        log('Update Position Failed');
      }
    } catch (e) {
      log('Error sending position: $e');
    }
  }
}
