// import 'dart:developer';

// import 'package:workmanager/workmanager.dart';
// import 'location_service.dart'; // تأكد من مسار الملف الصحيح

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     log("Task $task started");
//     switch (task) {
//       case 'update_position':
//         log("Updating position...");
//         await LocationService.updatePosition();
//         break;
//     }
//     return Future.value(true);
//   });
// }
