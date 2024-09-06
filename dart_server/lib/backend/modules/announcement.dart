
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/delegates.dart';

import 'info_module.dart';

class AnnouncementModule extends InfoModule {

  // Constructor
  AnnouncementModule() {
    refreshTimer();

    // Initial cut-off mitigation.
    // When using some bluetooth modules, the start of the audio is cut off.
    // This is a workaround to mitigate that.
    // We will play quiet noise on a loop to keep the audio channel open.
    // We can do this on a separate thread.
    Isolate.spawn((_) async {
      while (true) {
        if (Platform.isLinux) {
          await playSound(File("dart_server/assets/audio/noise.mp3"), volume: 0.01);
        } else {
          await playSound(File("assets/audio/noise.mp3"), volume: 0.01);
        }
      }
    }, null);

  }


  // Queue
  List<AnnouncementQueueEntry> queue = [];
  AnnouncementQueueEntry? currentAnnouncement;
  DateTime? currentAnnouncementTimeStamp;
  String defaultText = "*** NO MESSAGE ***";
  bool isPlaying = false;

  // Audio

  // Events
  final EventDelegate<AnnouncementQueueEntry> onAnnouncement = EventDelegate();

  // Timer
  Timer refreshTimer() => Timer.periodic(const Duration(milliseconds: 10), (timer) async {

    if (!isPlaying) {

      if (queue.isNotEmpty) {
        isPlaying = true;
        AnnouncementQueueEntry nextAnnouncement = queue.first;

        currentAnnouncement = nextAnnouncement;
        currentAnnouncementTimeStamp = DateTime.now(); // todo: replace this with the rtc module or gps module

        backend.matrixDisplay.topLine = currentAnnouncement!.displayText;

        onAnnouncement.trigger(currentAnnouncement!);

        if (currentAnnouncement!.audioBytes.isNotEmpty) {

          // Prime all of the audio sources to be ready to play
          for (Uint8List source in currentAnnouncement!.audioBytes) {
            await playSoundFromBytes(source);
          }

        } else {
          if (queue.isNotEmpty) {
            // await Future.delayed(const Duration(seconds: 2));
          }
        }

        isPlaying = false;
        queue.removeAt(0);

      }



    }


  });

  // Will call the callback function if the announcement will be proceeding
  Future<bool> _internalAccountForInconsistentTime({
    required AnnouncementQueueEntry announcement,
    required Duration timerInterval,
    required Function() callback
  }) async {
    DateTime now = DateTime.now();
    if (announcement.scheduledTime != null) {

      if (now.isAfter(announcement.scheduledTime!)) {
        callback();
        return true;
      }

      int milisecondDifference = abs(now.millisecondsSinceEpoch - announcement.scheduledTime!.millisecondsSinceEpoch);
      if (milisecondDifference <= timerInterval.inMilliseconds) {
        // Account for the time lost by the periodic timer
        callback();
        await Future.delayed(Duration(milliseconds: timerInterval.inMilliseconds - milisecondDifference));
        return true;
      } else {
        return false;
      }
    } else {
      callback();
      return true;
    }
  }

  // Methods
  Future<void> queueAnnouncement(AnnouncementQueueEntry announcement) async {
    print("Announcement queued: ${announcement.displayText}, with audio: ${announcement.audioBytes.length}");
    queue.add(announcement);
  }

  // Constants

  final List<NamedAnnouncementQueueEntry> manualAnnouncements = [
    // NamedAnnouncementQueueEntry(
    //   shortName: "Driver Change",
    //   displayText: "Driver Change",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/driverchange.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "No Standing Upr Deck",
    //   displayText: "No standing on the upper deck",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/nostanding.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Face Covering",
    //   displayText: "Please wear a face covering!",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/facecovering.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Seats Upstairs",
    //   displayText: "Seats are available upstairs",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/seatsupstairs.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Bus Terminates Here",
    //   displayText: "Bus terminates here. Please take your belongings with you",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/busterminateshere.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Bus On Diversion",
    //   displayText: "Bus on diversion. Please listen for further announcements",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/busondiversion.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Destination Change",
    //   displayText: "Destination Changed - please listen for further instructions",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/destinationchange.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Wheelchair Space",
    //   displayText: "Wheelchair space requested",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/wheelchairspace1.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Move Down The Bus",
    //   displayText: "Please move down the bus",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/movedownthebus.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Next Stop Closed",
    //   displayText: "The next bus stop is closed",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/nextstopclosed.wav")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "CCTV In Operation",
    //   displayText: "CCTV is in operation on this bus",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/cctvoperation.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Safe Door Opening",
    //   displayText: "Driver will open the doors when it is safe to do so",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/safedooropening.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Buggy Safety",
    //   displayText: "For your child's safety, please remain with your buggy",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/buggysafety.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Wheelchair Space 2",
    //   displayText: "Wheelchair priority space required",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/wheelchairspace2.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Service Regulation",
    //   displayText: "Regulating service - please listen for further information",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/serviceregulation.mp3")],
    // ),
    // NamedAnnouncementQueueEntry(
    //   shortName: "Bus Ready To Depart",
    //   displayText: "This bus is ready to depart",
    //   audioSources: [AudioWrapperAssetSource("audio/manual_announcements/readytodepart.mp3")],
    // ),
  ];

