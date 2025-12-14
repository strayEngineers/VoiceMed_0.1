#include <WiFi.h>
#include <Preferences.h>
#include <U8g2lib.h>
#include <NimBLEDevice.h> // 輕量級 BLE 庫
#include <NTPClient.h>      // 鬧鐘時間同步
#include <WiFiUdp.h>
#include <WebServer.h>      // 連線後接收鬧鐘資料
#include <ArduinoJson.h>    // 解析鬧鐘資料
#include <Wire.h>
#include <vector>           // 鬧鐘動態陣列

// =======================================================
// 狀態與配置定義
// =======================================================

// 系統狀態
enum SystemState { 
    BLE_CONFIG,         // 藍牙配置模式
    WIFI_CONNECTING,    // 正在嘗試連線 Wi-Fi
    WIFI_CONNECTED      // Wi-Fi 連線成功，運行模式
};
SystemState currentState = BLE_CONFIG; 

// NVS 儲存設定
Preferences preferences;
const char* NVS_NAMESPACE = "config";
const char* NVS_SSID_KEY = "ssid";
const char* NVS_PWD_KEY = "password";
const char* NVS_BTNAME_KEY = "btname";

// BLE GATT 服務定義 (UUIDs)
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_WIFI_UUID         "beb5483e-36e1-4688-b7f5-ea07361b26a8" 
#define CHAR_BTNAME_UUID       "b3b3a001-3e00-4740-98d0-25032906e000" 
#define CHAR_STATUS_UUID       "c5c5c001-4e00-4740-98d0-25032906e001"  // 新增：狀態回報特徵

// NTP 相關設定
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");
const long utcOffsetInSeconds = 28800; // UTC+8 (台灣時間)

// Web Server
WebServer server(80);

// 硬體腳位設定
const byte anaPin = 34;     // 可變電阻引腳
const int buzzer = 25;      // 蜂鳴器
const int redLED = 12;      // 紅燈
const int buttonPin = 32;   // 關閉按鈕

// 軟體 I2C 腳位 (OLED2)
#define SDA_2 26
#define SCL_2 27

// 音樂相關設定
const int C = 956;          // C 音符頻率
const int halfBeat = 100;   // 半拍
const int fullBeat = 200;   // 一拍

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
std::vector<Alarm> alarms;

// 狀態變數
short val;
short previousVal = -1;
bool redLedOn = false;
bool alarmActive = false;
bool isTestingVolume = false;
unsigned long lastVolumeTestTime = 0;
const unsigned long VOLUME_TEST_TIMEOUT = 1000; 
const unsigned long ALARM_TRIGGER_COOLDOWN = 60000; 

// 藍牙連線狀態旗標 (全域變數)
bool bleConnected = false; 

// =======================================================
// OLED 設定 (雙 I2C / 分頁模式 _1)
// =======================================================
U8G2_SH1106_128X64_NONAME_1_HW_I2C oled1(U8G2_R0, U8X8_PIN_NONE); 
U8G2_SH1106_128X64_NONAME_1_SW_I2C oled2(U8G2_R0, /* clock=*/ SCL_2, /* data=*/ SDA_2, /* reset=*/ U8X8_PIN_NONE); 

String currentSSID = "";
String currentPassword = "";

NimBLEServer* pServer = nullptr;
NimBLEAdvertising* pAdvertising = nullptr;
NimBLECharacteristic* pStatusChar = nullptr;  // 狀態特徵指標

// =======================================================
// 函數前置宣告
// =======================================================
bool loadConfig();
void saveWiFiConfig(const String& ssid, const String& password);
void updateSystemState(SystemState newState);
void startBLEServer();
void handleAlarmUpdate();
void handleGetTime();
void initOLED();
void setDisplayStatus(const String& line1, const String& line2);
void displayVolume(int volume); 
void displayVoiceMed(); 
void updateTimeDisplay();
void displayMealReminder(const char* meal); 
void displayWelcome();
void checkAlarms(); 
void triggerAlarm(Alarm& alarm);
void playAlarmMelody(int volume); 
void playTestTone(int volume); 
void playTone(int frequency, int duration, int volume);


