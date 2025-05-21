#include <WiFi.h> //Board Manager: ESP32 Dev Module
#include <WebServer.h>
#include <ArduinoJson.h> //Manage Libraries: ArduinoJson 6.x
#include <NTPClient.h> //Manage Libraries: NTPClient
#include <WiFiUdp.h>
#include <Wire.h>
#include <U8g2lib.h> //Manage Libraries: U8g2

// OLED 設定
U8G2_SH1106_128X64_NONAME_F_HW_I2C oled1(U8G2_R0, /* reset=*/ U8X8_PIN_NONE);
U8G2_SH1106_128X64_NONAME_F_HW_I2C oled2(U8G2_R0, /* reset=*/ U8X8_PIN_NONE);

// WiFi設定
const char* ssid = "guineapigisme";
const char* password = "hahahaha";
WebServer server(80);

// 硬體腳位設定
const byte anaPin = 34;     // 可變電阻引腳
const int buzzer = 25;      // 蜂鳴器
const int redLED = 12;      // 紅燈
const int buttonPin = 32;   // 關閉按鈕
const int dayPins[] = {18, 2, 4, 19, 5, 17, 16};  // 星期一到星期天對應的引腳

// 音樂相關設定
const int C = 956;      // C 音符頻率
const int halfBeat = 100;  // 半拍
const int fullBeat = 200;  // 一拍

// 狀態變數
short val;
short previousVal = -1;
bool buttonState = false;
bool redLedOn = false;
bool buttonPressed = false;
bool acknowledgedAlarm = false;
bool lastButtonState = false;
bool alarmActive = false;
bool melodyPlaying = false;
unsigned long buttonPressedTime = 0; //回傳TRY

unsigned long alarmStartTime = 0;
unsigned long lastToneToggle = 0;
unsigned long lastBeatTime = 0;
int currentBeat = 0;
bool toneState = false;

// 新增音量測試相關變數
bool isTestingVolume = false;
unsigned long lastVolumeTestTime = 0;
const unsigned long VOLUME_TEST_TIMEOUT = 1000; // 音量測試間隔


// NTP相關設置
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");
const long utcOffsetInSeconds = 28800; // UTC+8 (台灣時間)

// 鬧鐘結構體
struct Alarm {
  int id;
  int hour;
  int minute;
  int year;
  int month;
  int day;
  bool isEnabled;
  bool isRepeating;
};

// 動態鬧鐘陣列
std::vector<Alarm> alarms;

void setup() {
  Serial.begin(115200);
  Wire.begin();
  
  // 初始化OLED
  oled1.setI2CAddress(0x3C << 1);
  oled1.begin();
  oled2.setI2CAddress(0x3D << 1);
  oled2.begin();
  
  // 連接WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");
  Serial.println(WiFi.localIP());

  // 初始化NTP
  timeClient.begin();
  timeClient.setTimeOffset(utcOffsetInSeconds);
  
  // 設置API端點
  server.on("/api/alarms", HTTP_POST, handleAlarmUpdate);
  server.on("/api/time", HTTP_GET, handleGetTime);
  //回傳TRY：設定 Web API 路由-------------
  server.on("/alarm/ack", HTTP_GET, [](AsyncWebServerRequest *request){
    String response;
    if (buttonPressed) {
      response = "{\"status\": \"acknowledged\", \"timestamp\": " + String(buttonPressedTime) +
                ", \"alarmId\": " + String(lastTriggeredAlarmId) + "}";
    } else {
      response = "{\"status\": \"pending\"}";
    }
    request->send(200, "application/json", response);
  });

  //回傳TRY：設定 Web API 路由-------------
  server.begin();

  // 設定輸入輸出腳位
  pinMode(buzzer, OUTPUT);
  pinMode(anaPin, INPUT);
  pinMode(redLED, OUTPUT);
  pinMode(buttonPin, INPUT_PULLUP);
  
  // 初始化LED
  digitalWrite(redLED, LOW);
  for (int i = 0; i < 7; i++) {
    pinMode(dayPins[i], OUTPUT);
    digitalWrite(dayPins[i], LOW);
  }

  // 顯示歡迎畫面
  displayWelcome();
}

