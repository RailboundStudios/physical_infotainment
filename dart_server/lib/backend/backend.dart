

import 'package:dart_server/backend/modules/announcement.dart';
import 'package:dart_server/backend/modules/tracker.dart';
import 'package:dart_server/io/gps_tracker.dart';
import 'package:dart_server/io/matrix_display.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/delegates.dart';

class pibus_backend {

  static final pibus_backend _singleton = pibus_backend._internal();

  factory pibus_backend() {
    return _singleton;
  }

  pibus_backend._internal() {
    print("pibus_backend initializing");
  }

  // IO
  MatrixDisplay matrixDisplay = MatrixDisplay();
  GpsTracker gpsTracker = GpsTracker("/dev/ttyACM0");

  // Modules
  TrackerModule Module_Tracker = TrackerModule();
  AnnouncementModule Module_Announcement = AnnouncementModule();

  // Events
  EventDelegate<BusRoute> routeDelegate = EventDelegate<BusRoute>();

  // Important variables
  BusRoute? _currentRoute;
  BusRoute? get currentRoute => _currentRoute;
  set currentRoute(BusRoute? value) {
    _currentRoute = value;
    Future.delayed(Duration.zero, () {
      routeDelegate.trigger(_currentRoute!);
    });

  }
}