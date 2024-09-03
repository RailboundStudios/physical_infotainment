import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_server/backend/backend.dart';

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

  late pibus_backend backend; // Create the backend.

  try {

    backend = pibus_backend(); // Initialize the backend.
    backend.init();

    while (true) {
      await Future.delayed(Duration(seconds: 1));
    }
  } catch (e) {
    print("Error: $e");

    backend.gpsTracker.dispose();
    backend.matrixDisplay.dispose();
  }



}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
