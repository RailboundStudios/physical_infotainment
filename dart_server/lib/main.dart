import 'dart:io';

import 'package:dart_server/io/gps_tracker.dart';
import 'package:dart_server/io/matrix_display.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main(List<String> arguments) async {

  print("Starting the dart server");

  MatrixDisplay matrixDisplay = MatrixDisplay();
  GpsTracker gpsTracker = GpsTracker("/dev/ttyACM0");

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

  // get the displayInfo. /displayInfo
  router.get("/displayInfo", (Request request) {
    return Response.ok(
      {
        "topText": matrixDisplay.topLine,
        "bottomText": matrixDisplay.bottomLine,
        "textColor": [matrixDisplay.color.red, matrixDisplay.color.green, matrixDisplay.color.blue],
      }
    );
  });

  // get the locationInfo. /locationInfo
  router.get("/locationInfo", (Request request) {
    return Response.ok(
      {
        "locationFix": gpsTracker.isFixed,
        "latitude": gpsTracker.latitude,
        "longitude": gpsTracker.longitude
      }
    );
  });

  var server = await shelf_io.serve(router, 'localhost', 8080);

  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }

}
