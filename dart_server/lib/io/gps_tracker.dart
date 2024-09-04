
import 'dart:io';
import 'package:libserialport/libserialport.dart';

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

  Duration _utcOffset = Duration.zero;
  DateTime get utcTime => DateTime.now().toUtc().add(_utcOffset);

  GpsTracker(this.serialPort) {

    SerialPort serial = SerialPort(serialPort);

    if (!serial.openRead()) {
      throw Exception("Failed to open serial port: $serialPort");
    }

    SerialPortReader reader = SerialPortReader(serial);

    print("GpsTracker: Listening to GPS data");
    reader.stream.listen((event) {

      String decoded = String.fromCharCodes(event);

      print("GpsTracker: ${decoded}");

      try {
        if (decoded.contains("GPGGA")) {
          List<String> parts = decoded.split(",");
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

          DateTime now = DateTime.now();
          DateTime gpsTime = DateTime(now.year, now.month, now.day, hour, minute, second.toInt(), (second * 1000).toInt());

          _utcOffset = gpsTime.difference(now);

          print("Latitude: $_latitude, Longitude: $_longitude");
          return;
        }
        if (decoded.contains("GPVTG")) {
          // Get the speed
          _speed = double.parse(decoded.split(",")[7]);
          print("Speed: $_speed");
          return;
        }
      } catch (e) {
        print("Error parsing GPS data: $e");
      }

    });

  }

  void dispose() {
    // Close the serial port
    // _timerA.cancel();
    // raf.closeSync();
    print("GPS tracker disposed");
  }


}