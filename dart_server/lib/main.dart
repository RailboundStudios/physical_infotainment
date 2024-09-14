// Copyright 2024 IMBENJI.NET. All rights reserved.
// For use of this source code, please see the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_server/backend/backend.dart';

Future<void> main(List<String> arguments) async {

  ConsoleLog("---=== PiBus Server =====================================================---");
  ConsoleLog("Initialising the pi-bus backend...");
  ConsoleLog("---======================================================================---");
  ConsoleLog(" ");

  Directory storageDir = Directory("storage");
  if (!storageDir.existsSync()) {
    storageDir.createSync();
    ConsoleLog("Created storage directory");
  }
  Directory routesDir = Directory("storage/routes");
  if (!routesDir.existsSync()) {
    routesDir.createSync();
    ConsoleLog("Created routes directory");
  }

  late pibus_backend backend; // Create the backend.

  try {

    backend = pibus_backend(); // Initialize the backend.
    backend.init();

    ConsoleLog(" ");
    ConsoleLog("Backend initialized successfully!");
    ConsoleLog("---======================================================================---");

    while (true) {
      await Future.delayed(Duration(seconds: 1));
    }
  } catch (e) {
    ConsoleLog("Error: $e");

    backend.gpsTracker.dispose();
    backend.matrixDisplay.dispose();
  }



}

String getPrettyJSONString(jsonObject){
  var encoder = new JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