// =======================================================
// BLE Callbacks 
// =======================================================

// Server 連線/斷線 Callback
class ServerCallbacks : public NimBLEServerCallbacks {
public:
    void onConnect(NimBLEServer* pServer) {
        Serial.println("\n========================================");
        Serial.println("📱 [ServerCallback] 客戶端已連線！");
        Serial.println("========================================\n");
        bleConnected = true;
    }

    void onDisconnect(NimBLEServer* pServer) {
        Serial.println("\n========================================");
        Serial.println("📱 [ServerCallback] 客戶端已斷線");
        Serial.println("========================================\n");
        bleConnected = false;
    }
};

// 特徵讀寫 Callback
class CharacteristicCallbacks : public NimBLECharacteristicCallbacks {
public:
    void onWrite(NimBLECharacteristic* pCharacteristic) {
        Serial.println("\n========================================");
        Serial.println("📩 [CharCallback] 收到寫入請求！");
        
        std::string value = pCharacteristic->getValue();
        String receivedData = String(value.c_str());
        
        Serial.print("  長度: ");
        Serial.println(receivedData.length());
        Serial.print("  內容: ");
        Serial.println(receivedData);
        
        if (receivedData.length() == 0) {
            Serial.println("  ⚠️ 空資料，忽略");
            Serial.println("========================================\n");
            return;
        }

        String charUUID = String(pCharacteristic->getUUID().toString().c_str());
        Serial.print("  UUID: ");
        Serial.println(charUUID);
        
        // WiFi 設定 (UUID: beb5483e-36e1-4688-b7f5-ea07361b26a8)
        if (charUUID.indexOf("beb5483e") >= 0) {
            Serial.println("  📡 類型: WiFi 設定");
            
            int commaPos = receivedData.indexOf(',');
            if (commaPos > 0) {
                String newSSID = receivedData.substring(0, commaPos);
                String newPWD = receivedData.substring(commaPos + 1);
                
                Serial.print("  📶 SSID: ");
                Serial.println(newSSID);
                Serial.print("  🔐 密碼長度: ");
                Serial.println(newPWD.length());
                
                saveWiFiConfig(newSSID, newPWD);
                
                Serial.println("  ✅ 儲存完成，準備連線 WiFi");
                Serial.println("========================================\n");
                
                delay(500);
                updateSystemState(WIFI_CONNECTING);
            } else {
                Serial.println("  ❌ 格式錯誤（應為: SSID,Password）");
                Serial.println("========================================\n");
            }
        }
        // 藍牙名稱設定 (UUID: b3b3a001-3e00-4740-98d0-25032906e000)
        else if (charUUID.indexOf("b3b3a001") >= 0) {
            Serial.println("  📡 類型: 藍牙名稱設定");
            
            preferences.begin(NVS_NAMESPACE, false);
            preferences.putString(NVS_BTNAME_KEY, receivedData);
            preferences.end();
            
            Serial.println("  ✅ 藍牙名稱已儲存");
            Serial.println("========================================\n");
        }
        else {
            Serial.println("  ⚠️ 未知的 UUID");
            Serial.println("========================================\n");
        }
    }

    void onRead(NimBLECharacteristic* pCharacteristic) {
        Serial.println("📖 [CharCallback] 收到讀取請求");
    }
};

// =======================================================
// SETUP / LOOP
// =======================================================

void setup() {
    Serial.begin(115200);
    Wire.begin(); 
    
    initOLED();
    
    pinMode(buzzer, OUTPUT);
    pinMode(anaPin, INPUT);
    pinMode(redLED, OUTPUT);
    pinMode(buttonPin, INPUT_PULLUP);
    digitalWrite(redLED, LOW);

    displayWelcome();  // 移到前面，顯示 2 秒後再進入狀態

    Serial.println("========================================");
    Serial.println("VoiceMed2 Smart Pillbox Starting...");
    Serial.println("========================================");

    // ✅ 設定 NimBLE 參數（在 init 之前）
    NimBLEDevice::setPower(ESP_PWR_LVL_P9);  // 提高發射功率

    if (loadConfig()) {
        Serial.println("📂 WiFi config found, connecting...");
        updateSystemState(WIFI_CONNECTING); 
    } else {
        Serial.println("📂 No WiFi config, entering BLE mode...");
        updateSystemState(BLE_CONFIG);
    }

    Serial.println("✅ Setup complete");
}