void loop() {
  timeClient.update();
  server.handleClient();
  
  weekdayLed();
  updateTimeDisplay();
  
  // 可變電阻音量控制
  val = analogRead(anaPin);
  int volume = map(val, 0, 4095, 0, 100);
  
  // 只在音量變動足夠大時進行處理
  if (abs(val - previousVal) > 5) {
    previousVal = val;
    displayVolume(volume);
    
    // 如果不在警報狀態下，觸發音量測試
    if (!alarmActive) {
      isTestingVolume = true;
      lastVolumeTestTime = millis();
      playTestTone(volume);
    }
  } else {
    // 如果音量測試已經持續一段時間，停止測試
    if (isTestingVolume && (millis() - lastVolumeTestTime > VOLUME_TEST_TIMEOUT)) {
      isTestingVolume = false;
      displayVoiceMed();
    }
  }
  
  if (!isTestingVolume && !alarmActive) {
    checkAlarms();
  }
  
  delay(100);
}

// 新增音量測試的音調播放函數
void playTestTone(int volume) {
  playTone(C, 100, volume); // 播放較短的音調用於測試
}

// 修改handleAlarmUpdate函數，添加防重複觸發邏輯
void handleAlarmUpdate() {
  if (server.hasArg("plain")) {
    String json = server.arg("plain");
    StaticJsonDocument<4096> doc;
    DeserializationError error = deserializeJson(doc, json);
    
    if (error) {
      server.send(400, "text/plain", "Invalid JSON");
      return;
    }

    // 建立暫時的新鬧鐘列表
    std::vector<Alarm> newAlarms;
    JsonArray alarmsArray = doc["alarms"].as<JsonArray>();
    
    for (JsonObject alarmObj : alarmsArray) {
      Alarm alarm;
      alarm.id = alarmObj["id"].as<int>();
      
      String timeStr = alarmObj["time"].as<String>();
      alarm.hour = timeStr.substring(0, 2).toInt();
      alarm.minute = timeStr.substring(3, 5).toInt();
      
      String dateStr = alarmObj["date"].as<String>();
      alarm.year = dateStr.substring(0, 4).toInt();
      alarm.month = dateStr.substring(5, 7).toInt();
      alarm.day = dateStr.substring(8, 10).toInt();
      
      // 直接從前端取得最新的啟用狀態
      alarm.isEnabled = alarmObj["isEnabled"].as<bool>();
      alarm.isRepeating = alarmObj["isRepeating"].as<bool>();
      
      // 檢查這個鬧鐘是否正在響鈴
      bool isCurrentlyActive = false;
      for (const auto& existingAlarm : alarms) {
        if (existingAlarm.id == alarm.id && alarmActive) {
          isCurrentlyActive = true;
          break;
        }
      }
      
      // 如果鬧鐘正在響鈴，保持啟用狀態為 false
      if (isCurrentlyActive) {
        alarm.isEnabled = false;
      }
      
      newAlarms.push_back(alarm);
    }
    
    // 更新全局鬧鐘列表
    alarms = newAlarms;
    
    printAlarms(); // 印出更新後的鬧鐘列表以供調試
    server.send(200, "text/plain", "Alarms updated successfully");
  } else {
    server.send(400, "text/plain", "No data received");
  }
}

