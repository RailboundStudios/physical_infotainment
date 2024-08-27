

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
        }
      });

    });
  }

  Process? _matrixServer;

  String _topLine = "";
  String _bottomLine = "";
  Color _color = Color(254, 254, 0);

  bool get isReady => _matrixServer != null;

  String get topLine => _topLine;
  void set topLine(String value) {
    topLine = value;
    print("Top: $value");
  }

  String get bottomLine => _bottomLine;
  void set bottomLine(String value) {
    bottomLine = value;
    print("Bottom: $value");
  }

  Color get color => _color;
  void set color(Color value) {
    color = value;
    print("Color: $value");
  }

  void kill() {
    _matrixServer?.kill();
  }


}

class Color {
  final int red;
  final int green;
  final int blue;

  Color(this.red, this.green, this.blue);
}