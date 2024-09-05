

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/OrdinanceSurveyUtils.dart';
import 'package:vector_math/vector_math.dart';

int levenshteinDistance(String a, String b) {
  List<List<int>> matrix = List.generate(
    a.length + 1,
        (_) => List<int>.filled(b.length + 1, 0),
  );

  for (int i = 0; i <= a.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= b.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      int cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost, // substitution
      ].reduce((curr, next) => curr < next ? curr : next);
    }
  }

  return matrix[a.length][b.length];
}

String getClosestMatch(String pattern, List<String> list) {
  pattern = pattern.toLowerCase();

  String? closestMatch;
  int minDistance = 2147483647;

  for (String candidate in list) {
    int distance = levenshteinDistance(pattern, candidate);
    if (distance < minDistance) {
      minDistance = distance;
      closestMatch = candidate;
    }
  }

  return closestMatch!;
}

Uint8List getAudioForDestination(String destination, Map<String, String> indexedAudios) {

  String audioName = destination
      .replaceAll(RegExp(r"[^A-Za-z0-9 ]"), "")
      .replaceAll("  ", " ")
      .replaceAll(" ", "_")
      .toUpperCase();
  audioName = "S_${audioName}_001.mp3";

  late File audioFile;

  if (indexedAudios.containsKey(audioName.toLowerCase())) {
    audioFile = File(indexedAudios[audioName.toLowerCase()]!);
    print("Found audio file for $audioName");
  } else {
    print("Could not find audio file for $audioName");
    String closestMatch = getClosestMatch(audioName, indexedAudios.keys.toList());
    audioFile = File(indexedAudios[closestMatch.toLowerCase()]!);
    print("Chose $closestMatch for $audioName");
  }

  return audioFile.readAsBytesSync();
}