void loop() {
    // ✅ 每 5 秒輸出一次當前狀態
    static unsigned long lastStatusPrint = 0;
    if (millis() - lastStatusPrint > 5000) {
        lastStatusPrint = millis();
        Serial.println("========================================");
        Serial.print("📍 Current State: ");
        switch (currentState) {
            case BLE_CONFIG: Serial.println("BLE_CONFIG (等待手機連線)"); break;
            case WIFI_CONNECTING: Serial.println("WIFI_CONNECTING (連線中)"); break;
            case WIFI_CONNECTED: Serial.println("WIFI_CONNECTED (已連線)"); break;
        }
        Serial.print("📶 WiFi Status: ");
        Serial.println(WiFi.status() == WL_CONNECTED ? "已連線" : "未連線");
        if (WiFi.status() == WL_CONNECTED) {
        Serial.print("🌐 IP: ");
        Serial.println(WiFi.localIP());
        }
        Serial.print("📡 BLE Connected: ");
        Serial.println(bleConnected ? "是" : "否");
        Serial.println("========================================");
    }

    // 狀態機邏輯
    switch (currentState) {
        case BLE_CONFIG: {
            // ✅ 手動檢查連線數量
            if (pServer) {
                int connCount = pServer->getConnectedCount();
                
                static int lastConnCount = 0;
                if (connCount != lastConnCount) {
                Serial.print("🔗 連線數變化: ");
                Serial.print(lastConnCount);
                Serial.print(" → ");
                Serial.println(connCount);
                lastConnCount = connCount;
                
                if (connCount > 0) {
                    Serial.println("✅ 偵測到有裝置連線！");
                } else {
                    Serial.println("⚠️ 裝置已斷線");
                }
                }
            }
            
            break;
        }
            
        case WIFI_CONNECTING: {
            static unsigned long connectStartTime = 0;
            static unsigned long lastDotTime = 0;
            if (connectStartTime == 0) {
                connectStartTime = millis();
                lastDotTime = millis();
            }

            // ✅ 每秒輸出一個點，表示還在連線中
            if (millis() - lastDotTime > 1000) {
                lastDotTime = millis();
                Serial.print(".");
                if ((millis() - connectStartTime) % 10000 < 1000) {
                Serial.print(" (");
                Serial.print((millis() - connectStartTime) / 1000);
                Serial.println("s)");
                }
            }

            if (WiFi.status() == WL_CONNECTED) {
                Serial.println("\n✅ WiFi 連線成功！");
                updateSystemState(WIFI_CONNECTED);
            } else if (millis() - connectStartTime > 30000) { 
                Serial.println("Wi-Fi Connection Timeout. Switching to BLE Config.");
                updateSystemState(BLE_CONFIG); 
                connectStartTime = 0;
            }
            break;
        }

        case WIFI_CONNECTED: {
            timeClient.update(); 
            server.handleClient(); 
            checkAlarms(); 
            
            updateTimeDisplay(); 
            
            // 可變電阻音量控制和測試邏輯
            val = analogRead(anaPin);
            int volume = map(val, 0, 4095, 0, 100);

            if (abs(val - previousVal) > 5) {
                previousVal = val;
                displayVolume(volume);
                
                if (!alarmActive) {
                    isTestingVolume = true;
                    lastVolumeTestTime = millis();
                    playTestTone(volume);
                }
            } else {
                if (isTestingVolume && (millis() - lastVolumeTestTime > VOLUME_TEST_TIMEOUT)) {
                    isTestingVolume = false;
                    displayVoiceMed();
                }
            }

            if (WiFi.status() != WL_CONNECTED) {
                Serial.println("Wi-Fi Lost. Retrying...");
                updateSystemState(WIFI_CONNECTING); 
            }
            break;
        }
    }
    delay(10);
}


