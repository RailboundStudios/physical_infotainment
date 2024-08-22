import 'dart:io';

import 'package:dart_server/main.dart' as dart_server;

Future<void> main(List<String> arguments) async {

  // Start the matrix server. The server relies on commands to control the matrix.
  // The server is written in dotnet, located: ../../dotnet_server/bin/Debug/net6.0/dotnet_server.dll
  // The server is started with the command: dotnet dotnet_server.dll

  String dotnetPath = "/home/imbenji/.dotnet/dotnet";

  Process matrixServer = await Process.start(dotnetPath, ["/dotnet_server/bin/dotnet_server.dll"]);

  matrixServer.stdin.writeln("top=Hello from Dart!");

  while (true) {}

}
