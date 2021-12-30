import 'dart:async';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:voice_effect/effect_options.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({Key? key}) : super(key: key);

  @override
  VoiceScreenState createState() => VoiceScreenState();
}

class VoiceScreenState extends State<VoiceScreen> {
  late FlutterSoundRecorder _myRecorder;
  final audioPlayer = AssetsAudioPlayer();
  late String filePath;
  List file = [];
  Timer? timer;
  Duration duration = const Duration();

  double pitch = 1;
  double speed = 1;

  var box = Hive.box('myBox');

  late bool isFirst;

  String effectTitle = 'Listeden bir ses efekti seçiniz';

  @override
  void initState() {
    isFirst = box.get('isFirst', defaultValue: true);
    super.initState();
    startIt();
    _listofFiles();
  }

  void startIt() async {
    String record = DateFormat('kk-mm-ss - d.M.y').format(DateTime.now());
    //? iki noktalı gösterim hataya sebep oluyor example:kk:mm:ss
    filePath = '/storage/emulated/0/Download/flutter-voice/$record.wav';
    _myRecorder = FlutterSoundRecorder();
    await _myRecorder.openAudioSession(
        focus: AudioFocus.requestFocusAndStopOthers,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        device: AudioDevice.speaker);
    await _myRecorder.setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours.remainder(60));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.deepPurple.shade200,
            centerTitle: true,
            title: const Text('Voice Changer'),
            elevation: 0,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  text: 'Ses Kaydedici',
                ),
                Tab(
                  text: 'Ses Değiştirici',
                ),
              ],
            ),
          ),
          body: TabBarView(children: [
            voiceRecorderWidget(context, hours, minutes, seconds),
            voiceChangerWidget(),
          ])),
    );
  }

  Column voiceRecorderWidget(BuildContext context, String hours, String minutes, String seconds) {
    return Column(
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.shade200,
                  Colors.deepPurple.shade400,
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(MediaQuery.of(context).size.width, 100.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildTimeCard(header: 'SAAT', time: hours),
                const SizedBox(width: 12),
                buildTimeCard(header: 'DAKİKA', time: minutes),
                const SizedBox(width: 12),
                buildTimeCard(header: 'SANİYE', time: seconds),
              ],
            )),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildElevatedButton(icon: Icons.mic, iconColor: Colors.red, f: record, text: 'Kaydı Başlat'),
            const SizedBox(
              width: 30,
            ),
            buildElevatedButton(
                icon: Icons.stop, iconColor: Colors.black.withOpacity(0.83), f: stopRecord, text: 'Kaydı Durdur'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(height: 0),
              itemCount: file.length,
              itemBuilder: (context, index) {
                int myIndex = file.length - 1 - index;
                String itemName = file[myIndex]
                    .toString()
                    .replaceAll("File: '/storage/emulated/0/Download/flutter-voice/", '')
                    .replaceAll("'", '');
                return InkWell(
                  onTap: () {
                    String audioPath = file[myIndex].toString().replaceAll('File: ', '').replaceAll("'", '');
                    startPlaying(audioPath);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(
                        Icons.music_note,
                        color: Colors.deepPurple.shade400,
                      ),
                      title: Text(
                        itemName,
                        style: TextStyle(color: Colors.black.withOpacity(0.83), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                );
              }),
        )
      ],
    );
  }

  voiceChangerWidget() {
    return Column(
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.shade200,
                  Colors.deepPurple.shade400,
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(MediaQuery.of(context).size.width, 100.0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * .65,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    color: Colors.grey.shade100,
                                    width: MediaQuery.of(context).size.width,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Ses Efektleri',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black.withOpacity(0.8))),
                                          InkWell(
                                              onTap: () {
                                                Navigator.of(context, rootNavigator: true).pop('bottomSheet');
                                              },
                                              child: const Icon(Icons.close)),
                                        ],
                                      ),
                                    )),
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: EffectOptions.effectOptionsList.length,
                                    itemBuilder: (context, index) {
                                      return effectOption(context, EffectOptions.effectOptionsList[index]);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white60,
                                  Colors.white70,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Row(
                                  children: [
                                    const Icon(CupertinoIcons.speaker_2_fill),
                                    const SizedBox(width: 12),
                                    Text(effectTitle),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down_rounded),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Efekti seçtikten sonra listeden oynatmak istediğiniz ses kaydına dokunun',
                    style: TextStyle(color: Colors.white), textAlign: TextAlign.center)
              ],
            )),
        Expanded(
          child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(height: 0),
              itemCount: file.length,
              itemBuilder: (context, index) {
                int myIndex = file.length - 1 - index;
                String itemName = file[myIndex]
                    .toString()
                    .replaceAll("File: '/storage/emulated/0/Download/flutter-voice/", '')
                    .replaceAll("'", '');
                return InkWell(
                  onTap: () async {
                    String audioPath = file[myIndex].toString().replaceAll('File: ', '').replaceAll("'", '');
                    startPlaying(audioPath);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(
                        Icons.music_note,
                        color: Colors.deepPurple.shade400,
                      ),
                      title: Text(
                        itemName,
                        style: TextStyle(color: Colors.black.withOpacity(0.83), fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.play_arrow, color: Colors.deepPurple),
                    ),
                  ),
                );
              }),
        ),
      ],
    );
  }

  Widget effectOption(BuildContext context, EffectOptions effectOptions) {
    return InkWell(
      onTap: () {
        setState(() {
          effectTitle = effectOptions.title;
        });
        pitch = effectOptions.pitch;
        speed = effectOptions.speed;
        audioPlayer.setPitch(effectOptions.pitch);
        audioPlayer.setPlaySpeed(effectOptions.speed);
        Navigator.of(context, rootNavigator: true).pop('bottomSheet');
      },
      child: ListTile(
        title: Text(effectOptions.title),
        leading: Icon(effectOptions.icon),
      ),
    );
  }

  ElevatedButton buildElevatedButton(
      {required IconData icon, required Color iconColor, required Function f, required String text}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12.0),
        side: BorderSide(
          color: Colors.deepPurple.shade400,
          width: 4.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        primary: Colors.white,
        elevation: 10.0,
      ),
      onPressed: () => f(),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 35.0,
          ),
          Text(
            text,
            style: TextStyle(color: Colors.black.withOpacity(0.83), fontSize: 12),
          )
        ],
      ),
    );
  }

  void _listofFiles() async {
    file = Directory('/storage/emulated/0/Download/flutter-voice/').listSync();
  }

  Future<void> record() async {
    startTimer();
    late Directory dir;
    if (isFirst) {
      dir = Directory(path.dirname(filePath));
      isFirst = false;
      box.put('isFirst', false);
    } else {
      String record = DateFormat('kk-mm-ss - d.M.y').format(DateTime.now());
      filePath = '/storage/emulated/0/Download/flutter-voice/$record.wav';
      dir = Directory(path.dirname(filePath));
    }

    if (!dir.existsSync()) {
      //? hata verebilir burası
      dir.createSync();
    }

    await _myRecorder.openAudioSession();
    await _myRecorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );
  }

  Future<String?> stopRecord() async {
    setState(() {
      _listofFiles();
      duration = const Duration();
      timer?.cancel();
    });
    _myRecorder.closeAudioSession();
    return await _myRecorder.stopRecorder();
  }

  Future<void> startPlaying(String path) async {
    audioPlayer.open(
      Audio.file(path),
      autoStart: true,
      showNotification: true,
      pitch: pitch,
      playSpeed: speed,
    );
  }

  Future<void> stopPlaying() async {
    audioPlayer.stop();
  }

  void addTime() {
    setState(() {
      final seconds = duration.inSeconds + 1;
      duration = Duration(seconds: seconds);
    });
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) => addTime());
  }

  Widget buildTimeCard({required String time, required String header}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            time,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.83), fontSize: 72),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          header,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        )
      ],
    );
  }
}