// =======================================================
// 狀態切換與管理
// =======================================================

void updateSystemState(SystemState newState) {
    Serial.println("\n🔄 ========== 狀態切換 ==========");
    Serial.print("從 ");
    switch (currentState) {
        case BLE_CONFIG: Serial.print("BLE_CONFIG"); break;
        case WIFI_CONNECTING: Serial.print("WIFI_CONNECTING"); break;
        case WIFI_CONNECTED: Serial.print("WIFI_CONNECTED"); break;
    }
    Serial.print(" → ");
    switch (newState) {
        case BLE_CONFIG: Serial.println("BLE_CONFIG"); break;
        case WIFI_CONNECTING: Serial.println("WIFI_CONNECTING"); break;
        case WIFI_CONNECTED: Serial.println("WIFI_CONNECTED"); break;
    }

    currentState = newState;
    
    // 清理舊模式的資源
    WiFi.disconnect(true);
    
    // ✅ 如果要進入 BLE 模式，完全重新初始化
    if (newState == BLE_CONFIG) {
        // 清理舊的 BLE
        if (pServer) {
        NimBLEDevice::deinit(true);  // ✅ 完全清除
        delay(100);
        }
        
        Serial.println("📱 啟動藍牙配對模式...");
        startBLEServer();
        setDisplayStatus("Mode: BLE Config", "Ready to Receive Config");
        Serial.println("✅ 藍牙配對模式已就緒");
        Serial.println("👉 請在手機 APP 上進行掃描");
    }
    else if (newState == WIFI_CONNECTING) {
        // 清理 BLE（切換到 WiFi 模式）
        NimBLEDevice::deinit(true);
        server.stop();
        
        Serial.println("📶 開始連線 WiFi...");
        Serial.print("  SSID: ");
        Serial.println(currentSSID);
        WiFi.mode(WIFI_STA);
        WiFi.begin(currentSSID.c_str(), currentPassword.c_str());
        setDisplayStatus("Mode: Connecting", "SSID: " + currentSSID);
        Serial.println("⏳ 等待連線中...");
    }
    else if (newState == WIFI_CONNECTED) {
        startBLEServer();
        if (pStatusChar) {
            String statusMsg = "CONNECTED:" + WiFi.localIP().toString();
            pStatusChar->setValue(statusMsg.c_str());
            pStatusChar->notify();  // 主動通知APP
        }
    
        // 5秒後再關閉BLE，啟動WiFi服務
        delay(5000);
        NimBLEDevice::deinit();

        Serial.println("🎉 WiFi 連線成功！");
        Serial.print("🌐 IP 位址: ");
        Serial.println(WiFi.localIP());

        server.on("/api/alarms", HTTP_POST, handleAlarmUpdate);
        server.on("/api/time", HTTP_GET, handleGetTime);
        server.begin();
        
        Serial.println("🌐 Web Server 已啟動");
        Serial.println("  → POST /api/alarms (設定鬧鐘)");
        Serial.println("  → GET  /api/time   (取得時間)");

        timeClient.begin();
        timeClient.setTimeOffset(utcOffsetInSeconds);
        
        setDisplayStatus("Connection successful", "IP: " + WiFi.localIP().toString());
        Serial.println("✅ 系統完全就緒");
    }
    Serial.println("==================================\n");
}

// =======================================================
// 鬧鐘/Web Server API
// =======================================================

void handleAlarmUpdate() {
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, server.arg("plain"));

  if (error) {
    server.send(400, "text/plain", "Invalid JSON");
    return;
  }

  alarms.clear();
  JsonArray alarmArray = doc.as<JsonArray>();

  for (JsonObject obj : alarmArray) {
    Alarm newAlarm;
    newAlarm.id = obj["id"] | 0;
    newAlarm.hour = obj["hour"] | 0;
    newAlarm.minute = obj["minute"] | 0;
    newAlarm.year = obj["year"] | 0;
    newAlarm.month = obj["month"] | 0;
    newAlarm.day = obj["day"] | 0;
    newAlarm.isEnabled = obj["isEnabled"] | true;
    newAlarm.isRepeating = obj["isRepeating"] | false; 
    alarms.push_back(newAlarm);
  }

  server.send(200, "text/plain", "Alarms updated successfully!");
}

