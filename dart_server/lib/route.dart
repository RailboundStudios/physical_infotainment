// Copyright 2024 IMBENJI.NET. All rights reserved.
// For use of this source code, please see the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

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

    if (map["RouteAudio"] != null && map["RouteAudio"] != "") {
      routeAudio = base64Decode(map["RouteAudio"]);
    }

    if (map["DestinationAudio"] != null && map["DestinationAudio"] != "") {
      destinationAudio = base64Decode(map["DestinationAudio"]);
    }

    if (map["RouteHash"] != null) {
      _hash = map["RouteHash"];
    }

    stops = (map["Stops"] as List).map((e) => BusRouteStop.fromMap(e)).toList();
  }

  String? _hash;
  String get hash {
    if (_hash == null) {
      _hash = md5.convert(utf8.encode(getPrettyJSONString(toMap()))).toString();
    }
    return _hash!;
  }

  toMap({
    bool includeHash = false,
  }) {
    return {
      "RouteNumber": routeNumber,
      "Destination": destination,
      if (_hash != null && includeHash) "RouteHash": hash,
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
    heading = map["Heading"] ?? 0.0;
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

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}