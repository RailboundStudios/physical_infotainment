

// Singleton class to control the matrix display
import 'dart:io';

class MatrixDisplay {
  static final MatrixDisplay _singleton = MatrixDisplay._internal();

  factory MatrixDisplay() {
    return _singleton;
  }

  MatrixDisplay._internal() {
    print("MatrixDisplay singleton created");

    Process.start("./dotnet_server", [""],
        workingDirectory: "/home/imbenji/physical_infotainment/dotnet_server/bin/"
    ).then((process) {
      process.stdout.listen((event) {
        print("Matrix Server: ${String.fromCharCodes(event)}");
        if (String.fromCharCodes(event).contains("Starting matrix")) {
          _matrixServer = process;

          Future.delayed(Duration(seconds: 1), () {
            _topLine = "IMBENJI.NET";
            _bottomLine = "PI-BUS";
          });
        }
      });

    });
  }

  Process? _matrixServer;

  String _topLine = "";
  String _bottomLine = "";
  Color _color = Color(254, 254, 0);
  int _speedMs = 10;

  bool get isReady => _matrixServer != null;

  String get topLine => _topLine;
  void set topLine(String value) {
    _topLine = value;
    print("Top: $value");
    _matrixServer?.stdin.writeln("Top=$value");
  }

  String get bottomLine => _bottomLine;
  void set bottomLine(String value) {
    _bottomLine = value;
    print("Bottom: $value");
    _matrixServer?.stdin.writeln("Bottom=$value");
  }

  Color get color => _color;
  void set color(Color value) {
    _color = value;
    print("Color: $value");
    _matrixServer?.stdin.writeln("Color=${value.red},${value.green},${value.blue}");
  }

  int get SpeedMs => _speedMs;
  void set SpeedMs(int value) {
    _speedMs = value;
    print("Speed: $value");
    _matrixServer?.stdin.writeln("Speed=$value");
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