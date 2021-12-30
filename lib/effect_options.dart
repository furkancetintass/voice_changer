import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EffectOptions {
  final String title;
  final double pitch;
  final double speed;
  final IconData icon;

  EffectOptions(this.title, this.pitch, this.speed, this.icon);

  static List<EffectOptions> effectOptionsList = [
    EffectOptions('Kalın Erkek Sesi (Seviye 4)', 0.5, 0.8, CupertinoIcons.person_2_alt),
    EffectOptions('Kalın Erkek Sesi (Seviye 3)', 0.65, 0.85, CupertinoIcons.person_alt),
    EffectOptions('Kalın Erkek Sesi (Seviye 2)', 0.7, 0.9, CupertinoIcons.person_alt_circle),
    EffectOptions('Kalın Erkek Sesi (Seviye 1)', 0.8, 1, CupertinoIcons.person_alt_circle_fill),
    EffectOptions('Normal Ses', 1, 1, CupertinoIcons.person_circle),
    EffectOptions('İnce Ses (Seviye 1)', 1.2, 1, CupertinoIcons.person_crop_circle_fill),
    EffectOptions('İnce Ses (Seviye 2)', 1.4, 1, CupertinoIcons.person_fill),
    EffectOptions('İnce Ses (Seviye 3)', 1.6, 1, CupertinoIcons.person_circle_fill),
    EffectOptions('İnce Ses (Seviye 4)', 2.1, 1.4, CupertinoIcons.person_2_square_stack_fill),
  ];
}
