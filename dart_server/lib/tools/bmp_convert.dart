import 'dart:io';
import 'dart:typed_data';
import 'package:dart_server/backend/backend.dart';
import 'package:image/image.dart';

void main() async {
  // Load the image file
  final imagePath = "C:\\Development\\Repositories\\physical_infotainment\\dotnet_server\\dotnet_server\\assets\\logo.bmp";
  final file = File(imagePath);
  final imageBytes = file.readAsBytesSync();

  // Decode the image
  final image = decodeImage(imageBytes);

  if (image == null) {
    ConsoleLog('Could not decode image.');
    return;
  }

  // Get image dimensions
  final width = image.width;
  final height = image.height;

  // Prepare the output string
  StringBuffer output = StringBuffer();
  output.writeln(width);
  output.writeln(height);

  // Get RGB values and add them to the output
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      final r = getRed(pixel);
      final g = getGreen(pixel);
      final b = getBlue(pixel);
      output.write('$r,$g,$b,');
    }
  }

  // Remove the last comma
  final result = output.toString().substring(0, output.length - 1);

  // ConsoleLog the result or save it to a file
  ConsoleLog(result);

  Directory outputDir = file.parent;

  // Optionally, save the result to a file
  final outputFile = File('${outputDir.path}/output.txt');
  outputFile.writeAsStringSync(result);
}
