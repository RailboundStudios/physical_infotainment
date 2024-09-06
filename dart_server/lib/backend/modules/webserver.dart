
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_server/backend/backend.dart';
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

    // Update the Matrix Payload.
    router.patch("/matrix", (Request request) async {
      Map<String, dynamic> body = jsonDecode(await request.readAsString());

      // Start updating matrix attributes.
      // If expected values are null, then leave them the same.
      // todo: Come back to this, and update the dotnet server so that the parameters are dynamic in preparation for different types of displays.
      // todo: for now, we'll just adapt to the current fixed parameters.
      if (body["text_top"] != null) {
        backend.matrixDisplay.topLine = body["text_top"];
      }
      if (body["text_bottom"] != null) {
        backend.matrixDisplay.bottomLine = body["text_bottom"];
      }
      if (body["color"] != null) {
        backend.matrixDisplay.color = Color(body["color"][0], body["color"][1], body["color"][2]);
      }
      if (body["speed"] != null) {
        backend.matrixDisplay.SpeedMs = body["speed"];
      }
      if (body["mode"] != null) {
        backend.matrixDisplay.mode = body["mode"];
      }
    });
    // Get the current Matrix Payload.
    router.get("/matrix", (Request request) {
      return Response.ok(
          getPrettyJSONString({
            "text_top": backend.matrixDisplay.topLine,
            "text_bottom": backend.matrixDisplay.bottomLine,
            "color": [
              backend.matrixDisplay.color.red,
              backend.matrixDisplay.color.green,
              backend.matrixDisplay.color.blue
            ],
            "speed": backend.matrixDisplay.SpeedMs
          })
      );
    });


    // Update the GPS Payload. Hopefully this isn't used much.
    router.patch("/position", (Request request) async {
      Map<String, dynamic> body = jsonDecode(await request.readAsString());

      /*
        Expecting:
          - latitude
          - longitude
          - speed
          - time
       */

      if (body["latitude"] != null) {
        backend.gpsTracker.latitude = body["latitude"];
      }
      if (body["longitude"] != null) {
        backend.gpsTracker.longitude = body["longitude"];
      }
      if (body["speed"] != null) {
        backend.gpsTracker.speed = body["speed"];
      } else {
        // We could calculate the speed from the previous position, but that's long.
      }
      if (body["time"] != null) {
        backend.gpsTracker.utcTime = DateTime.parse(body["time"]);
      }

    });
    // Get the current GPS Payload.
    router.get("/position", (Request request) {
      return Response.ok(
          getPrettyJSONString({
            "latitude": backend.gpsTracker.latitude,
            "longitude": backend.gpsTracker.longitude,
            "speed": backend.gpsTracker.speed,
            "time": backend.gpsTracker.utcTime.toIso8601String()
          })
      );
    });

    // Get a list of routes. /routes?deep=true|false
    // if deep is true, then the stops are included.
    router.get("/routes", (Request request) {
      List<dynamic> routes = [];

      for (FileSystemEntity fileSystemEntity in routesDir.listSync()) {
        File file = File(fileSystemEntity.path);

        String contents = file.readAsStringSync();
        Map<String, dynamic> map = jsonDecode(contents);

        BusRoute route = BusRoute.fromMap(map);
        String hash = route.hash;

        if (request.url.queryParameters["deep"] == "true") {
          routes.add(map);
        } else {
          routes.add({
            "RouteNumber": map["RouteNumber"],
            "Destination": map["Destination"],
            "RouteHash": hash,
            "StopCount": map["Stops"].length,
            "Stops": []
          });
        }
      }

      return Response.ok(getPrettyJSONString(routes));
    });

    // Set the current route. /current-route?hash=123456
    router.patch("/current-route", (Request request) {
      String hash = request.url.queryParameters["hash"] ?? "";

      if (hash == "nil") {
        backend.currentRoute = null;
        backend.matrixDisplay.topLine = "";
        return Response.ok("Route set to nil");
      }

      File file = File("storage/routes/$hash.json");
      if (!file.existsSync()) {
        return Response.ok("Failed to find route with hash: $hash");
      }

      Map<String, dynamic> map = jsonDecode(file.readAsStringSync());
      backend.currentRoute = BusRoute.fromMap(map);

      backend.Module_Announcement.queueAnnouncement_destination(backend.currentRoute!);

      return Response.ok("Route set to ${map["RouteNumber"]} - ${map["Destination"]}");
    });
    // Get the current route. /current-route
    router.get("/current-route", (Request request) {
      if (backend.currentRoute == null) {
        return Response.ok("No route set");
      }
      return Response.ok(getPrettyJSONString(backend.currentRoute!.toMap()));
    });

    // Upload a route. /upload-route
    router.post("/upload-route", (Request request) async {
      var body = await request.readAsString();

      BusRoute route = BusRoute.fromMap(jsonDecode(body));

      String hash = route.hash;
      Map<String, dynamic> map = jsonDecode(body);

      File file = File("storage/routes/$hash.json");
      file.writeAsStringSync(getPrettyJSONString(map));

      return Response.ok(hash);
    });

    /*
        Vanity stuff
     */

    // Announce stop. /announce-stop
    router.post("/announce-stop", (Request request) async {
      Map<String, dynamic> body = jsonDecode(await request.readAsString());

      BusRouteStop? stopToAnnounce = backend.currentRoute!.stops.firstWhere((element) => element.name == body["stop"], orElse: () => BusRouteStop("", 0, 0));

      if (stopToAnnounce.name == "") {
        return Response.ok("Failed to find stop: ${body["stop"]}");
      }

      backend.Module_Announcement.queueAnnouncement_stop(stopToAnnounce);

      return Response.ok("Announcing stop: ${body["stop"]}");
    });
    // Announce destination. todo: implement this.
    router.get("/announce-destination", (Request request) async {

      BusRoute currentRoute = backend.currentRoute!;
      backend.Module_Announcement.queueAnnouncement_destination(currentRoute);

      return Response.ok("Announcing destination: ${currentRoute.destination}");
    });

    router.get("/ring-bell", (Request request) {
      backend.Module_Announcement.ringBell();
      return Response.ok("Ringing bell");
    });



    /*
      Legacy
     */

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
          getPrettyJSONString({
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
          getPrettyJSONString({
            "locationFix": backend.gpsTracker.isFixed,
            "latitude": backend.gpsTracker.latitude,
            "longitude": backend.gpsTracker.longitude
          })
      );
    });

    // Upload a route. /uploadRoute - Saves the route to a file
    router.post("/uploadRoute", (Request request) async {
      var body = await request.readAsString();

      BusRoute route = BusRoute.fromMap(jsonDecode(body));

      String hash = route.hash;
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
        BusRoute route = BusRoute.fromMap(map);
        String hash = route.hash;

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

          BusRoute route = BusRoute.fromMap(jsonDecode(contents));
          String fileHash = route.hash;

          if (fileHash == hash) {
            Map<String, dynamic> map = jsonDecode(contents);



            backend.currentRoute = BusRoute.fromMap(map);
            ConsoleLog("Route set to ${map["RouteNumber"]} - ${map["RouteDestination"]}");

            backend.matrixDisplay.topLine = "${map["RouteNumber"]} to ${map["RouteDestination"]}";

            return Response.ok("Route set to ${map["RouteNumber"]} - ${map["RouteDestination"]}");
          }
        }
        return Response.ok("Failed to find route with hash: $hash");
      });


      return Response.ok(getPrettyJSONString(routes));
    });

    // Get the current route. /currentRoute
    router.get("/currentRoute", (Request request) {
      if (backend.currentRoute == null) {
        return Response.ok("No route set");
      }
      return Response.ok(getPrettyJSONString(backend.currentRoute!.toMap()));
    });

    // Announce stop. /announceStop?stop=StopName
    router.get("/announceStop", (Request request) {
      String stop = request.url.queryParameters["stop"] ?? "";

      BusRouteStop? stopToAnnounce = backend.currentRoute!.stops.firstWhere((element) => element.name == stop, orElse: () => BusRouteStop("", 0, 0));

      if (stopToAnnounce.name == "") {
        return Response.ok("Failed to find stop: $stop");
      }

      backend.Module_Announcement.queueAnnouncement_stop(stopToAnnounce);

      return Response.ok("Announcing stop: $stop");
    });

    // Test Connection. /testConnection
    router.get("/testConnection", (Request request) {
      return Response.ok("Connection successful");
    });

    var server80   = shelf_io.serve(router, '0.0.0.0', 80);
    var server8080 = shelf_io.serve(router, '0.0.0.0', 8080);
    ConsoleLog("Listening on port 80 and 8080");

  }

}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
