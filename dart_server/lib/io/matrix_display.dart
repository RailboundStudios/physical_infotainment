

// Singleton class to control the matrix display
import 'dart:io';

import 'package:dart_server/backend/backend.dart';

class MatrixDisplay {
  static final MatrixDisplay _singleton = MatrixDisplay._internal();

  factory MatrixDisplay() {
    return _singleton;
  }

  MatrixDisplay._internal() {


    if (Platform.isWindows) { // Assume test environment
      ConsoleLog("MatrixDisplay: Windows is not supported");
      return;
    }

    ConsoleLog("MatrixDisplay: Initialising");

    Process.start("./dotnet_server", [""],
        workingDirectory: "/home/imbenji/physical_infotainment/dotnet_server/bin/"
    ).then((process) {
      process.stdout.listen((event) {
        ConsoleLog("Matrix Server: ${String.fromCharCodes(event)}");
        if (String.fromCharCodes(event).contains("exit # to quit") && !isReady) {
          _matrixServer = process;

          Future.delayed(Duration(seconds: 1), () {
            ConsoleLog("Matrix Server ready!!!");
            topLine = "IMBENJI.NET";
            bottomLine = "%time";
          });
        }
      });

    });
  }

  Process? _matrixServer;

  String _topLine = "";
  String _bottomLine = "";
  Color _color = Color(231, 164, 57);
  int _speedMs = 10;
  int _timeOffset = 0;
  int _mode = 0; // 0 = Ibus, 1 = S Stock

  bool get isReady => _matrixServer != null;

  String get topLine => _topLine;
  void set topLine(String value) {
    _topLine = value;
    ConsoleLog("Top: $value");
    _matrixServer?.stdin.writeln("Top=$value");
  }

  String get bottomLine => _bottomLine;
  void set bottomLine(String value) {
    _bottomLine = value;
    ConsoleLog("Bottom: $value");
    _matrixServer?.stdin.writeln("Bottom=$value");
  }

  Color get color => _color;
  void set color(Color value) {
    _color = value;
    ConsoleLog("Color: $value");
    _matrixServer?.stdin.writeln("Color=${value.red},${value.green},${value.blue}");
  }

  int get SpeedMs => _speedMs;
  void set SpeedMs(int value) {
    _speedMs = value;
    ConsoleLog("Speed: $value");
    _matrixServer?.stdin.writeln("Speed=$value");
  }

  int get timeOffset => _timeOffset;
  void set timeOffset(int value) {
    _timeOffset = value;
    ConsoleLog("Time Offset: $value");
    _matrixServer?.stdin.writeln("TimeOffset=$value");
  }

  int get mode => _mode;
  void set mode(int value) {
    _mode = value;
    ConsoleLog("Mode: $value");
    _matrixServer?.stdin.writeln("Mode=$value");
  }

  void kill() {
    _matrixServer?.stdin.writeln("exit");
    // _matrixServer?.kill();
  }

  void dispose() {
    kill();
  }


}

class Color {
  final int red;
  final int green;
  final int blue;

  Color(this.red, this.green, this.blue);
}