void handleGetTime() {
  StaticJsonDocument<200> doc;
  doc["timestamp"] = timeClient.getEpochTime();
  doc["formatted"] = timeClient.getFormattedTime();
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// 修改警報檢查邏輯
void checkAlarms() {
  timeClient.update();
  unsigned long epochTime = timeClient.getEpochTime();
  time_t rawTime = (time_t)epochTime;
  struct tm *ptm = localtime(&rawTime);
  
  int currentYear = ptm->tm_year + 1900;
  int currentMonth = ptm->tm_mon + 1;
  int currentDay = ptm->tm_mday;
  int currentHour = timeClient.getHours();
  int currentMinute = timeClient.getMinutes();
  
  static int lastTriggeredAlarmId = -1;
  static unsigned long lastAlarmTriggerTime = 0;
  const unsigned long ALARM_TRIGGER_COOLDOWN = 60000; // 1分鐘冷卻時間
  
  for (auto& alarm : alarms) {
    if (alarm.isEnabled) {
      bool dateMatch = false;
      
      if (alarm.isRepeating) {
        dateMatch = true;
      } else {
        dateMatch = (currentYear == alarm.year && 
                    currentMonth == alarm.month && 
                    currentDay == alarm.day);
      }
      
      // 檢查是否是相同的鬧鐘在短時間內重複觸發
      bool isSameAlarm = (alarm.id == lastTriggeredAlarmId);
      bool isInCooldown = (millis() - lastAlarmTriggerTime < ALARM_TRIGGER_COOLDOWN);
      
      if (dateMatch && 
          currentHour == alarm.hour && 
          currentMinute == alarm.minute && 
          !(isSameAlarm && isInCooldown)) {
        
        lastTriggeredAlarmId = alarm.id;
        lastAlarmTriggerTime = millis();
        
        triggerAlarm(alarm);
        buttonPressed = false;  //回傳TRY
        buttonPressedTime = 0;  //回傳TRY
        
        if (!alarm.isRepeating) {
          alarm.isEnabled = false;
        }
        
        delay(1000);
      }
    }
  }

  // 檢查按鈕狀態
  if (alarmActive && digitalRead(buttonPin) == LOW && redLedOn) {
    alarmActive = false;
    digitalWrite(redLED, LOW);
    oled2.clearBuffer();
    oled2.setFont(u8g2_font_ncenB24_tr);
    oled2.drawStr(30, 45, "OK!");
    oled2.sendBuffer();
    delay(500);

    melodyPlaying = false;
    redLedOn = false;
    buttonPressed = true;
    acknowledgedAlarm = true;
    
    displayVoiceMed();
    delay(2000);
  }
}


void triggerAlarm(const Alarm& alarm) {
  alarmActive = true;
  digitalWrite(redLED, HIGH);
  redLedOn = true;
  
  // 根據時間顯示不同提醒
  if (alarm.hour >= 5 && alarm.hour < 11) {
    displayMealReminder("Breakfast");
  } else if (alarm.hour >= 11 && alarm.hour < 17) {
    displayMealReminder("Lunch");
  } else if (alarm.hour >= 17 && alarm.hour < 21) {
    displayMealReminder("Dinner");
  } else {
    displayMealReminder("Before Sleep");
  }

  // 播放提醒音樂，同時允許音量調整
  unsigned long startTime = millis();
  unsigned long duration = 5 * 60 * 1000;  // 5分鐘
  
  while (millis() - startTime < duration && digitalRead(buttonPin) == HIGH) {
    int currentVolume = map(analogRead(anaPin), 0, 4095, 0, 100);  // 即時讀取當前音量
    playAlarmMelody(currentVolume);
    updateTimeDisplay();  // 在播放音樂的同時更新時間顯示
  }
}


void playAlarmMelody(int volume) {
  for (int i = 0; i < 3 && digitalRead(buttonPin) == HIGH; i++) {
    playTone(C, halfBeat, volume);
    if (digitalRead(buttonPin) == HIGH) delay(halfBeat);
  }
  if (digitalRead(buttonPin) == HIGH) {
    playTone(C, fullBeat, volume);
    delay(halfBeat);
  }
  if (digitalRead(buttonPin) == HIGH) delay(500);
}


// 其他輔助函數
void displayWelcome() {
  oled2.clearBuffer();
  oled2.setFont(u8g2_font_ncenB14_tr);
  oled2.drawStr(20, 32, "WELCOME");
  oled2.sendBuffer();
  
  oled1.clearBuffer();
  oled1.setFont(u8g2_font_ncenB14_tr);
  oled1.drawStr(0, 32, "VoiceMed");
  oled1.sendBuffer();
  
  delay(2000);
}

void displayVolume(int volume) {
  oled2.clearBuffer();
  oled2.setFont(u8g2_font_ncenB10_tr);
  oled2.drawStr(0, 35, "Volume: ");
  oled2.setCursor(65, 35);
  oled2.print(volume);
  oled2.drawStr(90, 35, "%");
  oled2.sendBuffer();
}

void displayVoiceMed() {
  oled2.clearBuffer();
  oled2.setFont(u8g2_font_ncenB14_tr);
  oled2.drawStr(15, 42, "VoiceMed");
  oled2.sendBuffer();
}

void displayMealReminder(const char* meal) {
  oled2.clearBuffer();
  oled2.setFont(u8g2_font_ncenB14_tr);
  oled2.drawStr(40, 30, meal);
  
  String notyet = "Not yet!";
  int ntWidth = oled2.getStrWidth(notyet.c_str());
  oled2.setFont(u8g2_font_ncenB10_tr);
  oled2.drawStr(40, 52, notyet.c_str());
  oled2.sendBuffer();
}

void playTone(int frequency, int duration, int volume) {
  int halfPeriod = frequency / 2;
  long elapsedTime = 0;
  int onTime = (volume / 2 * halfPeriod) / 100;
  int offTime = halfPeriod - onTime;
  
  while (elapsedTime < duration * 1000 && digitalRead(buttonPin) == HIGH) {
    digitalWrite(buzzer, HIGH);
    delayMicroseconds(onTime);
    digitalWrite(buzzer, LOW);
    delayMicroseconds(offTime);
    elapsedTime += halfPeriod * 2;
  }
}

void weekdayLed() {
  int currentWeekday = timeClient.getDay();
  
  // 重置所有LED
  for (int i = 0; i < 7; i++) {
    digitalWrite(dayPins[i], LOW);
  }
  
  // 點亮當天LED
  if (currentWeekday > 0 && currentWeekday <= 6) {
    digitalWrite(dayPins[currentWeekday - 1], HIGH);
  } else {
    digitalWrite(dayPins[6], HIGH);
  }
}

void updateTimeDisplay() {
  timeClient.update();
  unsigned long epochTime = timeClient.getEpochTime();
  
  if (epochTime == 0) {
    timeClient.forceUpdate();
    epochTime = timeClient.getEpochTime();
  }
  
  time_t rawTime = (time_t)epochTime;
  struct tm *ptm = localtime(&rawTime);
  
  int currentYear = ptm->tm_year + 1900;
  int currentMonth = ptm->tm_mon + 1;
  int currentDay = ptm->tm_mday;
  int dayOfWeek = ptm->tm_wday;
  int currentHour = timeClient.getHours();
  int currentMinute = timeClient.getMinutes();
  
  String daysOfWeek[] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
  String weekDayStr = daysOfWeek[dayOfWeek];
  
  oled1.clearBuffer();
  
  // 時間顯示
  String timeStr = (currentHour < 10 ? "0" : "") + String(currentHour) + ":" + 
                  (currentMinute < 10 ? "0" : "") + String(currentMinute);
  oled1.setFont(u8g2_font_ncenB24_tr);
  int timeWidth = oled1.getStrWidth(timeStr.c_str());
  oled1.drawStr(128 - timeWidth, 25, timeStr.c_str());
  
  // 日期顯示
  String dateStr = String(currentYear) + "/" + 
                  (currentMonth < 10 ? "0" : "") + String(currentMonth) + "/" + 
                  (currentDay < 10 ? "0" : "") + String(currentDay);
  oled1.setFont(u8g2_font_ncenB08_tr);
  int dateWidth = oled1.getStrWidth(dateStr.c_str());
  oled1.drawStr(128 - dateWidth, 45, dateStr.c_str());
  
  // 星期顯示
  int weekDayWidth = oled1.getStrWidth(weekDayStr.c_str());
  oled1.drawStr(128 - weekDayWidth, 62, weekDayStr.c_str());
  
  oled1.sendBuffer();
}

void printAlarms() {
  Serial.println("Current alarms:");
  for (const auto& alarm : alarms) {
    Serial.print("Alarm ID: ");
    Serial.println(alarm.id);
    
    Serial.print("Date: ");
    Serial.print(alarm.year);
    Serial.print("/");
    if (alarm.month < 10) Serial.print("0");
    Serial.print(alarm.month);
    Serial.print("/");
    if (alarm.day < 10) Serial.print("0");
    Serial.println(alarm.day);
    
    Serial.print("Time: ");
    Serial.print(alarm.hour);
    Serial.print(":");
    if (alarm.minute < 10) Serial.print("0");
    Serial.println(alarm.minute);
    
    Serial.print("Enabled: ");
    Serial.println(alarm.isEnabled ? "Yes" : "No");
    Serial.print("Repeating: ");
    Serial.println(alarm.isRepeating ? "Yes" : "No");
    Serial.println();
  }
}