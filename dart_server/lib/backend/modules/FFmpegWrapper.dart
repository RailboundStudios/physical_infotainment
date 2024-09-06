import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:dart_server/backend/backend.dart';

class FFplayAudioPlayer {
  Process? _ffplayProcess;
  bool _isPlaying = false;

  Future<void> _initializeFFplay(String format) async {
    _ffplayProcess = await Process.start(
      'ffplay',
      ['-f', format, '-', '-autoexit'],
      mode: ProcessStartMode.normal
    );

    _ffplayProcess!.stderr.listen((data) {
      final output = utf8.decode(data);
      ConsoleLog(output);
      if (output.contains('aq=    0KB') && _isPlaying) {
        // Handle end of playback
        ConsoleLog('Playback finished');
        _isPlaying = false;
      }
      // You can refine the condition based on more specific output
    });
  }

  Future<void> playFromUint8List(Uint8List audioData, String format) async {

    format = 'mp3';

    // Initialize ffplay with the provided format
    if (_ffplayProcess == null) await _initializeFFplay(format);
    await _writeToProcess(audioData);
    await _waitForCompletion();
  }

  Future<void> playFromFile(File file, String format) async {
    final audioData = await file.readAsBytes();
    await playFromUint8List(audioData, format);
  }

  Future<void> _writeToProcess(Uint8List data) async {

    _ffplayProcess!.stdin.add(data);
    await Future.delayed(Duration(milliseconds: 1000));
    _isPlaying = true;
    await _ffplayProcess!.stdin.flush();
  }

  Future<void> _waitForCompletion() async {
    // Wait for the stderr stream to contain the 'Exiting' message
    while (_isPlaying) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  Future<void> dispose() async {
    _ffplayProcess?.stdin.close();
    await _ffplayProcess?.exitCode;
    _ffplayProcess = null;
  }
}
