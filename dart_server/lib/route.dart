
import 'dart:convert';
import 'dart:typed_data';

class BusRoute {
  String routeNumber = "";
  String destination = "";

  Uint8List? routeAudio;
  Uint8List? destinationAudio;

  List<BusRouteStop> stops = [];

  BusRoute(this.routeNumber, this.destination);

  BusRoute.fromMap(Map<String, dynamic> map) {
    routeNumber = map["RouteNumber"];
    destination = map["Destination"];
    routeAudio = map["RouteAudio"] != "" ? base64Decode(map["RouteAudio"]) : null;
    destinationAudio = map["DestinationAudio"] != "" ? base64Decode(map["DestinationAudio"]) : null;
    stops = (map["Stops"] as List).map((e) => BusRouteStop.fromMap(e)).toList();
  }

  toMap() {
    return {
      "RouteNumber": routeNumber,
      "Destination": destination,
      "RouteAudio": routeAudio != null ? base64Encode(routeAudio!) : "",
      "DestinationAudio": destinationAudio != null ? base64Encode(destinationAudio!) : "",
      "Stops": stops.map((e) => e.toMap()).toList(),
    };
  }
}

class BusRouteStop {
  String name = "";

  Uint8List? audio;

  double announceDistance = 20; // in meters

  double latitude = 0.0;
  double longitude = 0.0;
  double heading = 0.0;

  BusRouteStop(this.name, this.latitude, this.longitude);

  BusRouteStop.fromMap(Map<String, dynamic> map) {
    name = map["Name"];
    var location = map["Location"].split(", ");
    latitude = double.parse(location[0]);
    longitude = double.parse(location[1]);
    heading = map["Heading"];
    audio = map["Audio"] != "" ? base64Decode(map["Audio"]) : null;
    announceDistance = map["AnnounceDistance"];
  }

  toMap() {
    return {
      "Name": name,
      "Location": "$latitude, $longitude",
      "Heading": heading,
      "Audio": audio != null ? base64Encode(audio!) : "",
      "AnnounceDistance": announceDistance,
    };
  }
}