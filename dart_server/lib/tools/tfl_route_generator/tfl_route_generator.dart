

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/OrdinanceSurveyUtils.dart';

void main() {

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

    // Get the last bus route with the same route number
    BusRoute busRoute = busRoutes.lastWhere((element) => element.routeNumber == "$route, $run", orElse: () => BusRoute("$route, $run", ""));
    // If the bus route doesn't exist, add it to the list
    if (!busRoutes.contains(busRoute)) {
      busRoutes.add(busRoute);
      print("Added bus route $route, $run");
    }

    // set the destination.
    busRoute.destination = stopName;

    // Create a new bus stop
    List<double> latLong = OSGrid.toLatLong(double.parse(northing), double.parse(easting));

    BusRouteStop busStop = BusRouteStop(stopName, latLong[0], latLong[1]);

    // Add the bus stop to the bus route
    busRoute.stops.add(busStop);
  }

  print("Loaded ${busRoutes.length} bus routes");

  // Sanitise the bus routes
  for (BusRoute busRoute in busRoutes) {
    busRoute.routeNumber = busRoute.routeNumber.split(",")[0];
  }

  // Save each individual bus route to a file
  Directory outputDirectory = Directory("lib/tools/tfl_route_generator/output");
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync();
  }

  for (BusRoute busRoute in busRoutes) {
    File routeFile = File("lib/tools/tfl_route_generator/output/${busRoute.routeNumber}_${busRoutes.indexOf(busRoute)}.json");

    // Encode to json with indentation
    String json = getPrettyJSONString(busRoute.toMap());

    routeFile.writeAsStringSync(json);
  }

}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}