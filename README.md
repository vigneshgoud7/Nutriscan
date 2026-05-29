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

## 📖 Project Overview

NutriScan AI is a full-stack, AI-powered health and nutrition application designed to revolutionize how individuals understand their dietary intake. Simply capture a photo of any food, meal, or nutrition label, and receive an instant, personalized dietary analysis. 

Powered by **Google Gemini 1.5 Flash Vision** and tailored to your unique health profile, allergies, and specific goals, NutriScan acts as your 24/7 personal nutritionist. Whether you are tracking macros, managing allergies, or trying to make healthier grocery choices, NutriScan provides real-time, actionable insights.

### ✨ Key Features

- 📸 **AI Image Analysis:** Photograph nutrition labels or meals to get instant macronutrient breakdowns and ingredient insights.
- 🧑‍⚕️ **Deep Personalization:** Every AI response is contextualized to your custom health profile (age, sex, weight, fitness goals, medical history, and diet type).
- ⚠️ **Allergy Alerts:** Automatic, immediate warnings if a scanned product contains your documented allergens, keeping you safe.
- ⚖️ **Smart Comparisons:** Side-by-side analysis of multiple products (up to 5) with AI-driven recommendations on the optimal choice for your specific needs.
- 💬 **Contextual Chat:** Engage in a continuous, dynamic conversation with your AI nutritionist—with memory spanning your last 10 messages for a seamless experience.
- 🔒 **Secure Auth & Data:** Built with robust Supabase Authentication (Email/Password, Google, Apple) and Row-Level Security (RLS) to ensure your health data remains strictly confidential.
- ⚡ **Freemium Tier:** Free users get 20 requests per day. Premium users get up to 500 requests per day.

---

## 💻 Tech Stack

The application is built using a modern, scalable, and highly performant architecture.

### Frontend (Mobile & Web)
*   **Framework:** [Flutter](https://flutter.dev/) (Dart) - For building natively compiled applications for mobile, web, and desktop from a single codebase.
*   **State Management:** [Riverpod](https://riverpod.dev/) - For robust and compile-safe state management.
*   **Routing:** [GoRouter](https://pub.dev/packages/go_router) - Declarative routing for complex navigation flows.
*   **Networking:** [Dio](https://pub.dev/packages/dio) - Powerful HTTP client for Dart.

### Backend (API Service)
*   **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python) - High-performance web framework for building APIs.
*   **AI Integration:** Google Gemini 1.5 Flash (via `google-genai`) - For state-of-the-art vision and natural language processing.
*   **Validation:** [Pydantic](https://docs.pydantic.dev/) - Data validation and settings management using Python type annotations.

### Database & Infrastructure
*   **Database:** PostgreSQL (hosted on [Supabase](https://supabase.com/)) - Relational database handling complex queries and user profiles.
*   **Authentication:** Supabase Auth - Managing user identities and secure access.
*   **Storage:** Supabase Storage - Public CDN for storing and serving user-uploaded food images.

---

## 📱 Screenshots

> **Note:** Add your actual project screenshots to an `assets/images/` folder in your repository and update these paths.

| Home Dashboard | AI Analysis Results | Product Comparison | Health Profile |
| :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/vigneshgoud7/Nutriscan/main/frontend/assets/images/placeholder_home.png" onerror="this.src='https://via.placeholder.com/250x500.png?text=Home+Screen'" width="200" alt="Home Dashboard"/> | <img src="https://raw.githubusercontent.com/vigneshgoud7/Nutriscan/main/frontend/assets/images/placeholder_analysis.png" onerror="this.src='https://via.placeholder.com/250x500.png?text=Analysis+Screen'" width="200" alt="AI Analysis"/> | <img src="https://raw.githubusercontent.com/vigneshgoud7/Nutriscan/main/frontend/assets/images/placeholder_compare.png" onerror="this.src='https://via.placeholder.com/250x500.png?text=Compare+Screen'" width="200" alt="Compare Products"/> | <img src="https://raw.githubusercontent.com/vigneshgoud7/Nutriscan/main/frontend/assets/images/placeholder_profile.png" onerror="this.src='https://via.placeholder.com/250x500.png?text=Profile+Screen'" width="200" alt="User Profile"/> |

*Experience a seamless, intuitive UI designed for effortless navigation and quick insights.*

---

## 🏗️ System Architecture

NutriScan AI utilizes a decoupled client-server architecture. The Flutter frontend communicates securely with the FastAPI backend via RESTful APIs.

```mermaid
graph TD
    %% Frontend
    subgraph Client [Flutter App]
        UI[User Interface]
        State[Riverpod State]
        AuthClient[Supabase Client]
    end

    %% Backend API
    subgraph Backend [FastAPI Service]
        API[API Router]
        AuthMiddleware[JWT Auth Middleware]
        GeminiService[Gemini AI Service]
        DBClient[AsyncPG DB Client]
    end

    %% External Services
    subgraph Cloud [External Cloud Services]
        SupabaseDB[(Supabase PostgreSQL)]
        SupabaseAuth[Supabase Auth]
        SupabaseStorage[Supabase Storage]
        GeminiAPI[Google Gemini 1.5 Flash]
    end

    %% Flow
    UI <--> State
    State <--> |REST HTTPS| API
    AuthClient <--> |JWT Token| SupabaseAuth
    API <--> AuthMiddleware
    AuthMiddleware <--> DBClient
    API <--> GeminiService
    GeminiService <--> |gRPC / REST| GeminiAPI
    DBClient <--> |SQL| SupabaseDB
    API <--> SupabaseStorage
```

### Data Flow Example (Image Analysis):
1. **Capture:** User captures a food image in the Flutter app.
2. **Upload:** The image is uploaded directly to **Supabase Storage**.
3. **Request:** The Flutter app sends the image URL and user prompt to the **FastAPI `/chat/message` endpoint**.
4. **Auth & Context:** The backend verifies the user's JWT token and retrieves their **Health Profile** from PostgreSQL.
5. **Prompt Engineering:** The backend constructs a highly detailed prompt combining the image, user query, and health profile context.
6. **AI Processing:** The prompt is sent to **Google Gemini Vision AI**.
7. **Response:** The AI response is processed, saved to the database (Chat History), and returned to the client.

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

## 🔮 Future Roadmap

We are constantly innovating. Here is what is coming next to NutriScan AI:

- [ ] **Barcode Scanning:** Direct integration with OpenFoodFacts API for instant product lookup without AI processing, saving time and tokens.
- [ ] **Meal Logging & Calendar:** Daily macro and calorie tracking integrated with a comprehensive calendar view for long-term diet management.
- [ ] **Wearable Integration:** Sync health data (calories burned, active minutes, steps) directly from Apple Health and Google Fit for a holistic health view.
- [ ] **Multi-language Support:** Expand the AI prompt guidelines to natively support localized nutrition recommendations in Spanish, French, German, and Hindi.
- [ ] **Community Sharing:** A platform for users to share healthy AI-approved recipes and findings with the NutriScan community.

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
