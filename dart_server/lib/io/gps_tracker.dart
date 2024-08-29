
import 'dart:async';
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

  late Timer _timerA;

  GpsTracker(this.serialPort) {

    File file = File(serialPort);
    if (!file.existsSync()) {
      throw Exception("Serial port $serialPort does not exist.");
    }
    RandomAccessFile raf = file.openSync(mode: FileMode.read);

    _timerA = Timer.periodic(Duration(seconds: 1), (timer) {
      print("Getting GPS data from $serialPort");

      List<int> bytes = raf.readSync(1024);

      if (bytes.isEmpty) {
        print("No data received from GPS");
        return;
      }

      String data = String.fromCharCodes(bytes);
      List<String> parts = data.split(",");

      if (parts[0] == "\$GPGGA") { // Check if the data is a GPGGA sentence
        // Check if the data is valid
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
        double _latitude = int.parse(latitudeString.substring(0, 2)) +
            double.parse(latitudeString.substring(2)) / 60;
        double _longitude = int.parse(longitudeString.substring(0, 3)) +
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
      if (parts[0] == "\$GPVTG") { // Check if the data is a GPVTG sentence
        // Get the speed
        _speed = double.parse(parts[7]);
        print("Speed: $_speed");
        return;
      }

      if (_time.difference(DateTime.now()).inSeconds > 2) {
        print("No GPS data received in 10 seconds");
        _isFixed = false;
      }

    });


  }

  void dispose() {
    // Close the serial port
    _timerA.cancel();
  }


}