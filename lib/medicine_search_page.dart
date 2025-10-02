// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, use_super_parameters, library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_declarations, avoid_print

import 'dart:convert';
import 'dart:io';
import "package:audioplayers/audioplayers.dart";
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' hide Text;
import 'font_size.dart';
import "util.dart";

class MedicineSearchPage extends StatefulWidget {
  @override
  _MedicineSearchPageState createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: "QR");
  late QRViewController qrController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    qrController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        _handleQRCode(scanData.code!);
      }
    });
  }

  void _handleQRCode(String code) async {
    qrController.pauseCamera();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineSearchResultPage(scannedText: code),
      ),
    );
    qrController.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final height25Percent = screenHeight * 0.25;
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    var appBar = AppBar(
      title: Text(
        AppLocalizations.of(context)!.scan4,
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
        onTap: () {
          Navigator.pushNamed(context, "/");
        },
        child: Icon(Icons.arrow_back),
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, "/");
        return false;
      },
      child: Scaffold(
        appBar: appBar,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: screenHeight - height25Percent,
                child: ClipRRect(
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Color(0xFF65B891),
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: height25Percent,
              color: Color(0xFFEFF7CF),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.scan3,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: fontSizeProvider.fontSize + 4,
                        color: Color(0xFF2A4747),
                        fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 20.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicineSearchResultPage extends StatefulWidget {
  final String scannedText;

  const MedicineSearchResultPage({Key? key, required this.scannedText})
      : super(key: key);

  @override
  _MedicineSearchResultPageState createState() =>
      _MedicineSearchResultPageState();
}

class _MedicineSearchResultPageState extends State<MedicineSearchResultPage>
    with WidgetsBindingObserver {
  List<String> extractedData = [];

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
  String englishText = '';
  String chineseText = '';

  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAndParseWebContent();
    WidgetsBinding.instance.addObserver(this);

    _setupAudioPlayer(chineseAudioPlayer, 'zh-TW');
    _setupAudioPlayer(englishAudioPlayer, 'en');
  }

  Future<void> _fetchAndParseWebContent() async {
    try {
      final response = await http.get(Uri.parse(widget.scannedText));

      if (response.statusCode == 200) {
        Document document = html_parser.parse(response.body);
        final rows = document
            .getElementsByTagName('tbody')[3]
            .getElementsByTagName('tr');

        List<String> extractedData = [];

        for (int i = 0; i < rows.length; i++) {
          if (i == 1 || i == 2 || i == 3 || i == 6) {
            continue;
          }

          final headerCells =
              rows[i].getElementsByClassName("tableHeaderTd_Left");
          final dataCells = rows[i].getElementsByClassName("tableTd_Left");

          for (int j = 0; j < headerCells.length; j++) {
            if (j < dataCells.length) {
              String headerText = headerCells[j]
                  .innerHtml
                  .trim()
                  .replaceAll(RegExp(r'<br>\s*'), ' ');
              String dataText = dataCells[j].text.trim();

              extractedData.add('$headerText：$dataText');
            }
          }
        }

        setState(() {
          this.extractedData = extractedData;
        });

        chineseText = extractedData.join('\n');
        displayedText = chineseText;

        await _sendTextToAPI(chineseText);
      } else {
        setState(() {
          extractedData = [
            "Failed to load the web page. Status code: ${response.statusCode}"
          ];
        });
      }
    } catch (e) {
      setState(() {
        extractedData = ["Error occurred while fetching data: $e"];
      });
    }
  }

  Future<void> _sendTextToAPI(String text) async {
    final String apiUrl = "http://192.168.17.253:8080/";
    final fontSizeProvider = context.read<FontSizeProvider>();

    final Map<String, dynamic> data = {
      'text': text,
    };

    try {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 40 * fontSizeProvider.fontSize / 20,
                    height: 40 * fontSizeProvider.fontSize / 20,
                    child: CircularProgressIndicator()),
                SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.upload1,
                  style: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        isUploading = true;
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      Navigator.of(context).pop();
      setState(() {
        isUploading = false;
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('成功: ${responseData['text']}');

        await _downloadFile(
            responseData['audio_files']['zh'], 'output_zh-TW.mp3');
        await _downloadFile(responseData['audio_files']['en'], 'output_en.mp3');

        englishText = responseData['translated_text'];
      } else {
        final errorData = json.decode(response.body);
        print('錯誤: ${errorData['error']}');
        showSnackBar(context, AppLocalizations.of(context)!.upload2);
      }
    } catch (e) {
      Navigator.pushNamed(context, "/medicineSearch");
      setState(() {
        isUploading = false;
      });
      print('發送請求時出現錯誤: $e');
      showSnackBar(context, AppLocalizations.of(context)!.upload2);
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        print('檔案已下載並儲存於: $filePath');

        if (fileName.contains('zh')) {
          audioFilePathZh = filePath;
        } else if (fileName.contains('en')) {
          audioFilePathEn = filePath;
        }
      } else {
        print('下載檔案失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('下載過程中發生錯誤: $e');
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
        print(chineseText);
        displayedText = chineseText;
      } else {
        isSliderEnabledEnglish = isPlayingEnglish;
        print(englishText);
        displayedText = englishText;
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

          Navigator.pushNamed(context, "/medicineSearch");
        },
        child: Icon(Icons.arrow_back),
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        await chineseAudioPlayer.stop();
        await englishAudioPlayer.stop();

        Navigator.pushNamed(context, "/medicineSearch");
        return false;
      },
      child: Scaffold(
        appBar: appBar,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              if (!isUploading)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      displayedText,
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize,
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
