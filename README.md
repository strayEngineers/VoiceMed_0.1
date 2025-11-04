# VoiceMed - Smart Medication Management System

[![Static Badge](https://img.shields.io/badge/lang-en-red)](./README.md) [![Static Badge](https://img.shields.io/badge/lang-zh--tw-yellow)](./README.zh-tw.md) ![Flutter](https://img.shields.io/badge/Flutter-3.3.4-blue) ![License](https://img.shields.io/badge/License-MIT-green)

> An intelligent medication management solution integrating voice-enabled mobile app, IoT smart pillbox, and AI assistant to help elderly and visually impaired users manage medications effortlessly.

---

## 📋 Table of Contents

- [About the Project](#about-the-project)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [System Architecture](#system-architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
  - [Hardware Setup](#hardware-setup)
- [Deployment](#deployment)
- [Technical Challenges](#technical-challenges)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## 🎯 About the Project

### Motivation

VoiceMed was developed to address critical challenges faced by elderly and visually impaired individuals in medication management:

- **Difficulty reading prescription labels** (small fonts, complex medical terminology)
- **Missing medication doses** due to lack of timely reminders
- **Limited caregiver oversight** for remote monitoring

### Target Users

- **Primary Users**: Elderly, visually impaired individuals
- **Caregivers**: Family members or healthcare professionals needing remote monitoring
- **General Users**: Anyone requiring medication management and reminders

---

## ✨ Key Features

### 🔊 Voice-Enabled Prescription Scanning
- OCR scans prescription labels and converts text to speech
- Supports QR code scanning for detailed medication information

### 🌐 Multi-Language Support
- Chinese/English interface and voice translation
- Accessibility-first design

### ⏰ Smart Medication Reminders
- Dual reminders: mobile app + IoT smart pillbox
- Customizable schedules with voice alerts

### 🤖 AI Assistant
- Natural language Q&A for medication queries
- Powered by LLM with pharmaceutical knowledge base (RAG architecture)

### 👨‍⚕️ Caregiver Mode
- Remote management of multiple pillboxes
- Real-time medication adherence monitoring
- Push notifications for missed doses

### 🎮 Gamification & Rewards
- Earn points for medication adherence
- Virtual plant growth visualization
- Achievement system with social sharing

### 📊 Dashboard Analytics
- Visual charts for medication history
- Adherence statistics and insights

### 🌍 PWA Support
- Cross-platform web app (iOS/Android/Desktop)
- Offline functionality with background sync

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter/Dart
- **Platforms**: iOS, Android, Web (PWA)
- **State Management**: Provider
- **UI/UX**: Material Design with accessibility support

### Backend
- **API Server**: Flask (Python)
- **Database**: 
  - Local: SQLite (offline sync)
  - Cloud: PostgreSQL/MySQL
- **Real-time Communication**: MQTT/WebSocket

### Hardware (IoT)
- **Microcontroller**: ESP32/Arduino
- **Components**: OLED display, buzzer, LED indicators, rotary encoder

### AI & Voice
- **OCR**: Tesseract + Custom ML models
- **Speech Recognition**: Google Speech-to-Text API
- **Text-to-Speech**: Google TTS API
- **LLM**: GPT API / Local models with RAG

### Key Dependencies
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

## 🏗️ System Architecture

```
Frontend Layer
├─ Flutter/Dart APP (iOS/Android)
├─ PWA (Web)
│   ├─ Multi-language UI
│   ├─ Theme switching (Light/Dark)
│   └─ Accessibility features
│
RESTful API / WebSocket
│
Backend/API
├─ Flask/Python API Server
│   ├─ Authentication & Authorization
│   ├─ Medication data management
│   └─ AI/LLM integration
├─ SQLite (Local) + PostgreSQL (Cloud)
│   ├─ User profiles & medication records
│   └─ Offline sync mechanism
│
MQTT/WebSocket
│
Hardware/IoT Layer
└─ ESP32/Arduino 音箱式藥盒
    ├─ OLED display module
    ├─ Buzzer alert system
    ├─ LED warning lights
    └─ Rotary volume control
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: >= 3.3.4
- **Dart**: >= 3.3.4
- **Android Studio** / **Xcode** (for mobile development)
- **Python**: >= 3.8 (for backend API)
- **Arduino IDE** / **PlatformIO** (for ESP32 firmware)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/voicemed.git
cd voicemed

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure environment variables
# Create .env file
cp .env.example .env

# Edit .env with your API keys (Google Speech API, etc.)
```

### Running the App

#### Mobile (Android/iOS)
```bash
flutter run
```

#### Web (PWA)
```bash
flutter run -d chrome
```

#### Backend API Server
```bash
cd backend
pip install -r requirements.txt
flask run
```

### Hardware Setup

#### ESP32 Smart Pillbox

1. **Install ESP32 board support** in Arduino IDE
   - Go to `Tools > Board > Boards Manager`
   - Search "ESP32" and install

2. **Configure WiFi credentials**
```c
// In config.h
#define WIFI_SSID "YourWiFiName"
#define WIFI_PASSWORD "YourPassword"
```

3. **Upload firmware**
- Select `Tools > Board > ESP32 Dev Module`
- Click Upload button

4. **Auto WiFi setup (alternative)**
```c
#include <WiFiManager.h>
WiFiManager wifiManager;
wifiManager.autoConnect("VoiceMed-Setup");
```

---

## 📦 Deployment

### Production Architecture

Production Environment
├─ Mobile APP: App Store / Google Play
├─ PWA: HTTPS Server (Nginx/Apache)
├─ API: Flask Backend (Gunicorn + Nginx)
├─ Database: PostgreSQL/MySQL
└─ Hardware: ESP32 Firmware (Arduino IDE/PlatformIO)

### Flutter APP Deployment

#### Android (Google Play)
```bash
flutter build apk --release
flutter build appbundle --release
```

#### iOS (App Store)
```bash
flutter build ios --release
```

### PWA Deployment
```bash
# Build production web version
flutter build web --release

# Deploy to server
scp -r build/web/* user@server:/var/www/voicemed/
```

### Backend API Deployment
```bash
# Using Gunicorn + Nginx
gunicorn -w 4 -b 0.0.0.0:5000 app:app

# Setup HTTPS with Let's Encrypt
sudo certbot --nginx -d yourdomain.com
```

### Database Migration
```bash
# Flask-Migrate for schema management
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

---

## 🔧 Technical Challenges & Solutions

### 1. **Cross-Platform IoT Integration**
**Challenge**: Real-time synchronization between APP, server, and ESP32 pillbox  
**Solution**:
- MQTT/WebSocket real-time messaging
- RESTful API for data exchange
- Offline cache mechanism (SQLite)
- Auto-reconnect with data compensation

### 2. **Bilingual Voice Recognition & Synthesis**
**Challenge**: Medical terminology, noisy environments, natural TTS  
**Solution**:
- Google Speech-to-Text/Text-to-Speech API
- Custom pharmaceutical vocabulary training
- Noise reduction algorithms

### 3. **OCR Prescription Accuracy**
**Challenge**: Inconsistent label formats, lighting conditions  
**Solution**:
- Tesseract OCR + ML model optimization
- Image preprocessing (denoising, binarization, skew correction)
- Multi-engine verification

### 4. **AI Natural Language Understanding**
**Challenge**: Conversational queries, personalized responses  
**Solution**:
- LLM integration (GPT API or local models)
- RAG architecture with pharmaceutical knowledge base
- Context memory for multi-turn dialogue

### 5. **Caregiver Multi-Device Management**
**Challenge**: One-to-many device control, permission management  
**Solution**:
- Device binding & authorization system
- WebSocket push notifications
- Hierarchical permission control

### 6. **Gamification Design**
**Challenge**: Balance fun vs. practicality  
**Solution**:
- Points algorithm based on medication adherence
- Virtual plant growth animations (CSS/Lottie)
- Achievement system with social sharing

### 7. **PWA Offline Functionality**
**Challenge**: Service Worker caching, offline sync  
**Solution**:
- Workbox caching framework
- IndexedDB local storage
- Background Sync API

---

## 🗺️ Roadmap

- [ ] Multi-platform medication interaction database
- [ ] Wearable device integration (Apple Watch, Fitbit)
- [ ] Telemedicine consultation booking
- [ ] AI-powered dosage optimization
- [ ] Blockchain-based medication tracking

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

Project Maintainer: 
[rainlin138077](https://github.com/rainlin138077)
[xiaoyu](https://github.com/411177031)
[CipCap](https://github.com/CipherCapricorn)

Project Link:
[https://github.com/strayEngineers/VoiceMed_0.1](https://github.com/strayEngineers/VoiceMed_0.1)