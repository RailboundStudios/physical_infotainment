
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';


import 'package:dart_server/backend/backend.dart';
import 'package:dart_server/backend/modules/announcement.dart';
import 'package:dart_server/backend/modules/info_module.dart';
import 'package:dart_server/io/gps_tracker.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/OrdinanceSurveyUtils.dart';
import 'package:vector_math/vector_math.dart';

class TrackerModule extends InfoModule {

  // Constructor
  TrackerModule() {

    backend.routeDelegate.addListener((route) {
      ConsoleLog("Route variant changed");
      updateNearestStop();
    });
    Timer.periodic(Duration(seconds: 1), (timer) {
      onTick();
    });
  }


  void onTick() {
    if (!backend.gpsTracker.hasEverFixed) {
      return;
    }

    backend.matrixDisplay.timeOffset = backend.gpsTracker.utcOffset.inMilliseconds;
    updateNearestStop();
  }


  BusRouteStop? nearestStop;
  bool hasArrived = false;


  Future<void> updateNearestStop() async {
    if (backend.currentRoute == null) {
      return;
    }

    GpsTracker gpsTracker = backend.gpsTracker;

    // Get the closest stop
    BusRouteStop closestStop = backend.currentRoute!.stops.first;
    double closestDistance = OSGrid
        .toNorthingEasting([gpsTracker.latitude, gpsTracker.longitude])
        .distanceTo(OSGrid.toNorthingEasting([closestStop.latitude, closestStop.longitude]));

    for (BusRouteStop stop in backend.currentRoute!.stops) {
      double distance = OSGrid
          .toNorthingEasting([gpsTracker.latitude, gpsTracker.longitude])
          .distanceTo(OSGrid.toNorthingEasting([stop.latitude, stop.longitude]));

      if (distance < closestDistance) {
        closestStop = stop;
        closestDistance = distance;
      }
    }

    double relativeDistance = _calculateRelativeDistance(closestStop, gpsTracker.latitude, gpsTracker.longitude);



    if (relativeDistance < -10) {
      ConsoleLog("Closest stop is behind us: ${closestStop.name}");
      ConsoleLog("Relative distance: $relativeDistance");

      int stopIndex = backend.currentRoute!.stops.indexOf(closestStop);

      int maxStops = backend.currentRoute!.stops.length;

      closestStop = backend.currentRoute!.stops[min(stopIndex + 1, maxStops)-1];

      ConsoleLog("Closest stop is now: ${closestStop.name}");
    } else {
      ConsoleLog("Closest stop is in front of us: ${closestStop.name}");
    }

    bool preExisting = true;

    if (nearestStop != closestStop) {
      nearestStop = closestStop;
      hasArrived = false;
      preExisting = false;
    }

    ConsoleLog("Closest stop is the same as before");

    double distance = OSGrid
        .toNorthingEasting([gpsTracker.latitude, gpsTracker.longitude])
        .distanceTo(OSGrid.toNorthingEasting([nearestStop!.latitude, nearestStop!.longitude]));

    // convert km/h to mph
    double speed = gpsTracker.speed * 0.621371;
    ConsoleLog("Speed: $speed");

    Duration? duration;
    {
      // Testing some audio stuff
      Uint8List? audioBytes = nearestStop?.audio;

      if (audioBytes != null) {
        duration = await backend.Module_Announcement.announcementPlayer.queryDuration(audioBytes);

        ConsoleLog("Duration of audio: $duration");
      } else {
        ConsoleLog("Audio bytes are null");
        duration = Duration(seconds: 0);
      }


    }

    // get the estimated distance travelled in 5 seconds, in meters
    double distanceTravelled = speed * (3 + duration!.inSeconds);

    // adjust for the it takes to send the announcement to other devices
    distance -= distanceTravelled;

    // get the time to the stop in seconds
    double timeToStop = distance / speed;

    ConsoleLog("Distance to stop: $distance");
    ConsoleLog("Time to stop: $timeToStop");

    int secondsBefore = 7;

    ConsoleLog("Seconds before: $secondsBefore");

    if ((timeToStop < secondsBefore ) && !hasArrived && relativeDistance > 0) {
      ConsoleLog("We are at the stop");
      hasArrived = true;
      // liveInformation.announcementModule.queueAnnounceByAudioName(
      //   displayText: "${nearestStop!.formattedStopName}",
      //   audioNames: [
      //     // "A_NEXT_STOP_001.mp3",
      //     nearestStop!.getAudioFileName()
      //   ],
      //   sendToServer: true
      // );
      backend.Module_Announcement.queueAnnouncement(AnnouncementQueueEntry(
        displayText: nearestStop!.name,
        audioBytes: [
          if (nearestStop!.audio != null) nearestStop!.audio!
        ],
      ));
    }


    if (!hasArrived && !preExisting) {
      // liveInformation.announcementModule.queueAnnounceByAudioName(
      //   displayText: "${closestStop.formattedStopName}",
      //   audioNames: [],
      //   sendToServer: true
      // );
      backend.Module_Announcement.queueAnnouncement(AnnouncementQueueEntry(
        displayText: closestStop.name,
        audioBytes: [],
      ));
    }



    ConsoleLog("Closest stop: ${closestStop.name} in ${closestDistance.round()} meters");
  }

}

double _calculateRelativeDistance(BusRouteStop stop, double latitude, double longitude) {

  Vector2 StopPoint = OSGrid.toNorthingEasting([stop.latitude, stop.longitude]);
  Vector2 CurrentPoint = OSGrid.toNorthingEasting([latitude, longitude]);

  // Detect whether the stop is in front or behind the current location using the heading
  double heading = stop.heading;
  double angle = atan2(StopPoint.y - CurrentPoint.y, StopPoint.x - CurrentPoint.x);
  double relativeAngle = angle - heading;
  bool isBehind = relativeAngle.abs() > pi / 2;

  double sign = isBehind ? -1 : 1;

  return sign * StopPoint.distanceTo(CurrentPoint);
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {

  // Convert to eastings and northings
  Vector2 point1 = OSGrid.toNorthingEasting([lat1, lon1]);
  Vector2 point2 = OSGrid.toNorthingEasting([lat2, lon2]);

  return point1.distanceTo(point2);

}