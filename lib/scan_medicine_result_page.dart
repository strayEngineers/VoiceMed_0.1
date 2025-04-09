// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, sort_child_properties_last, sized_box_for_whitespace, unnecessary_overrides

import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "font_size.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "util.dart";

class ScanMedicineResultPage extends StatefulWidget {
  final String chineseText;
  final String englishText;
  final bool hasCheckbox;

  const ScanMedicineResultPage({
    Key? key,
    required this.chineseText,
    required this.englishText,
    required this.hasCheckbox,
  }) : super(key: key);

  @override
  _ScanMedicineResultPageState createState() => _ScanMedicineResultPageState();
}

class _ScanMedicineResultPageState extends State<ScanMedicineResultPage>
    with WidgetsBindingObserver {
  AudioPlayer chineseAudioPlayer = AudioPlayer();
  AudioPlayer englishAudioPlayer = AudioPlayer();

  bool isPlayingChinese = false;
  bool isPlayingEnglish = false;

  Duration currentChinesePosition = Duration.zero;
  Duration currentEnglishPosition = Duration.zero;

  Duration chineseTotalDuration = Duration.zero;
  Duration englishTotalDuration = Duration.zero;

  bool isSliderEnabledChinese = false;
  bool isSliderEnabledEnglish = false;

  bool isChineseSliderVisible = false;
  bool isEnglishSliderVisible = false;

  String? audioFilePathZh =
      '/data/user/0/com.example.VoiceMed/app_flutter/output_zh-TW.mp3';
  String? audioFilePathEn =
      '/data/user/0/com.example.VoiceMed/app_flutter/output_en.mp3';

  String displayedText = '';

  bool _hasShownSnackBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _setupAudioPlayer(chineseAudioPlayer, 'zh-TW');
    _setupAudioPlayer(englishAudioPlayer, 'en');

    displayedText = widget.chineseText;

    if (!widget.hasCheckbox && !_hasShownSnackBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackBar(context, AppLocalizations.of(context)!.checkboxmsg);
        setState(() {
          _hasShownSnackBar = true;
        });
      });
    }
  }

  void _setupAudioPlayer(AudioPlayer player, String language) {
    player.onDurationChanged.listen((duration) {
      setState(() {
        if (language == 'zh-TW') {
          chineseTotalDuration = duration;
        } else {
          englishTotalDuration = duration;
        }
      });
    });

    player.onPositionChanged.listen((position) {
      setState(() {
        if (language == 'zh-TW') {
          currentChinesePosition = position;
        } else {
          currentEnglishPosition = position;
        }
      });
    });

    player.onPlayerComplete.listen((event) {
      setState(() {
        if (language == 'zh-TW') {
          isPlayingChinese = false;
          currentChinesePosition = Duration.zero;
          isSliderEnabledChinese = false;
          englishAudioPlayer.pause();
        } else {
          isPlayingEnglish = false;
          currentEnglishPosition = Duration.zero;
          isSliderEnabledEnglish = false;
          chineseAudioPlayer.pause();
        }
      });
    });
  }

  Future<void> _playAudio(String audioFilePath, String language) async {
    AudioPlayer currentPlayer =
        language == 'zh-TW' ? chineseAudioPlayer : englishAudioPlayer;

    if (isPlayingChinese || isPlayingEnglish) {
      await chineseAudioPlayer.pause();
      await englishAudioPlayer.pause();
    }

    setState(() {
      isPlayingChinese = language == 'zh-TW' ? !isPlayingChinese : false;
      isPlayingEnglish = language == 'en' ? !isPlayingEnglish : false;

      isChineseSliderVisible = language == 'zh-TW' ? isPlayingChinese : false;
      isEnglishSliderVisible = language == 'en' ? isPlayingEnglish : false;

      if (language == 'zh-TW') {
        isSliderEnabledChinese = isPlayingChinese;
        displayedText = widget.chineseText;
      } else {
        isSliderEnabledEnglish = isPlayingEnglish;
        displayedText = widget.englishText;
      }
    });

    if ((language == 'zh-TW' && isPlayingChinese) ||
        (language == 'en' && isPlayingEnglish)) {
      Duration startPosition =
          language == 'zh-TW' ? currentChinesePosition : currentEnglishPosition;
      await _playSpecificAudio(currentPlayer, audioFilePath, startPosition);
    }
  }

  Future<void> _playSpecificAudio(
      AudioPlayer player, String audioFilePath, Duration position) async {
    if (position > Duration.zero) {
      await player.seek(position);
      await player.resume();
    } else {
      await player.play(DeviceFileSource(audioFilePath));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      if (isPlayingChinese) {
        setState(() {
          chineseAudioPlayer.pause();
          isPlayingChinese = false;
        });
      }

      if (isPlayingEnglish) {
        setState(() {
          englishAudioPlayer.pause();
          isPlayingEnglish = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    var appBar = AppBar(
      title: Text(
        AppLocalizations.of(context)!.scanresult,
        style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Color(0xFF439775),
      iconTheme: IconThemeData(
          color: Color(0xFFEFF7CF), size: 30 * fontSizeProvider.fontSize / 20),
      leading: GestureDetector(
        onTap: () async {
          await chineseAudioPlayer.stop();
          await englishAudioPlayer.stop();

          Navigator.pushNamed(context, "/");
        },
        child: Icon(Icons.arrow_back),
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        await chineseAudioPlayer.stop();
        await englishAudioPlayer.stop();

        Navigator.pushNamed(context, "/");
        return false;
      },
      child: Scaffold(
        appBar: appBar,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    displayedText,
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            _buildAudioControls(),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        if (isChineseSliderVisible)
          _buildSlider(
            chineseAudioPlayer,
            currentChinesePosition,
            chineseTotalDuration,
            isSliderEnabledChinese,
          ),
        if (isEnglishSliderVisible)
          _buildSlider(
            englishAudioPlayer,
            currentEnglishPosition,
            englishTotalDuration,
            isSliderEnabledEnglish,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLanguageButton('中文', isPlayingChinese,
                () => _playAudio(audioFilePathZh!, 'zh-TW')),
            SizedBox(width: 16),
            _buildLanguageButton('English', isPlayingEnglish,
                () => _playAudio(audioFilePathEn!, 'en')),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider(AudioPlayer player, Duration currentPosition,
      Duration totalDuration, bool isSliderEnabled) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Column(
      children: [
        SliderTheme(
          data: Theme.of(context).sliderTheme.copyWith(
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 10 * fontSizeProvider.fontSize / 20,
                ),
                trackHeight: 6 * fontSizeProvider.fontSize / 20,
              ),
          child: Slider(
            value: currentPosition.inSeconds.toDouble(),
            min: 0,
            max: totalDuration.inSeconds.toDouble(),
            onChanged: isSliderEnabled
                ? (double value) {
                    setState(() {
                      if (player == chineseAudioPlayer) {
                        currentChinesePosition =
                            Duration(seconds: value.toInt());
                      } else {
                        currentEnglishPosition =
                            Duration(seconds: value.toInt());
                      }
                    });
                  }
                : null,
            onChangeEnd: (double value) {
              if (player == chineseAudioPlayer) {
                chineseAudioPlayer.seek(Duration(seconds: value.toInt()));
              } else {
                englishAudioPlayer.seek(Duration(seconds: value.toInt()));
              }
            },
          ),
        ),
        Text(
          '${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}',
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: fontSizeProvider.fontSize - 4),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(
      String language, bool isPlaying, VoidCallback onPlayPause) {
    final fontSizeProvider = context.read<FontSizeProvider>();

    return ElevatedButton(
      onPressed: onPlayPause,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 25 * fontSizeProvider.fontSize / 20,
          ),
          SizedBox(width: 5),
          Text(language,
              style: TextStyle(fontSize: fontSizeProvider.fontSize - 2)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    chineseAudioPlayer.dispose();
    englishAudioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
