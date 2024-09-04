
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';


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
      print("Route variant changed");
      updateNearestStop();
    });
    Timer.periodic(Duration(seconds: 1), (timer) {
      try {
        onTick();
      } catch (e) {
        print("Error in tracker module: $e");
      }
    });
  }


  void onTick() {
    if (!backend.gpsTracker.hasEverFixed) {
      return;
    }

    print("Updating nearest stop");

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
      print("Closest stop is behind us: ${closestStop.name}");
      print("Relative distance: $relativeDistance");

      int stopIndex = backend.currentRoute!.stops.indexOf(closestStop);

      int maxStops = backend.currentRoute!.stops.length;

      closestStop = backend.currentRoute!.stops[min(stopIndex + 1, maxStops)];

      print("Closest stop is now: ${closestStop.name}");
    } else {
      print("Closest stop is in front of us: ${closestStop.name}");
    }

    bool preExisting = true;

    if (nearestStop != closestStop) {
      nearestStop = closestStop;
      hasArrived = false;
      preExisting = false;
    }

    print("Closest stop is the same as before");

    double distance = OSGrid
        .toNorthingEasting([gpsTracker.latitude, gpsTracker.longitude])
        .distanceTo(OSGrid.toNorthingEasting([nearestStop!.latitude, nearestStop!.longitude]));

    // convert km/h to mph
    double speed = gpsTracker.speed * 0.621371;
    print("Speed: $speed");

    Duration? duration;
    {
      // Testing some audio stuff
      Uint8List? audioBytes = nearestStop?.audio;

      if (audioBytes != null) {
        duration = await getSoundLength(audioBytes);

        print("Duration of audio: $duration");
      } else {
        print("Audio bytes are null");
        duration = Duration(seconds: 0);
      }


    }

    // get the estimated distance travelled in 5 seconds, in meters
    double distanceTravelled = speed * (3 + duration!.inSeconds);

    // adjust for the it takes to send the announcement to other devices
    distance -= distanceTravelled;

    // get the time to the stop in seconds
    double timeToStop = distance / speed;

    print("Distance to stop: $distance");
    print("Time to stop: $timeToStop");

    int secondsBefore = 7;

    print("Seconds before: $secondsBefore");

    if ((timeToStop < secondsBefore ) && !hasArrived && relativeDistance > 0) {
      print("We are at the stop");
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



    print("Closest stop: ${closestStop.name} in ${closestDistance.round()} meters");
  }

}

double _calculateRelativeDistance(BusRouteStop stop, double latitude, double longitude) {

  List<double> toLatLong = [stop.latitude, stop.longitude];

  Vector2 stopPoint = OSGrid.toNorthingEasting([toLatLong[0], toLatLong[1]]);
  Vector2 currentPoint = OSGrid.toNorthingEasting([latitude, longitude]);

  // calculate the heading from the current point to the stop point
  // 0 degrees is north, 90 degrees is east, 180 degrees is south, 270 degrees is west
  double toHeading = degrees(atan2(stopPoint.x - currentPoint.x, stopPoint.y - currentPoint.y));
  toHeading = (toHeading + 360) % 360;

  // get the dot product of the heading and the stop heading
  double dotProduct = cos(radians(toHeading)) * cos(radians(stop.heading.toDouble())) + sin(radians(toHeading)) * sin(radians(stop.heading.toDouble()));

  return (dotProduct.sign) * _calculateDistance(latitude, longitude, toLatLong[0], toLatLong[1]);
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {

  // Convert to eastings and northings
  Vector2 point1 = OSGrid.toNorthingEasting([lat1, lon1]);
  Vector2 point2 = OSGrid.toNorthingEasting([lat2, lon2]);

  return point1.distanceTo(point2);

}