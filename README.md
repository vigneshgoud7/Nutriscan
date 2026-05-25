<div align="center">
  <img src="https://raw.githubusercontent.com/flutter/website/main/src/assets/images/docs/catalog-widget-placeholder.png" alt="NutriScan Logo" width="120" />
  <h1>🥗 NutriScan AI</h1>
  <p><em>Your Personal AI Nutritionist and Health Assistant</em></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
  [![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
  [![Gemini](https://img.shields.io/badge/Google%20Gemini-1.5%20Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
</div>

<br />

NutriScan AI is a full-stack, AI-powered health and nutrition application. Capture a photo of any food, meal, or nutrition label, and receive instant, personalized dietary analysis. Powered by **Google Gemini 1.5 Flash Vision** and tailored to your unique health profile, allergies, and goals.

---

## ✨ Features

- 📸 **AI Image Analysis:** Photograph nutrition labels or meals to get instant macronutrient breakdowns.
- 🧑‍⚕️ **Deep Personalization:** Every AI response is tailored to your customized health profile (age, sex, weight, goals, diseases, and diet type).
- ⚠️ **Allergy Alerts:** Automatic, immediate warnings if a scanned product contains your documented allergens.
- ⚖️ **Smart Comparisons:** Side-by-side analysis of multiple products (up to 5) with AI-driven recommendations on the best choice for you.
- 💬 **Contextual Chat:** Engage in continuous conversation with your AI nutritionist—memory spans your last 10 messages.
- 🔒 **Secure Auth & Data:** Built with Supabase Authentication (Email/Password, Google, Apple) and Row-Level Security (RLS) to protect your health data.
- ⚡ **Freemium Tier:** Free users get 20 requests per day. Premium users get up to 500 requests per day.

---

## 💻 Tech Stack

### Frontend
- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Routing:** [GoRouter](https://pub.dev/packages/go_router)
- **Network:** [Dio](https://pub.dev/packages/dio)

### Backend
- **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python)
- **Database:** PostgreSQL (hosted on [Supabase](https://supabase.com/))
- **AI Integration:** Google Gemini 1.5 Flash (via `google-genai`)
- **Storage:** Supabase Storage (Public CDN for images)

---

## 🚀 Setup Instructions

### 1. Prerequisites

Ensure you have the following installed:
- **Python 3.12+**
- **Flutter 3.19+**
- A **Supabase** account (Free tier is sufficient)
- A **Google AI Studio API Key** (Free tier)

### 2. Supabase Setup

1. Create a new project at [Supabase](https://app.supabase.com).
2. Navigate to the **SQL Editor** and execute the entire contents of `backend/schema.sql` to generate your database tables, triggers, and Row Level Security policies.
3. Navigate to **Storage** and create a new bucket named `food-images`. 
   - Set it to **Public**.
   - Set max file size to **10MB**.
   - Restrict to `image/jpeg`, `image/png`, and `image/webp`.

### 3. Environment Variables

Create a `.env` file in the `backend/` directory using the provided `.env.example`.

```env
# backend/.env
SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="YOUR_SERVICE_ROLE_KEY"
SUPABASE_JWT_SECRET="YOUR_JWT_SECRET"
DATABASE_URL="postgresql://postgres.[YOUR-PROJECT]:[PASSWORD]@aws-0-region.pooler.supabase.com:6543/postgres"
GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

Update your frontend constants in `frontend/lib/theme/constants.dart`:
```dart
static const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1'; // Or your deployed URL
static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 4. Running the Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Start the FastAPI server
uvicorn app.main:app --reload --port 8000
```
*API documentation will be available at [http://localhost:8000/docs](http://localhost:8000/docs)*

### 5. Running the Frontend

```bash
cd frontend
flutter pub get

# Run on Web for quick testing
flutter run -d chrome

# Run on iOS or Android emulator
flutter run
```

---

## 📡 API Endpoints

The FastAPI backend exposes the following primary endpoints under `/api/v1`:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/signup` | Register a new user |
| `POST` | `/auth/signin` | Authenticate and receive JWT |
| `GET`  | `/profile/me` | Fetch the authenticated user's health profile |
| `POST` | `/profile/me` | Upsert the user's health profile |
| `POST` | `/chat/message` | Send a message/image to Gemini AI |
| `POST` | `/compare/analyze`| Compare 2-5 products using AI |
| `GET`  | `/history/sessions`| Fetch user's conversation history |

---

## 📁 Folder Structure

```text
nutriscan/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI app entry point
│   │   ├── config.py            # Environment config
│   │   ├── database.py          # Async DB pool (asyncpg)
│   │   ├── routers/             # API Route handlers (auth, profile, chat)
│   │   ├── services/            # Business logic (Gemini AI, Rate Limiting)
│   │   ├── models/              # Pydantic Schemas
│   │   └── middleware/          # JWT Verification
│   ├── schema.sql               # Supabase Database Schema
│   └── requirements.txt
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart            # Flutter App Entry point
│   │   ├── theme/               # Dark theme, colors, typography
│   │   ├── models/              # Dart Data Models
│   │   ├── services/            # API Service Layer
│   │   ├── providers/           # Riverpod State Notifiers
│   │   ├── router/              # GoRouter Configuration
│   │   └── screens/             # UI Screens (Auth, Onboarding, Chat, History)
│   └── pubspec.yaml
└── README.md
```

---

## 🔮 Future Improvements

- **Barcode Scanning:** Direct integration with OpenFoodFacts API for instant product lookup without AI processing.
- **Meal Logging:** Daily macro and calorie tracking integrated with a calendar view.
- **Wearable Integration:** Sync health data (calories burned, steps) directly from Apple Health and Google Fit.
- **Multi-language Support:** Expand the AI prompt guidelines to support localized nutrition recommendations in Spanish, French, and Hindi.

---

## 🤝 Contribution Guidelines

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <b>Built with ❤️ for a healthier future.</b>
</div>
