import 'dart:io';

import 'package:dart_server/main.dart' as dart_server;

Future<void> main(List<String> arguments) async {

  print("Starting the dart server");

  // Start the matrix server. The server relies on commands to control the matrix.
  // The server is written in dotnet, located: ../../dotnet_server/bin/Debug/net6.0/dotnet_server.dll
  // The server is started with the command: dotnet dotnet_server.dll

  String dotnetPath = "/home/imbenji/.dotnet/dotnet";
  String currentDirectory = Directory.current.path;

  Process matrixServer = await Process.start("./dotnet_server/bin/dotnet_server", [""],
      workingDirectory: "./dotnet_server/bin/"
  );

  matrixServer.stdout.listen((event) {
    print("Matrix Server: ${String.fromCharCodes(event)}");
  });

  while (true) {
    matrixServer.stdin.writeln("Top=Hello from Dart!");
    await Future.delayed(Duration(seconds: 1));
  }

}