void main() {

  List<String> routeAllowlist = [
    "N68"
  ];

  Map<String, String> indexedAudios = {};

  Directory audioDirectory = Directory("lib/tools/tfl_route_generator/audios");
  for (FileSystemEntity entity in audioDirectory.listSync(recursive: true)) {
    if (entity is File) {
      String fileName = entity.path.split(RegExp(r"\\|/")).last;
      indexedAudios[fileName.toLowerCase()] = entity.path;
    }
  }

  Map<String, dynamic> destinations = jsonDecode(
    File("lib/tools/tfl_route_generator/destinations.json").readAsStringSync()
  );

  // Load bin/tools/tfl_route_generator/bus-sequences.csv
  String csv = File("lib/tools/tfl_route_generator/bus-sequences.csv").readAsStringSync();

  List<List<String>> rows = CsvToListConverter().convert(csv, shouldParseNumbers: false);
  rows.removeAt(0);

  List<BusRoute> busRoutes = [];

  for (int i = 0; i < rows.length - 1; i++) {

    List<dynamic> row = rows[i];

    String route = row[0] as String;
    String run = row[1] as String;
    String sequence = row[2] as String;
    String stopCodeLBSL = row[3] as String;
    String busStopCode = row[4] as String;
    String naptanAtco = row[5] as String;
    String stopName = row[6] as String;
    String easting = row[7] as String;
    String northing = row[8] as String;
    String heading = row[9] as String;

    if (!routeAllowlist.contains(route)) {
      continue;
    }

    // Get the last bus route with the same route number
    BusRoute busRoute = busRoutes.lastWhere((element) => element.routeNumber == "$route, $run", orElse: () => BusRoute("$route, $run", ""));
    // If the bus route doesn't exist, add it to the list
    if (!busRoutes.contains(busRoute)) {
      busRoutes.add(busRoute);
      print("Added bus route $route, $run");
    }

    // Remove anything that is surrounded in any kind of parenthesis, () [] {} <>
    stopName = stopName.replaceAll(RegExp(r"\(.*\)"), "").replaceAll(RegExp(r"\[.*\]"), "").replaceAll(RegExp(r"\{.*\}"), "").replaceAll(RegExp(r"\<.*\>"), "");

    // Remove outliers
    stopName = stopName.replaceAll("lol<", "");

    // remove anything that isnt A-Z, a-z, 0-9, /, ., ', ,, from the stop name. Then split the stop name by spaces, remove any empty strings, and capitalise the first letter of each word.
    stopName = stopName
        .replaceAll(RegExp(r"[^A-Za-z0-9/.' ]"), "")
        .split(" ")
        .where((element) => element.isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1).toLowerCase())
        .join(" ");

    // Lets try to assume the audio name. replace anything that isnt a-z 0-9, Keep Spaces
    String audioName = stopName.replaceAll(RegExp(r"[^A-Za-z0-9 ]"), "")
        .replaceAll("  ", " ")
        .replaceAll(" ", "_")
        .toUpperCase();
    audioName = "S_${audioName}_001.mp3";

    late File audioFile;
    if (indexedAudios.containsKey(audioName.toLowerCase())) {
      audioFile = File(indexedAudios[audioName.toLowerCase()]!);
      print("Found audio file for $audioName");
    } else {
      print("Could not find audio file for $audioName");
      String closestMatch = getClosestMatch(audioName, indexedAudios.keys.toList());
      audioFile = File(indexedAudios[closestMatch.toLowerCase()]!);
      print("Chose $closestMatch for $audioName");
    }



    // set the destination.
    busRoute.destination = stopName;

    // Create a new bus stop
    List<double> latLong = OSGrid.toLatLong(double.parse(northing), double.parse(easting));

    BusRouteStop busStop = BusRouteStop(stopName, latLong[0], latLong[1]);
    busStop.heading = double.parse(heading);
    busStop.audio = audioFile.readAsBytesSync();

    // Add the bus stop to the bus route
    busRoute.stops.add(busStop);

    print("Added stop $stopName to bus route $route, $run");
    print(" ");
  }

  print("Loaded ${busRoutes.length} bus routes");

  // Sanitise the bus routes
  for (BusRoute busRoute in busRoutes) {
    busRoute.routeNumber = busRoute.routeNumber.split(",")[0];

    String routeNumberAudio = "R_${busRoute.routeNumber}_001.mp3";
    File routeNumberAudioFile = File(indexedAudios[routeNumberAudio.toLowerCase()]!);
    busRoute.routeAudio = routeNumberAudioFile.readAsBytesSync();

    String? destination;

    for (String key in destinations.keys) {

      if (destination == null) {
        destination = key;
        continue;
      }

      Vector2 lastStopPoint = OSGrid.toNorthingEasting([busRoute.stops.last.latitude, busRoute.stops.last.longitude]);
      Vector2 currentDestinationPoint = OSGrid.toNorthingEasting([
        double.parse(destinations[key]!["Location"].split(", ")[0]),
        double.parse(destinations[key]!["Location"].split(", ")[1])
      ]);
      Vector2 nextDestinationPoint = OSGrid.toNorthingEasting([
        double.parse(destinations[destination]!["Location"].split(", ")[0]),
        double.parse(destinations[destination]!["Location"].split(", ")[1])
      ]);

      double distanceA = lastStopPoint.distanceTo(currentDestinationPoint);
      double distanceB = lastStopPoint.distanceTo(nextDestinationPoint);

      if (distanceA < distanceB) {
        destination = key;
      }

    }
    print("Choose destination $destination for route ${busRoute.routeNumber}");

    busRoute.destination = destination!;
    Uint8List audioBytes = getAudioForDestination(destination, indexedAudios);
    busRoute.destinationAudio = audioBytes;
  }

  // Save each individual bus route to a file
  Directory outputDirectory = Directory("lib/tools/tfl_route_generator/output");
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync();
  }

  for (BusRoute busRoute in busRoutes) {
    File routeFile = File("lib/tools/tfl_route_generator/output/${busRoute.routeNumber}_towards_${busRoute.destination}.json");

    // Encode to json with indentation
    String json = getPrettyJSONString(busRoute.toMap());

    routeFile.writeAsStringSync(json);
  }

}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}