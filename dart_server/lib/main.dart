import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_server/backend/backend.dart';

Future<void> main(List<String> arguments) async {

  print("---=== PiBus Server =====================================================---");
  print("Initialising the pi-bus backend...");
  print("---======================================================================---");
  print(" ");

  Directory storageDir = Directory("storage");
  if (!storageDir.existsSync()) {
    storageDir.createSync();
    print("Created storage directory");
  }
  Directory routesDir = Directory("storage/routes");
  if (!routesDir.existsSync()) {
    routesDir.createSync();
    print("Created routes directory");
  }

  late pibus_backend backend; // Create the backend.

  try {

    backend = pibus_backend(); // Initialize the backend.
    backend.init();

    print(" ");
    print("Backend initialized successfully!");
    print("---======================================================================---");

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
