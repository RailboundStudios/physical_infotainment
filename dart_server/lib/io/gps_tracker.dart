
import 'dart:async';
import 'dart:io';

class GpsTracker {

  final String serialPort;

  double _latitude = 0;
  double _longitude = 0;
  double get latitude => _latitude;
  double get longitude => _longitude;

  GpsTracker(this.serialPort) {

    File file = File(serialPort);
    if (!file.existsSync()) {
      throw Exception("Serial port $serialPort does not exist.");
    }
    RandomAccessFile raf = file.openSync(mode: FileMode.read);

    Timer.periodic(Duration(seconds: 1), (timer) {
      print("Getting GPS data from $serialPort");

      List<int> bytes = raf.readSync(1024);

      if (bytes.isEmpty) {
        print("No data received from GPS");
        return;
      }

      String data = String.fromCharCodes(bytes);
      List<String> parts = data.split(",");

      if (parts[0] != "\$GPGGA") { // Check if the data is a GPGGA sentence
        return;
      }

      // Check if the data is valid
      if (parts[6] == "0") { // 0:unpositioned 1:SPS mode, position valid 2:Differential, SPS mode, position valid, 3:PPS mode, position valid
        print("No GPS fix");
        return;
      }

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

      print("Latitude: $_latitude, Longitude: $_longitude");
    });
  }


}