

// Singleton class to control the matrix display
class MatrixDisplay {
  static final MatrixDisplay _singleton = MatrixDisplay._internal();

  factory MatrixDisplay() {
    return _singleton;
  }

  MatrixDisplay._internal() {
    print("MatrixDisplay singleton created");
  }

  String _topLine = "";
  String _bottomLine = "";

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
}