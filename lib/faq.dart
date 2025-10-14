// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'font_size.dart';

class FAQPage extends StatefulWidget {
  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // 用來儲存訊息列表
  List<Map<String, String>> _messages = [];

  // 問答資料集 (字典結構)
  late Map<String, String> _faqData;

  // 生成 _faqQuestions 列表，從 _faqData 的 keys 中提取所有問題
  late List<String> _faqQuestions;

  bool _isDataInitialized = false; // 用來判斷_faqQuestions是否已初始化

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataInitialized) {
      _faqData = {
        AppLocalizations.of(context)!.q1: AppLocalizations.of(context)!.a1,
        AppLocalizations.of(context)!.q2: AppLocalizations.of(context)!.a2,
        AppLocalizations.of(context)!.q3: AppLocalizations.of(context)!.a3,
        AppLocalizations.of(context)!.q4: AppLocalizations.of(context)!.a4,
        AppLocalizations.of(context)!.q5: AppLocalizations.of(context)!.a5,
        AppLocalizations.of(context)!.q6: AppLocalizations.of(context)!.a6,
        AppLocalizations.of(context)!.q7: AppLocalizations.of(context)!.a7,
        AppLocalizations.of(context)!.q8: AppLocalizations.of(context)!.a8,
        AppLocalizations.of(context)!.q9: AppLocalizations.of(context)!.a9,
        AppLocalizations.of(context)!.q10: AppLocalizations.of(context)!.a10,
        AppLocalizations.of(context)!.q11: AppLocalizations.of(context)!.a11,
        AppLocalizations.of(context)!.q12: AppLocalizations.of(context)!.a12,
        AppLocalizations.of(context)!.q13: AppLocalizations.of(context)!.a13,
        AppLocalizations.of(context)!.q14: AppLocalizations.of(context)!.a14,
        AppLocalizations.of(context)!.q15: AppLocalizations.of(context)!.a15,
        AppLocalizations.of(context)!.q16: AppLocalizations.of(context)!.a16,
        AppLocalizations.of(context)!.q17: AppLocalizations.of(context)!.a17,
        AppLocalizations.of(context)!.q18: AppLocalizations.of(context)!.a18,
        AppLocalizations.of(context)!.q19: AppLocalizations.of(context)!.a19,
      };
      _faqQuestions = _faqData.keys.toList();
      _isDataInitialized = true;
      setState(() {}); // 資料初始化完成，更新 UI
    }
  }

  // 新增訊息到訊息列表
  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({"role": role, "text": text});
    });
  }

  // 處理 FAQ 按鈕點擊事件
  void _handleFAQClick(String question) {
    _addMessage("user", question);
    Future.delayed(Duration(milliseconds: 500), () {
      String? answer = _faqData[question];
      _addMessage("bot", answer ?? AppLocalizations.of(context)!.noAnswer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final double fontSize = fontSizeProvider.fontSize;
    final double buttonWidth = 200.0 + (fontSize - 16.0) * 10.0; // 根據字大小調整按鈕寬度
    final double buttonHeight = 70.0 + (fontSize - 16.0) * 3.0; // 根據字大小調整按鈕高度

    var appBar = AppBar(
      title: Text(
        AppLocalizations.of(context)!.function4,
        style: TextStyle(
            fontSize: fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Color(0xFF439775),
      iconTheme:
          IconThemeData(color: Color(0xFFEFF7CF), size: 30 * fontSize / 20),
      leading: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, "/");
        },
        child: Icon(
          Icons.arrow_back,
        ),
      ),
    );

    if (!_isDataInitialized) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: SizedBox(
            width: 40 * fontSizeProvider.fontSize / 20,
            height: 40 * fontSizeProvider.fontSize / 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF439775)),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, "/");
        return false;
      },
      child: Scaffold(
        appBar: appBar,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.0, left: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xff439775),
                      child: Icon(
                        Icons.android,
                        size: 25 * fontSize / 20,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      AppLocalizations.of(context)!.greeting,
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        // color: Color(0xff2A4747),
                      ),
                    ),
                  ],
                ),
              ),
              // FAQ 按鈕區域，橫向滑動
              Container(
                padding: EdgeInsets.all(5.0),
                height: buttonHeight * 3 + 57,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (_faqQuestions.length / 3).ceil(),
                  itemBuilder: (context, index) {
                    int startIndex = index * 3;
                    int endIndex = (index + 1) * 3;
                    if (endIndex > _faqQuestions.length) {
                      endIndex = _faqQuestions.length;
                    }
                    List<String> sublist =
                        _faqQuestions.sublist(startIndex, endIndex);

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.0),
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sublist.map((question) {
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5.0),
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: () => _handleFAQClick(question),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 13.0,
                                    horizontal: 15.0,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    question,
                                    style: TextStyle(fontSize: fontSize),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              // 聊天訊息區
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message["role"] == "user";
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                backgroundColor: Color(0xff439775),
                                child: Icon(
                                  Icons.android,
                                  size: 25 * fontSize / 20,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.0),
                            ],
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 250),
                              child: Container(
                                padding: EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.background
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  message["text"]!,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: isUser
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              SizedBox(width: 8.0),
                              CircleAvatar(
                                backgroundColor: Color(0xff439775),
                                child: Icon(
                                  Icons.person,
                                  size: 25 * fontSizeProvider.fontSize / 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
