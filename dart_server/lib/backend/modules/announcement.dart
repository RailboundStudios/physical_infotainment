// Copyright 2024 IMBENJI.NET. All rights reserved.
// For use of this source code, please see the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_server/backend/backend.dart';
import 'package:dart_server/backend/modules/FFmpegWrapper.dart';
import 'package:dart_server/route.dart';
import 'package:dart_server/utils/delegates.dart';
import 'info_module.dart';

class AnnouncementModule extends InfoModule {

  // Constructor
  AnnouncementModule() {
    refreshTimer();

    // ffmpeg.();

    // Initial cut-off mitigation.
    // When using some bluetooth modules, the start of the audio is cut off.
    // This is a workaround to mitigate that.
    // We will play quiet noise on a loop to keep the audio channel open.
    // Future.delayed(Duration.zero).then((value) async {
    //   while (true) {
    //     if (Platform.isLinux) {
    //       await noisePlayer.playFromFile(File("dart_server/assets/audio/noise.mp3"), volume: 0.01, loop: true);
    //     } else {
    //       await noisePlayer.playFromFile(File("assets/audio/noise.mp3"), volume: 0.01, loop: true);
    //     }
    //   }
    // }); THIS S... IT IS THE MOST ANNOYING THING

  }


  // Queue
  List<AnnouncementQueueEntry> queue = [];
  AnnouncementQueueEntry? currentAnnouncement;
  DateTime? currentAnnouncementTimeStamp;
  String defaultText = "*** NO MESSAGE ***";
  bool isPlaying = false;
  DateTime? lastAnnouncementTime;

  bool bluetoothMode = true; // Some bluetooth speakers go into sleep, we need to play a sound to wake it up or else it will cut off a second of our announcement.

  // Audio
  FFplayAudioPlayer announcementPlayer = FFplayAudioPlayer();
  FFplayAudioPlayer noisePlayer = FFplayAudioPlayer(volume: 0.1);
  FFplayAudioPlayer bellPlayer = FFplayAudioPlayer();

  // Events
  final EventDelegate<AnnouncementQueueEntry> onAnnouncement = EventDelegate();

  // Timer
  Timer refreshTimer() => Timer.periodic(const Duration(milliseconds: 10), (timer) async {

    if (!isPlaying && queue.isNotEmpty) { // If nothift is playing and there is an announcement in the queue

      double secondsSinceLastAnnouncement = lastAnnouncementTime != null ? DateTime.now().difference(lastAnnouncementTime!).inSeconds.toDouble() : 0;
      isPlaying = true;
      if (secondsSinceLastAnnouncement >= 2) {
        // If the last announcement was more than 2 seconds ago...
        // We need to play a sound to wake up the bluetooth speaker

        if (bluetoothMode) {
          Uint8List noise = Platform.isLinux ? File("dart_server/assets/audio/noise.mp3").readAsBytesSync() : File("assets/audio/noise.mp3").readAsBytesSync();

          await announcementPlayer.playFromUint8List(noise);
        }
      }


      AnnouncementQueueEntry nextAnnouncement = queue.first;

      currentAnnouncement = nextAnnouncement;
      currentAnnouncementTimeStamp = DateTime.now(); // todo: replace this with the rtc module or gps module

      backend.matrixDisplay.topLine = currentAnnouncement!.displayText;

      onAnnouncement.trigger(currentAnnouncement!);

      if (currentAnnouncement!.audioBytes.isNotEmpty) {

        // Prime all of the audio sources to be ready to play
        for (Uint8List source in currentAnnouncement!.audioBytes) {
          // await playSoundFromBytes(source);
          await announcementPlayer.playFromUint8List(source);
          ConsoleLog("Playing audio");
        }

      } else {
        if (queue.isNotEmpty) {
          // await Future.delayed(const Duration(seconds: 2));
        }
      }

      isPlaying = false;
      queue.removeAt(0);
      lastAnnouncementTime = DateTime.now();
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
    ConsoleLog("Announcement queued: ${announcement.displayText}, with audio: ${announcement.audioBytes.length}");



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
          File("dart_server/assets/audio/to_destination.mp3").readAsBytesSync()
        else
          File("assets/audio/to_destination.mp3").readAsBytesSync(),
        if (route.destinationAudio != null) route.destinationAudio!,
      ],
    ));
  }

  Future<void> ringBell() async {
    if (Platform.isWindows) {
      await bellPlayer.playFromFile(File("assets/audio/envirobell.mp3"));
    } else {
      await bellPlayer.playFromFile(File("dart_server/assets/audio/envirobell.mp3"));
    }

    backend.matrixDisplay.bottomLine = "Bus Stopping".toUpperCase();
  }

  Future<void> resetBell() async {
    backend.matrixDisplay.bottomLine = "%time";
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

var abs = (int value) => value < 0 ? -value : value;