

class Constants {

  // Singleton
  static final Constants _singleton = Constants._internal();

  factory Constants() {
    return _singleton;
  }

  Constants._internal() {
    print("Constants singleton created");
  }

  // Constants
  String? serverAddress = "10.0.0.1"; // This is the ip address of the server if connected to its access point.


}