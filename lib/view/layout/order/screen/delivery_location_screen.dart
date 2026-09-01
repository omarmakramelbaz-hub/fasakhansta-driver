import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';

class DeliveryLocationArgs {
  final double lat;
  final double lng;
  const DeliveryLocationArgs({required this.lat, required this.lng});
}

class DeliveryLocationScreen extends StatefulWidget {
  static const String routeName = 'DeliveryLocationScreen';
  final DeliveryLocationArgs? args;
  const DeliveryLocationScreen({super.key, this.args});

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  List<Placemark>? placemarks;
  GoogleMapController? gmc;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    final args = widget.args;
    if (args == null) return;
    placemarks = await placemarkFromCoordinates(args.lat, args.lng);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);
    final args = widget.args;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          AppLocaleKey.location.tr(),
          style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      body: args == null
          ? const Center(child: Icon(Icons.location_off_rounded, color: softText, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.locale.languageCode == 'ar' ? 'موقع التسليم' : 'Delivery destination',
                    style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'يمكنك تكبير الخريطة لمراجعة الموقع بدقة'
                        : 'Zoom the map to review the destination precisely',
                    style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: MediaQuery.of(context).size.height * .60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xffECEEF1)),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(.09),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GoogleMap(
                      markers: markers,
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        gmc = controller;
                        setState(() {
                          markers = {
                            Marker(
                              markerId: const MarkerId('location'),
                              position: LatLng(args.lat, args.lng),
                            ),
                          };
                        });
                      },
                      initialCameraPosition: CameraPosition(target: LatLng(args.lat, args.lng), zoom: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xffECEEF1)),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(.055),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF0E3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: orange, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocaleKey.area.tr(),
                                style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                placemarks == null
                                    ? (context.locale.languageCode == 'ar' ? 'جارٍ تحميل العنوان...' : 'Loading address...')
                                    : '${placemarks![0].locality ?? ''}, ${placemarks![0].street ?? ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: softText,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
