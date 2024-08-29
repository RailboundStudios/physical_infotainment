import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_server/io/gps_tracker.dart';
import 'package:dart_server/io/matrix_display.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/OrdinanceSurveyUtils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:vector_math/vector_math.dart';

Future<void> main(List<String> arguments) async {

  print("Starting the dart server");

  Directory storageDir = Directory("storage");
  if (!storageDir.existsSync()) {
    storageDir.createSync();
  }
  Directory routesDir = Directory("storage/routes");
  if (!routesDir.existsSync()) {
    routesDir.createSync();
  }

  MatrixDisplay matrixDisplay = MatrixDisplay();
  GpsTracker gpsTracker = GpsTracker("/dev/ttyACM0");

  BusRoute? currentRoute;

  while (!matrixDisplay.isReady) {
    await Future.delayed(Duration(seconds: 1));
  }

  matrixDisplay.topLine = "Hello";
  matrixDisplay.bottomLine = "World";

  Router router = Router();
  // Set the top line. /top?text=Hello
  router.get("/top", (Request request) {
    String text = request.url.queryParameters["text"] ?? "";
    matrixDisplay.topLine = text;
    return Response.ok("Top line set to $text");
  });

  // Set the bottom line. /bottom?text=World
  router.get("/bottom", (Request request) {
    String text = request.url.queryParameters["text"] ?? "";
    matrixDisplay.bottomLine = text;
    return Response.ok("Bottom line set to $text");
  });

  // set the color. /color?r=255&g=0&b=0
  router.get("/color", (Request request) {
    int r = int.parse(request.url.queryParameters["r"] ?? "0");
    int g = int.parse(request.url.queryParameters["g"] ?? "0");
    int b = int.parse(request.url.queryParameters["b"] ?? "0");
    matrixDisplay.color = Color(r, g, b);
    return Response.ok("Color set to $r, $g, $b");
  });

  // set the speed. /speed?ms=10
  router.get("/speed", (Request request) {
    int ms = int.parse(request.url.queryParameters["ms"] ?? "10");
    matrixDisplay.SpeedMs = ms;
    return Response.ok("Speed set to $ms");
  });

  // get the displayInfo. /displayInfo
  router.get("/displayInfo", (Request request) {
    return Response.ok(
      jsonEncode({
        "topText": matrixDisplay.topLine,
        "bottomText": matrixDisplay.bottomLine,
        "textColor": [
          matrixDisplay.color.red,
          matrixDisplay.color.green,
          matrixDisplay.color.blue
        ],
        "speedMs": matrixDisplay.SpeedMs
      })
    );
  });

  // get the locationInfo. /locationInfo
  router.get("/locationInfo", (Request request) {
    return Response.ok(
      jsonEncode({
        "locationFix": gpsTracker.isFixed,
        "latitude": gpsTracker.latitude,
        "longitude": gpsTracker.longitude
      })
    );
  });

  // Upload a route. /uploadRoute - Saves the route to a file
  router.post("/uploadRoute", (Request request) async {
    var body = await request.readAsString();

    String hash = sha256.convert(utf8.encode(body)).toString();
    Map<String, dynamic> map = jsonDecode(body);

    File file = File("storage/routes/$hash.json");
    file.writeAsStringSync(getPrettyJSONString(map));

    return Response.ok("Route uploaded");
  });

  // The next 2 routers can be optimised by pre-caching the route information.

  // Get a list of routes. /routes
  router.get("/routes", (Request request) {
    List<dynamic> routes = [];

    for (FileSystemEntity fileSystemEntity in routesDir.listSync()) {
      File file = File(fileSystemEntity.path);

      String contents = file.readAsStringSync();
      Map<String, dynamic> map = jsonDecode(contents);
      String hash = sha256.convert(utf8.encode(contents)).toString();

      routes.add({
        "RouteNumber": map["RouteNumber"],
        "RouteDestination": map["Destination"],
        "RouteHash": hash,
        "StopCount": map["Stops"].length
      });
    }

    // Set the current route. /setCurrentRoute?hash=123456
    router.get("/setCurrentRoute", (Request request) {
      String hash = request.url.queryParameters["hash"] ?? "";
      for (FileSystemEntity fileSystemEntity in routesDir.listSync()) {
        File file = File(fileSystemEntity.path);
        String contents = file.readAsStringSync();
        String fileHash = sha256.convert(utf8.encode(contents)).toString();
        if (fileHash == hash) {
          Map<String, dynamic> map = jsonDecode(contents);
          currentRoute = BusRoute.fromMap(map);
          print("Route set to ${map["RouteNumber"]} - ${map["RouteDestination"]}");
          return Response.ok("Route set to ${map["RouteNumber"]} - ${map["RouteDestination"]}");
        }
      }
      return Response.ok("Failed to find route with hash: $hash");
    });


    return Response.ok(jsonEncode(routes));
  });

  // Test Connection. /testConnection
  router.get("/testConnection", (Request request) {
    return Response.ok("Connection successful");
  });

  Timer.periodic(Duration(seconds: 1), (timer) {
    if (currentRoute == null) {
      return;
    }

    // Get the nearest bus stop
    BusRouteStop? nearestBusStop;
    double nearestDistance = double.infinity;
    if (gpsTracker.hasEverFixed) {
      for (BusRouteStop busStop in currentRoute!.stops) {

        Vector2 PointA = OSGrid.toNorthingEasting([gpsTracker.latitude, gpsTracker.longitude]);
        Vector2 PointB = OSGrid.toNorthingEasting([busStop.latitude, busStop.longitude]);

        double distance = PointA.distanceTo(PointB);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestBusStop = busStop;
        }
      }
    }

    if (nearestBusStop != null) {
      matrixDisplay.topLine = nearestBusStop.name;
      matrixDisplay.bottomLine = "${nearestDistance.toStringAsFixed(2)}m";
    } else {
      matrixDisplay.topLine = "${currentRoute!.routeNumber} to ${currentRoute!.destination}";
      matrixDisplay.bottomLine = "";
    }
  });

  // Start the server
  var server = await shelf_io.serve(router, '0.0.0.0', 8080);

  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }

}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
