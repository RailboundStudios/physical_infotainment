
import 'dart:io';

class GpsTracker {

  final String serialPort;

  bool _isFixed = false;
  bool get isFixed => _isFixed;

  bool _hasEverFixed = false;
  bool get hasEverFixed => _hasEverFixed;

  double _latitude = 0;
  double get latitude => _latitude;

  double _longitude = 0;
  double get longitude => _longitude;

  /// Speed in km/h
  double _speed = 0;
  double get speed => _speed;

  DateTime _time = DateTime.now();


  GpsTracker(this.serialPort) {

    File file = File(serialPort);
    if (!file.existsSync()) {
      throw Exception("Serial port $serialPort does not exist.");
    }
    Process.run("cat", [serialPort]).then((ProcessResult result) {
      result.stdout.listen((event) {

        if (event.toString().contains("GPGGA")) {
          List<String> parts = event.toString().split(",");
          if (parts[6] == "0") { // 0:unpositioned 1:SPS mode, position valid 2:Differential, SPS mode, position valid, 3:PPS mode, position valid
            print("No GPS fix");
            _isFixed = false;
            return;
          }
          _isFixed = true;
          _hasEverFixed = true;

          // Get the latitude and longitude
          String latitudeString = parts[2]; // ddmm.mmmm
          String longitudeString = parts[4]; // dddmm.mmmm

          // Convert latitude and longitude to decimal degrees
          _latitude = int.parse(latitudeString.substring(0, 2)) +
              double.parse(latitudeString.substring(2)) / 60;
          _longitude = int.parse(longitudeString.substring(0, 3)) +
              double.parse(longitudeString.substring(3)) / 60;

          bool isNorth = parts[3] == "N";
          bool isEast = parts[5] == "E";

          if (!isNorth) {
            _latitude = -_latitude;
          }
          if (!isEast) {
            _longitude = -_longitude;
          }

          String timeString = parts[1];
          int hour = int.parse(timeString.substring(0, 2));
          int minute = int.parse(timeString.substring(2, 4));
          double second = double.parse(timeString.substring(4, 9));

          _time = DateTime(_time.year, _time.month, _time.day, hour, minute, second.toInt(), (second * 1000).toInt());

          print("Latitude: $_latitude, Longitude: $_longitude");
          return;
        }
        if (event.toString().contains("GPVTG")) {
          // Get the speed
          _speed = double.parse(event.toString().split(",")[7]);
          print("Speed: $_speed");
          return;
        }

      });
    });

  }

  void dispose() {
    // Close the serial port
    // _timerA.cancel();
    // raf.closeSync();
    print("GPS tracker disposed");
  }


}