void handleGetTime() {
  timeClient.update();
  StaticJsonDocument<256> doc;
  doc["epoch"] = timeClient.getEpochTime();
  doc["formattedTime"] = timeClient.getFormattedTime();
  doc["status"] = "OK";
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

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
  
  for (auto& alarm : alarms) {
    if (alarm.isEnabled) {
      bool dateMatch = (currentYear == alarm.year && 
                        currentMonth == alarm.month && 
                        currentDay == alarm.day);
      
      bool isSameAlarm = (alarm.id == lastTriggeredAlarmId);
      bool isInCooldown = (millis() - lastAlarmTriggerTime < ALARM_TRIGGER_COOLDOWN);
      
      if (dateMatch && 
          currentHour == alarm.hour && 
          currentMinute == alarm.minute && 
          !(isSameAlarm && isInCooldown)) {
        
        lastTriggeredAlarmId = alarm.id;
        lastAlarmTriggerTime = millis();
        
        triggerAlarm(alarm);
        
        // 單次提醒 - 觸發後立即禁用
        alarm.isEnabled = false; 
        
        delay(1000); 
      }
    }
  }

  // 檢查按鈕狀態 (停止警報)
  if (alarmActive && digitalRead(buttonPin) == LOW && redLedOn) {
    alarmActive = false;
    digitalWrite(redLED, LOW);
    
    oled2.clearBuffer();
    oled2.setFont(u8g2_font_ncenB24_tr); 
    oled2.drawStr(30, 45, "OK!");
    oled2.sendBuffer();
    delay(500);

    redLedOn = false; 
    
    displayVoiceMed();
    delay(2000);
  }
}

void triggerAlarm(Alarm& alarm) {
  alarmActive = true;
  digitalWrite(redLED, HIGH);
  redLedOn = true;
  
  // 顯示提醒 (OLED2)
  if (alarm.hour >= 5 && alarm.hour < 11) {
    displayMealReminder("Breakfast");
  } else if (alarm.hour >= 11 && alarm.hour < 17) {
    displayMealReminder("Lunch");
  } else if (alarm.hour >= 17 && alarm.hour < 21) {
    displayMealReminder("Dinner");
  } else {
    displayMealReminder("Before Sleep");
  }

  // 播放提醒音樂 (單次播放)
  int currentVolume = map(analogRead(anaPin), 0, 4095, 0, 100);
  playAlarmMelody(currentVolume); 
}

// =======================================================
// 鬧鐘/音量/OLED 輔助函式
// =======================================================

void updateTimeDisplay() {
  if (currentState != WIFI_CONNECTED) return;
  
  if (!timeClient.update()) {
      timeClient.forceUpdate();
  }
  
  unsigned long epochTime = timeClient.getEpochTime();
  time_t rawTime = (time_t)epochTime;
  struct tm *ptm = localtime(&rawTime);
  
  int currentYear = ptm->tm_year + 1900;
  int currentMonth = ptm->tm_mon + 1;
  int currentDay = ptm->tm_mday;
  int currentHour = timeClient.getHours();
  int currentMinute = timeClient.getMinutes();
  int currentSecond = timeClient.getSeconds();

  String timeStr = (currentHour < 10 ? "0" : "") + String(currentHour) + ":" + 
                   (currentMinute < 10 ? "0" : "") + String(currentMinute);
  
  String dateStr = String(currentYear) + "/" + 
                   (currentMonth < 10 ? "0" : "") + String(currentMonth) + "/" + 
                   (currentDay < 10 ? "0" : "") + String(currentDay);
                   
  const char *weekDayNames[] = {"SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"};
  String weekDayStr = weekDayNames[ptm->tm_wday];

  // OLED1 顯示 (分頁模式)
  oled1.firstPage();
  do {
    oled1.clearBuffer();
    
    // 1. 顯示時間 (大字體)
    oled1.setFont(u8g2_font_logisoso24_tf); 
    int timeWidth = oled1.getStrWidth(timeStr.c_str());
    oled1.drawStr(128 - timeWidth, 30, timeStr.c_str());
    
    // 2. 顯示日期 (小字體)
    oled1.setFont(u8g2_font_6x10_tf); 
    int dateWidth = oled1.getStrWidth(dateStr.c_str());
    oled1.drawStr(128 - dateWidth, 45, dateStr.c_str());
    
    // 3. 顯示星期 (小字體)
    int weekDayWidth = oled1.getStrWidth(weekDayStr.c_str());
    oled1.drawStr(128 - weekDayWidth, 60, weekDayStr.c_str());
    
    // 4. 顯示秒數 (左上角)
    String secStr = (currentSecond < 10 ? "0" : "") + String(currentSecond);
    oled1.drawStr(0, 10, secStr.c_str());

  } while(oled1.nextPage());
}