  void queueAnnouncement_stop(BusRouteStop stopToAnnounce) {
    queueAnnouncement(AnnouncementQueueEntry(
      displayText: stopToAnnounce.name,
      audioBytes: [
        if (stopToAnnounce.audio != null) stopToAnnounce.audio!
      ],
    ));
  }

  void queueAnnouncement_destination(BusRoute route) {
    Directory workingDirectory = Directory.current;

    queueAnnouncement(AnnouncementQueueEntry(
      displayText: "${route.routeNumber} to ${route.destination}",
      audioBytes: [
        if (route.routeAudio != null) route.routeAudio!,
        if (Platform.isLinux)
          File("dart_server/assets/audio/to_destination.wav").readAsBytesSync()
        else
          File("assets/audio/to_destination.wav").readAsBytesSync(),
        if (route.destinationAudio != null) route.destinationAudio!,
      ],
    ));
  }

  Future<void> ringBell() async {
    if (Platform.isWindows) {
      await playSound(File("assets/audio/envirobell.mp3"));
    } else {
      await playSound(File("dart_server/assets/audio/envirobell.mp3"));
    }

    backend.matrixDisplay.bottomLine = "Bus Stopping".toUpperCase();
  }
}

class AnnouncementQueueEntry {
  final String displayText;
  final List<Uint8List> audioBytes;
  bool sendToServer = true;
  DateTime? scheduledTime;
  DateTime? timestamp;

  AnnouncementQueueEntry({required this.displayText, required this.audioBytes, this.sendToServer = true, this.scheduledTime, this.timestamp});
}

class NamedAnnouncementQueueEntry extends AnnouncementQueueEntry {
  final String shortName;

  NamedAnnouncementQueueEntry({
    required this.shortName,
    required String displayText,
    required List<Uint8List> audioBytes,
    DateTime? scheduledTime,
    DateTime? timestamp,
    bool sendToServer = true,
  }) : super(
    displayText: displayText,
    audioBytes: audioBytes,
    sendToServer: sendToServer,
    scheduledTime: scheduledTime,
    timestamp: timestamp
  );

}

Future<void> playSoundFromBytes(Uint8List sound) async {
  // If a temp directory doesnt exist, create one.
  final tempDir = Directory('tmp');
  if (!tempDir.existsSync()) {
    tempDir.createSync();
  }

  String hash = tempDir.listSync().length.toString(); // This is faster than hashing the sound data.

  // Create a temporary file to store the sound.
  final tempFile = File('${tempDir.path}/$hash.wav');
  tempFile.createSync();
  tempFile.writeAsBytesSync(sound);

  await playSound(tempFile);
}

// Play the sound using ffmpeg.
Future<void> playSound(File sound, {
  double volume = 1.0, // Volume from 0.0 to 1.0
}) async {
  print('Playing sound...');

  // Play the sound using ffplay. without ui
  await Process.run('ffplay', [
    sound.path,
    "-autoexit",
    "-nodisp",
    "-volume", "${(volume * 100).toInt()}",
  ]);

  print('Sound played.');
}

final soundLengthCache = <String, Duration>{};

// Get the length of the sound file.
Future<Duration> getSoundLength(Uint8List sound) async {

  String hash = sha256.convert(sound).toString();

  // Check if the sound length is cached.
  if (soundLengthCache.containsKey(hash)) {
    return soundLengthCache[hash]!;
  }

  // If a temp directory doesnt exist, create one.
  final tempDir = Directory('tmp');
  if (!tempDir.existsSync()) {
    tempDir.createSync();
  }

  // Create a temporary file to store the sound.
  final tempFile = File('${tempDir.path}/$hash.wav');
  tempFile.createSync();
  tempFile.writeAsBytesSync(sound);

  // Get the length of the sound file.
  final result = await Process.run('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'default=noprint_wrappers=1:nokey=1',
    tempFile.path,
  ]);

  // Parse the result.
  final length = double.parse(result.stdout.toString().trim());

  // Cache the result.
  soundLengthCache[hash] = Duration(seconds: length.toInt());

  return Duration(seconds: length.toInt());
}

var abs = (int value) => value < 0 ? -value : value;