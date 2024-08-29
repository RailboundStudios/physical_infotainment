
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_server/backend/modules/info_module.dart';
import 'package:dart_server/io/matrix_display.dart';
import 'package:dart_server/route.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class WebserverModule extends InfoModule {

  // Constructor
  WebserverModule() {
    Directory routesDir = Directory("storage/routes");

    Router router = Router();
    // Set the top line. /top?text=Hello
    router.get("/top", (Request request) {
      String text = request.url.queryParameters["text"] ?? "";
      backend.matrixDisplay.topLine = text;
      return Response.ok("Top line set to $text");
    });

    // Set the bottom line. /bottom?text=World
    router.get("/bottom", (Request request) {
      String text = request.url.queryParameters["text"] ?? "";
      backend.matrixDisplay.bottomLine = text;
      return Response.ok("Bottom line set to $text");
    });

    // set the color. /color?r=255&g=0&b=0
    router.get("/color", (Request request) {
      int r = int.parse(request.url.queryParameters["r"] ?? "0");
      int g = int.parse(request.url.queryParameters["g"] ?? "0");
      int b = int.parse(request.url.queryParameters["b"] ?? "0");
      backend.matrixDisplay.color = Color(r, g, b);
      return Response.ok("Color set to $r, $g, $b");
    });

    // set the speed. /speed?ms=10
    router.get("/speed", (Request request) {
      int ms = int.parse(request.url.queryParameters["ms"] ?? "10");
      backend.matrixDisplay.SpeedMs = ms;
      return Response.ok("Speed set to $ms");
    });

    // get the displayInfo. /displayInfo
    router.get("/displayInfo", (Request request) {
      return Response.ok(
          jsonEncode({
            "topText": backend.matrixDisplay.topLine,
            "bottomText": backend.matrixDisplay.bottomLine,
            "textColor": [
              backend.matrixDisplay.color.red,
              backend.matrixDisplay.color.green,
              backend.matrixDisplay.color.blue
            ],
            "speedMs": backend.matrixDisplay.SpeedMs
          })
      );
    });

    // get the locationInfo. /locationInfo
    router.get("/locationInfo", (Request request) {
      return Response.ok(
          jsonEncode({
            "locationFix": backend.gpsTracker.isFixed,
            "latitude": backend.gpsTracker.latitude,
            "longitude": backend.gpsTracker.longitude
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



            backend.currentRoute = BusRoute.fromMap(map);
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

    var server = shelf_io.serve(router, '0.0.0.0', 8080);
  }

}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
