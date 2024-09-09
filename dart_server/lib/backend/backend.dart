

import 'package:dart_server/backend/modules/announcement.dart';
import 'package:dart_server/backend/modules/tracker.dart';
import 'package:dart_server/backend/modules/webserver.dart';
import 'package:dart_server/io/gps_tracker.dart';
import 'package:dart_server/io/matrix_display.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/delegates.dart';

class pibus_backend {

  static final pibus_backend _singleton = pibus_backend._internal();

  factory pibus_backend() {
    return _singleton;
  }

  pibus_backend._internal() {}

  void init() {
    ConsoleLog("pibus_backend initializing");

    // Initialize IO
    matrixDisplay = MatrixDisplay();
    gpsTracker = GpsTracker('/dev/ttyACM0');

    // Initialize modules
    Module_Tracker = TrackerModule();
    Module_Announcement = AnnouncementModule();
    Module_Webserver = WebserverModule();
  }

  // IO
  late MatrixDisplay matrixDisplay;
  late GpsTracker gpsTracker;

  // Modules
  late TrackerModule Module_Tracker;
  late AnnouncementModule Module_Announcement;
  late WebserverModule Module_Webserver;

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

void ConsoleLog(String message) {
  print("Console: $message");
}