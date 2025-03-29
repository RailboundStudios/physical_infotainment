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

    // Get the ip address of the server.
    String? address;
    while (address == null) {
      try {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type.name == "IPv4") {
              address = addr.address;
            }
          }
        }
      } catch (e) {
        ConsoleLog("Error: $e");
      }
      await Future.delayed(Duration(seconds: 1));
    }
    
    while (!backend.matrixDisplay.isReady) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    backend.matrixDisplay.topLine = "IP: $address";

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