void displayMealReminder(const char* meal) {
    oled2.firstPage();
    do {
        oled2.setFont(u8g2_font_ncenB14_tr);
        oled2.drawStr(0, 20, "Reminder!");
        oled2.setFont(u8g2_font_ncenB12_tr);
        oled2.drawStr(0, 40, meal);
    } while (oled2.nextPage());
}

void displayVolume(int volume) {
    oled2.firstPage();
    do {
        oled2.setFont(u8g2_font_ncenB14_tr);
        oled2.drawStr(0, 20, "Volume");
        oled2.setFont(u8g2_font_ncenB24_tr);
        oled2.drawStr(0, 50, String(volume).c_str());
        oled2.drawStr(60, 50, "%");
    } while (oled2.nextPage());
}

void displayVoiceMed() {
    oled2.firstPage();
    do {
        oled2.setFont(u8g2_font_ncenB14_tr);
        oled2.drawStr(0, 20, "Volume");
        oled2.setFont(u8g2_font_ncenB10_tr);
        oled2.drawStr(0, 40, "Steady");
    } while (oled2.nextPage());
}

void playTone(int frequency, int duration, int volume) {
    if (frequency == 0) {
        noTone(buzzer);
        delay(duration);
        return;
    }
    int onTime = 512 * volume / 100;
    int offTime = 512 - onTime;
    
    for (long i = 0; i < (long)duration * 1000L; i += 1000) {
        digitalWrite(buzzer, HIGH);
        delayMicroseconds(onTime);
        digitalWrite(buzzer, LOW);
        delayMicroseconds(offTime);
    }
}

void playAlarmMelody(int volume) {
  playTone(880, 500, volume);
  noTone(buzzer);
  delay(100);
}

void playTestTone(int volume) {
  playTone(880, 50, volume);
  noTone(buzzer);
}

// =======================================================
// 輔助函式 (Utility Functions)
// =======================================================

bool loadConfig() {
    preferences.begin(NVS_NAMESPACE, true);
    currentSSID = preferences.getString(NVS_SSID_KEY, "");
    currentPassword = preferences.getString(NVS_PWD_KEY, "");
    String btName = preferences.getString(NVS_BTNAME_KEY, "ESP32_BLE_Config");
    preferences.end();
    
    // 始終初始化 NimBLE 設備名稱
    NimBLEDevice::init(btName.c_str());
    return currentSSID.length() > 0;
}

void saveWiFiConfig(const String& ssid, const String& password) {
    preferences.begin(NVS_NAMESPACE, false);
    preferences.putString(NVS_SSID_KEY, ssid);
    preferences.putString(NVS_PWD_KEY, password);
    preferences.end();
    
    currentSSID = ssid;
    currentPassword = password;
}

