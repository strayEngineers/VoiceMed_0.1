import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  ///
  ///
  /// In zh, this message translates to:
  /// **'歡迎使用\n語音藥袋'**
  String get title;

  ///
  ///
  /// In zh, this message translates to:
  /// **'首頁'**
  String get home;

  ///
  ///
  /// In zh, this message translates to:
  /// **'藥袋掃描'**
  String get function1;

  ///
  ///
  /// In zh, this message translates to:
  /// **'藥物查詢'**
  String get function2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'服藥提醒'**
  String get function3;

  ///
  ///
  /// In zh, this message translates to:
  /// **'常見問題'**
  String get function4;

  ///
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settings;

  ///
  ///
  /// In zh, this message translates to:
  /// **'螢幕顯示'**
  String get theme;

  ///
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darktheme;

  ///
  ///
  /// In zh, this message translates to:
  /// **'語言切換'**
  String get language;

  ///
  ///
  /// In zh, this message translates to:
  /// **'切換語言'**
  String get changelan;

  ///
  ///
  /// In zh, this message translates to:
  /// **'字體大小'**
  String get fontsize;

  ///
  ///
  /// In zh, this message translates to:
  /// **'需要相機權限'**
  String get permissiontext1;

  ///
  ///
  /// In zh, this message translates to:
  /// **'請前往設置開啟相機權限'**
  String get permissiontext2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get permissiontext3;

  ///
  ///
  /// In zh, this message translates to:
  /// **'設置'**
  String get permissiontext4;

  ///
  ///
  /// In zh, this message translates to:
  /// **'需要檔案權限'**
  String get permissiontext5;

  ///
  ///
  /// In zh, this message translates to:
  /// **'請前往設置開啟檔案權限'**
  String get permissiontext6;

  ///
  ///
  /// In zh, this message translates to:
  /// **'請選擇掃描方式'**
  String get select;

  ///
  ///
  /// In zh, this message translates to:
  /// **'請將QRcode置中掃描框！'**
  String get scan3;

  ///
  ///
  /// In zh, this message translates to:
  /// **'掃描 QR Code'**
  String get scan4;

  ///
  ///
  /// In zh, this message translates to:
  /// **'掃描結果'**
  String get scanresult;

  ///
  ///
  /// In zh, this message translates to:
  /// **'未選擇照片'**
  String get getimage;

  ///
  ///
  /// In zh, this message translates to:
  /// **'未拍攝照片'**
  String get takephoto;

  ///
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get scanlanguage1;

  ///
  ///
  /// In zh, this message translates to:
  /// **'英文'**
  String get scanlanguage2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'台語'**
  String get scanlanguage3;

  ///
  ///
  /// In zh, this message translates to:
  /// **'上傳中...'**
  String get upload1;

  ///
  ///
  /// In zh, this message translates to:
  /// **'上傳失敗，請再試一次。'**
  String get upload2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'服藥提醒'**
  String get alarmreminder;

  ///
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get alarm;

  ///
  ///
  /// In zh, this message translates to:
  /// **'標題'**
  String get title2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'重複'**
  String get repeat;

  ///
  ///
  /// In zh, this message translates to:
  /// **'請輸入提醒標題'**
  String get enteralarmtitle;

  ///
  ///
  /// In zh, this message translates to:
  /// **'提醒標題'**
  String get alarmtitle;

  ///
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  ///
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  ///
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get save;

  ///
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get everyday;

  ///
  ///
  /// In zh, this message translates to:
  /// **'新增提醒'**
  String get addalarm;

  ///
  ///
  /// In zh, this message translates to:
  /// **'服藥提醒'**
  String get reminder;

  ///
  ///
  /// In zh, this message translates to:
  /// **'服藥時段辨識為空，無法預設提醒'**
  String get checkboxmsg;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q1 藥物可以與牛奶或果汁併服嗎？'**
  String get q1;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A1 許多藥物和牛奶或葡萄柚汁可能產生交互作用：\n\n1. 四環黴素與諾酮類抗生素應避免併服牛奶鈣片（乳製品及含有鈣、鎂等礦物質飲料或綜合維他命），因容易受到飲食中的鈣、鎂、鐵、鋁等陽離子螯合而影響其吸收及療效，故建議空腹或至少錯開兩小時服用。\n2. 葡萄柚汁在小腸中可能抑制藥物的代謝進而誘發毒性；受影響的藥物如安眠鎮靜劑、鈣離子通道阻斷劑等。\n\n若您正在服用的藥物無法確定是否有交互作用或是服藥的同時無法避免時，建議先諮詢醫師或藥師。此外，服用藥物時最好搭配足量白開水，避免使用其他飲料，以確保用藥安全。'**
  String get a1;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q2 服藥時應注意哪些事項？'**
  String get q2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A2\n\n1. 確實依照醫師指示服藥，切勿擅自增減藥量或停藥，並請按時回診。\n2. 請保留藥袋至藥品用完。\n3. 避免孩童接觸藥品，切勿將藥品交給他人使用。\n4. 一般藥品請存放陰涼處，如發現變質或過期，請勿使用。\n5. 請按時服藥，中西藥需間隔2小時。\n6. 若錯過服藥時間應盡快補服，若時間已接近下一次服藥時間，就不必補服，千萬不可一次服用兩倍劑量。\n7. 如有用藥疑問，請詢問藥師。'**
  String get a2;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q3 我正在吃中藥，還可以吃西藥嗎？'**
  String get q3;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A3 中藥和西藥一起服用有時候會引起一些不良的作用，最好詢問藥師確認沒問題後再服用，中藥和西藥相隔兩小時後再服用為宜。'**
  String get a3;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q4 吃藥時可以搭配果汁或是茶一起喝嗎？或是吃完藥後吃梅子餅有關係嗎？'**
  String get q4;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A4 服藥時應以「白開水」配服，將藥物搭配果汁、茶或梅子餅可能會改變某些藥物的酸鹼反應或相剋而影響療效甚至中毒，當然，並不是每種藥都會產生這種現象，所以若有特殊需要可先請教藥師。'**
  String get a4;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q5 不用或過期藥物如何處理？'**
  String get q5;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A5 化療藥品及管制藥品，建議請專業藥事人員協助處理。\n\n1. 除化療及管制藥品外，固體廢棄藥品，如錠狀、膠囊藥品，請將藥品與外包裝分開，外包裝需回收。藥品倒入可封口的塑膠袋，置於家中垃圾桶，隨垃圾車丟棄 (目前國內焚化爐多是經高溫燃燒後均可將藥品完全處理並減少二次環境汙染)。\n2. 液體廢棄藥品，如糖漿、藥水，將液體倒入塑膠袋(袋內放入一些可吸附藥水物品吸收液體) 隨垃圾車丟棄，空瓶交由垃圾車回收。\n3. 沒吃完的剩餘藥品，絕對不可隨意丟棄或倒入水槽或馬桶沖走，減少環境污染。'**
  String get a5;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q6 所有的藥都可以放在冰箱保存嗎？'**
  String get q6;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A6 有的藥放冰箱反而容易影響其藥效甚至變質，所以藥品要依說明書指示保存。'**
  String get a6;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q7 服藥後容易打瞌睡怎麼辦？'**
  String get q7;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A7 有些藥物會引起睡意甚至降低注意力和協調應變能力，所以若有操作機械、開車或考試，在看病時一定要告訴醫師和藥師，以免發生危險。'**
  String get a7;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q8 若用藥後發生過敏現象怎麼辦？'**
  String get q8;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A8 藥物過敏輕為皮膚癢、起紅疹，重則會影響呼吸甚至死亡。有過敏現象產生時，應該打電話或回門診告知醫師或藥師過敏的訊息，並依醫囑停藥或換藥，以避免再次使用會過敏的藥。'**
  String get a8;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q9 感冒藥沒吃完是不是可以留到下次再用？'**
  String get q9;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A9 因為每次感冒的病毒都有可能不同，所以感冒藥沒吃完建議丟掉，千萬不要下次再用。'**
  String get a9;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q10 兩次或兩餐的用藥一次吃完是不是效果比較好？'**
  String get q10;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A10 兩次的用藥一次吃完會藥物過量，副作用會增加，所以請務必遵守用法用量的規定，不要擅自改變服藥次數或增添藥量。'**
  String get a10;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q11 存放藥品須注意哪些事項？'**
  String get q11;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A11\n\n1. 醫院看病帶回的藥品，請放置在家中較陰涼的地方，例如桌子的抽屜或壁櫃。如果空間足夠，外用藥最好與內服藥分開存放，需要冷藏的藥品應放在冰箱。\n2. 家裏的常備藥或從社區藥局買回的指示藥與成藥，如果是散裝藥品，放在不透明的玻璃瓶內最理想。不同的藥品不要使用同一個容器，以免相互污染或吃錯藥。\n3. 藥品全部吃完以前不要除去效期與用法的標示。放置較久的藥品，每次取用時應再讀一次效期，接近效期時可以用色筆把日期特別標示出來，超過效期藥品須以正確步驟回收，勿倒水槽或馬桶。\n4. 存放藥品的地方應該避免兒童取得，以免把五顏六色的藥品當做糖果吞服。'**
  String get a11;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q12 兩種藥水或藥水和藥粉如果要帶出門，是不是可以混合在一個瓶子一起服用？'**
  String get q12;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A12 兩種藥物混合，可能會產生化學反應，變成有毒物質，故不可以兩種藥水混合在一個瓶子一起服用。'**
  String get a12;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q13 可否持本院開立的處方箋至健保特約藥局領藥？'**
  String get q13;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A13 持處方箋至批價櫃台結帳繳費並蓋章後，可至本院藥局或健保特約藥局領藥。'**
  String get a13;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q14 遺失「慢性病連續處方箋」該如何領藥？'**
  String get q14;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A14 請病友重新掛號看診，由醫師開立新的處方箋，計價後即可依領藥號拿藥。'**
  String get a14;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q15 每個西藥房都可以依處方籤領取藥品嗎？'**
  String get q15;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A15 不是！需有健保特約藥局才能依處方籤領取藥品。'**
  String get a15;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q16 服用藥物會產生皮膚癢或眼瞼、嘴唇水腫，是怎麼了？'**
  String get q16;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A16 這樣的現象可能是藥物過敏，須拿到醫院或藥局確認過敏的藥物來源，並請醫師提供正確藥物名稱，未來如有就醫時須告知醫師避開這些藥物，以免再次造成過敏反應。'**
  String get a16;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q17 肚子痛是不是吃「臭藥丸」就有效？'**
  String get q17;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A17 肚子痛的病因有很多種，一定要診斷清楚才能用藥，以免延誤治療的最佳時機。'**
  String get a17;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q18 小孩子的症狀不嚴重，是否可以先將大人的藥物減量後讓小孩子服用？'**
  String get q18;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A18 我們不是醫師，無法判定什麼病應該吃什麼藥，況且藥物使用不恰當可能危及生命，所以切勿自己當醫師將藥物分享或根據經驗任意給藥。'**
  String get a18;

  ///
  ///
  /// In zh, this message translates to:
  /// **'Q19 授乳期間服藥應注意那些事項？'**
  String get q19;

  ///
  ///
  /// In zh, this message translates to:
  /// **'A19\n\n1. 每次看診請告知醫師正在授乳，以選用較安全的藥品。\n2. 如果必須服用的藥品會經過乳汁分泌影響嬰兒，建議在服藥期間及停藥後一段時間暫停授乳。\n3. 於服藥前，可先將乳汁吸出，封存於雙層袋中冷凍儲存，以便有足夠量於停止授乳時供嬰兒食用。\n4. 可於剛授完乳後或嬰兒需要睡較長的時間前服藥。'**
  String get a19;

  ///
  ///
  /// In zh, this message translates to:
  /// **'對不起，無法提供該問題的答案。'**
  String get noAnswer;

  ///
  ///
  /// In zh, this message translates to:
  /// **'您好，需要什麼協助嗎？'**
  String get greeting;

  ///
  ///
  /// In zh, this message translates to:
  /// **'確定要離開VoiceMed嗎？'**
  String get leaveapp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
