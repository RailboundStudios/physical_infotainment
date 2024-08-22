import 'dart:io';

import 'package:dart_server/dart_server.dart' as dart_server;

Future<void> main(List<String> arguments) async {

  // Start the matrix server. The server relies on commands to control the matrix.
  // The server is written in dotnet, located: ../../dotnet_server/bin/Debug/net6.0/dotnet_server.dll
  // The server is started with the command: dotnet dotnet_server.dll

  Process matrixServer = await Process.start("dotnet", ["../../dotnet_server/bin/Debug/net6.0/dotnet_server.dll"]);

  matrixServer.stdin.writeln("top=Hello from Dart!");

}
