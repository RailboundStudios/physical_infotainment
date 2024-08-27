import 'dart:io';

import 'package:bluez/bluez.dart';
import 'package:dart_server/io/gps_tracker.dart';
import 'package:dart_server/main.dart' as dart_server;

Future<void> main(List<String> arguments) async {

  print("Starting the dart server");

  // Start the matrix server. The server relies on commands to control the matrix.
  // The server is written in dotnet, located: ../../dotnet_server/bin/Debug/net6.0/dotnet_server.dll
  // The server is started with the command: dotnet dotnet_server.dll

  String dotnetPath = "/home/imbenji/.dotnet/dotnet";
  String currentDirectory = Directory.current.path;

  Process matrixServer = await Process.start("./dotnet_server", [""],
      workingDirectory: "/home/imbenji/physical_infotainment/dotnet_server/bin/"
  );

  bool matrixServerStarted = false;

  matrixServer.stdout.listen((event) {
    print("Matrix Server: ${String.fromCharCodes(event)}");
    if (String.fromCharCodes(event).contains("Starting matrix")) {
      matrixServerStarted = true;
    }
  });

  while (!matrixServerStarted) {
    await Future.delayed(Duration(seconds: 1));
  }

  matrixServer.stdin.writeln("Top=Great Titchfield Street / Photographers' Gallery for Oxford Circus Station");

  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }

}
