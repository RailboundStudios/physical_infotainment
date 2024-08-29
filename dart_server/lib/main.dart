import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_server/backend/backend.dart';
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

  pibus_backend backend = pibus_backend(); // Create the backend.

  while (true) {
    // read input, if "exit" then break
    print("Enter a command:");
    String? input = stdin.readLineSync();
    if (input == "exit") {
      break;
    }
  }

  backend.gpsTracker.dispose();
  backend.matrixDisplay.dispose();

}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