void startBLEServer() {
    Serial.println("📱 啟動藍牙配對模式...");
  
    String btName = "VoiceMed2";
    preferences.begin(NVS_NAMESPACE, true);
    btName = preferences.getString(NVS_BTNAME_KEY, btName);
    preferences.end();
    
    Serial.print("🔵 BLE Device Name: ");
    Serial.println(btName);
    
    // 初始化 NimBLE
    NimBLEDevice::init(btName.c_str());
    NimBLEDevice::setMTU(512);
    NimBLEDevice::setSecurityAuth(false, false, true);
    NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);

    // 建立 Server 並註冊 Callbacks
    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    Serial.println("✅ Server Callbacks 已註冊");

    // 建立 Service
    NimBLEService* pService = pServer->createService(SERVICE_UUID);
    Serial.println("✅ Service 已建立");

    // WiFi 設定特徵
    NimBLECharacteristic* pWifiChar = pService->createCharacteristic(
        CHAR_WIFI_UUID, 
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE
    );
    pWifiChar->setCallbacks(new CharacteristicCallbacks());
    Serial.println("✅ WiFi Characteristic 已建立並註冊 Callbacks");

    // 藍牙名稱設定特徵
    NimBLECharacteristic* pBTNameChar = pService->createCharacteristic(
        CHAR_BTNAME_UUID, 
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE
    );
    pBTNameChar->setCallbacks(new CharacteristicCallbacks());
    Serial.println("✅ BTName Characteristic 已建立並註冊 Callbacks");

    // 狀態特徵
    if (pStatusChar == nullptr) {
        pStatusChar = pService->createCharacteristic(
            CHAR_STATUS_UUID, 
            NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
        );
        pStatusChar->setValue("READY");
        Serial.println("✅ Status Characteristic 已建立");
    }

    // 啟動服務（關鍵！）
    pService->start();
    Serial.println("✅ Service 已啟動");
    
    // 開始廣播（關鍵！）
    pServer->startAdvertising();
    Serial.println("✅ 開始廣播（使用 pServer->startAdvertising()）");
    
    // 也可以用 pAdvertising 設定更多細節
    pAdvertising = NimBLEDevice::getAdvertising();
    
    NimBLEAdvertisementData advertisementData;
    advertisementData.setName(btName.c_str());
    advertisementData.setCompleteServices(NimBLEUUID(SERVICE_UUID));
    advertisementData.setFlags(0x06);
    pAdvertising->setAdvertisementData(advertisementData);
    
    NimBLEAdvertisementData scanResponseData;
    scanResponseData.setName(btName.c_str());
    pAdvertising->setScanResponseData(scanResponseData);
    
    pAdvertising->setMinInterval(100);
    pAdvertising->setMaxInterval(200);
    
    Serial.println("✅ BLE Server 完全啟動");
    Serial.println("📡 廣播名稱: " + btName);
    Serial.println("📡 Service UUID: " + String(SERVICE_UUID));
    Serial.println("👉 請從手機 APP 連線");
    Serial.println("========================================");
}

void setDisplayStatus(const String& line1, const String& line2) {
    Serial.println("🖥️ Updating OLED:");
    Serial.println("  Line1: " + line1);
    Serial.println("  Line2: " + line2);

    oled1.firstPage();
    do {
        oled1.setFont(u8g2_font_6x10_tf);
        oled1.drawStr(0, 15, line1.c_str());
        oled1.drawStr(0, 30, line2.c_str());
    } while(oled1.nextPage());
    
    oled2.firstPage();
    do {
        oled2.setFont(u8g2_font_6x10_tf);
        oled2.drawStr(0, 15, "System State:");
        oled2.drawStr(0, 30, String(currentState).c_str());
    } while(oled2.nextPage());

    Serial.println("✅ OLED updated");
}

void initOLED() {
    oled1.begin(); 
    oled2.begin(); 
}

void displayWelcome() {
    oled1.firstPage();
    do {
        oled1.setFont(u8g2_font_ncenB12_tr);
        oled1.drawStr(0, 30, "Smart Alarm System");
    } while(oled1.nextPage());
    
    oled2.firstPage();
    do {
        oled2.setFont(u8g2_font_ncenB10_tr);
        oled2.drawStr(0, 30, "Initializing...");
    } while(oled2.nextPage());
    delay(2000);
}