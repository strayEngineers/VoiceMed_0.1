# VoiceMed - 智慧藥物管理系統

[![Static Badge](https://img.shields.io/badge/lang-en-red)](./README.md) [![Static Badge](https://img.shields.io/badge/lang-zh--tw-yellow)](./README.zh-tw.md) ![Flutter](https://img.shields.io/badge/Flutter-3.3.4-blue) ![License](https://img.shields.io/badge/License-MIT-green)

> 整合語音化行動應用程式、IoT 智慧藥盒與 AI 助手的完整藥物管理解決方案，幫助長者和視障人士輕鬆管理用藥。

---

## 📋 目錄

- [關於專案](#關於專案)
- [核心功能](#核心功能)
- [技術棧](#技術棧)
- [系統架構](#系統架構)
- [快速開始](#快速開始)
  - [環境需求](#環境需求)
  - [安裝步驟](#安裝步驟)
  - [執行應用程式](#執行應用程式)
  - [硬體設定](#硬體設定)
- [部署說明](#部署說明)
- [技術挑戰](#技術挑戰)
- [開發路線圖](#開發路線圖)
- [貢獻指南](#貢獻指南)
- [授權條款](#授權條款)
- [聯絡方式](#聯絡方式)

---

## 🎯 關於專案

### 開發動機

VoiceMed 致力於解決長者和視障人士在藥物管理上的關鍵挑戰：

- **藥袋資訊難以閱讀**（字體過小、專業術語複雜）
- **容易忘記服藥**，缺乏及時提醒機制
- **照護者難以遠端監控**用藥狀況

### 目標使用者

- **主要使用者**：長者、視障人士
- **照護者**：需要遠端監控的家屬或醫護人員
- **一般使用者**：需要藥物管理與提醒的普通民眾

---

## ✨ 核心功能

### 🔊 藥袋掃描語音化
- OCR 掃描藥袋文字並轉換為語音播放
- 支援 QR code 掃描取得詳細藥物資訊

### 🌐 多語言支援
- 中英文介面與語音翻譯
- 無障礙優先設計

### ⏰ 智慧服藥提醒
- APP 與 IoT 智慧藥盒雙向提醒
- 可自訂時程表與語音警示

### 🤖 AI 問答助手
- 自然語言回答用藥相關問題
- 整合 LLM 與藥物知識庫（RAG 架構）

### 👨‍⚕️ 照護者模式
- 遠端管理多個藥盒
- 即時監控服藥遵從度
- 漏服推送通知

### 🎮 遊戲化獎勵機制
- 準時服藥賺取積分
- 虛擬植物生長視覺化
- 成就系統與社交分享

### 📊 Dashboard 數據分析
- 圖表化服藥歷史紀錄
- 遵從度統計與洞察

### 🌍 PWA 跨平台支援
- 網頁版應用（iOS/Android/桌面）
- 離線功能與背景同步

---

## 🛠️ 技術棧

### 前端
- **框架**：Flutter/Dart
- **平台**：iOS、Android、Web (PWA)
- **狀態管理**：Provider
- **UI/UX**：Material Design 與無障礙支援

### 後端
- **API 伺服器**：Flask (Python)
- **資料庫**：
  - 本地：SQLite（離線同步）
  - 雲端：PostgreSQL/MySQL
- **即時通訊**：MQTT/WebSocket

### 硬體 (IoT)
- **微控制器**：ESP32/Arduino
- **元件**：OLED 顯示器、蜂鳴器、LED 指示燈、旋鈕

### AI 與語音
- **OCR**：Tesseract + 自訂 ML 模型
- **語音辨識**：Google Speech-to-Text API
- **語音合成**：Google TTS API
- **LLM**：GPT API / 本地模型 + RAG

### 主要依賴套件
```env
dependencies:
flutter: sdk
sqflite: ^2.3.3+1
path_provider: ^2.0.11
image_picker: ^1.1.0
permission_handler: ^11.3.1
audioplayers: ^6.0.0
provider: ^6.0.5
flutter_local_notifications: ^17.2.1+1
qr_code_scanner: ^1.0.1
shared_preferences: ^2.2.3
```

---

## 🏗️ 系統架構

```
前端層 (Frontend)
├─ Flutter/Dart APP (iOS/Android)
├─ PWA版本 (Web跨平台)
├─ 使用者介面 (多語言、主題切換、無障礙設計)
│
RESTful API / WebSocket
│
中間層 (Backend/API)
├─ Flask/Python API Server
├─ SQLite 本地資料庫 (離線資料同步)
├─ 雲端資料庫 (用戶資料、服藥紀錄)
│
MQTT/WebSocket
│
硬體層 (IoT)
├─ ESP32/Arduino 音箱式藥盒
├─ OLED螢幕顯示模組
├─ 蜂鳴器提醒模組
├─ LED警示燈
└─ 旋鈕音量調節
```

---

## 🚀 快速開始

### 環境需求

- **Flutter SDK**: >= 3.3.4
- **Dart**: >= 3.3.4
- **Android Studio** / **Xcode**（行動裝置開發）
- **Python**: >= 3.8（後端 API）
- **Arduino IDE** / **PlatformIO**（ESP32 韌體）

### 安裝步驟


```bash
# 1. Clone 專案
git clone https://github.com/yourusername/voicemed.git
cd voicemed

# 2. 安裝 Flutter 依賴套件
flutter pub get

# 3. 設定環境變數
# 建立 .env 檔案
cp .env.example .env

# 編輯 .env 填入 API 金鑰（Google Speech API 等）
```

### 執行應用程式

#### 行動裝置 (Android/iOS)
```bash
flutter run
```

#### 網頁版 (PWA)
```bash
flutter run -d chrome
```

#### 後端 API 伺服器
```bash
cd backend
pip install -r requirements.txt
flask run
```

### 硬體設定

#### ESP32 智慧藥盒

1. **安裝 ESP32 開發板支援**（Arduino IDE）
   - 前往 `Tools > Board > Boards Manager`
   - 搜尋 "ESP32" 並安裝

2. **設定 WiFi 憑證**
```c
// 在 config.h 中
#define WIFI_SSID "你的WiFi名稱"
#define WIFI_PASSWORD "你的密碼"
```

3. **上傳韌體**
- 選擇 `Tools > Board > ESP32 Dev Module`
- 點擊上傳按鈕

4. **自動 WiFi 設定（替代方案）**
```c
#include <WiFiManager.h>
WiFiManager wifiManager;
wifiManager.autoConnect("VoiceMed-Setup");
```

---

## 📦 部署說明

### 生產環境架構

生產環境
├─ 行動 APP：App Store / Google Play
├─ PWA：HTTPS 伺服器 (Nginx/Apache)
├─ API：Flask 後端 (Gunicorn + Nginx)
├─ 資料庫：PostgreSQL/MySQL
└─ 硬體：ESP32 韌體 (Arduino IDE/PlatformIO)

### Flutter APP 部署

#### Android (Google Play)
```bash
flutter build apk --release
flutter build appbundle --release
```

#### iOS (App Store)
```bash
flutter build ios --release
```

### PWA 部署
```bash
# 建置生產版本
flutter build web --release

# 部署到伺服器
scp -r build/web/* user@server:/var/www/voicemed/
```

### 後端 API 部署
```bash
# 使用 Gunicorn + Nginx
gunicorn -w 4 -b 0.0.0.0:5000 app:app

# 設定 HTTPS（Let's Encrypt）
sudo certbot --nginx -d yourdomain.com
```

### 資料庫遷移
```bash
# Flask-Migrate 自動遷移
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

---

## 🔧 技術挑戰與解決方案

### 1. **跨平台 IoT 整合**
**挑戰**：APP、伺服器、ESP32 藥盒三方即時同步  
**解決方案**：
- MQTT/WebSocket 即時通訊
- RESTful API 資料交換
- 離線快取機制 (SQLite)
- 斷線自動重連與資料補償

### 2. **雙語語音辨識與合成**
**挑戰**：藥物專業術語、噪音環境、語音自然度  
**解決方案**：
- Google Speech-to-Text/Text-to-Speech API
- 藥物專有名詞詞庫訓練
- 降噪演算法

### 3. **OCR 藥袋掃描準確度**
**挑戰**：藥袋格式不統一、光線影響  
**解決方案**：
- Tesseract OCR + 機器學習模型優化
- 影像前處理（去噪、二值化、傾斜校正）
- 多重識別引擎校驗

### 4. **AI 自然語言理解**
**挑戰**：理解口語化問題、個人化建議  
**解決方案**：
- LLM 整合（GPT API 或本地模型）
- RAG 架構結合藥物知識庫
- 對話上下文記憶

### 5. **照護者多裝置管理**
**挑戰**：一對多裝置控制、權限管理  
**解決方案**：
- 裝置綁定與授權機制
- WebSocket 推送通知
- 分層權限管理

### 6. **獎勵機制遊戲化設計**
**挑戰**：平衡趣味性與實用性  
**解決方案**：
- 基於服藥準時率的積分算法
- 虛擬植物生長動畫（CSS/Lottie）
- 成就系統與社交分享

### 7. **PWA 離線功能**
**挑戰**：Service Worker 快取、離線同步  
**解決方案**：
- Workbox 快取框架
- IndexedDB 本地儲存
- Background Sync API

---

## 🗺️ 開發路線圖

- [ ] 多平台藥物交互作用資料庫
- [ ] 穿戴式裝置整合（Apple Watch、Fitbit）
- [ ] 遠距醫療諮詢預約
- [ ] AI 驅動的劑量優化建議
- [ ] 區塊鏈藥物追蹤

---

## 🤝 貢獻指南

歡迎貢獻！請遵循以下步驟：

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

---

## 📄 授權條款

本專案採用 MIT License - 詳見 [LICENSE](LICENSE) 檔案

---

## 📞 聯絡方式

專案維護者：
[rainlin138077](https://github.com/rainlin138077)
[xiaoyu](https://github.com/411177031)
[CipCap](https://github.com/CipherCapricorn)

專案連結：
[https://github.com/strayEngineers/VoiceMed_0.1](https://github.com/strayEngineers/VoiceMed_0.1)