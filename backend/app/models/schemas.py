from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum
from uuid import UUID


class UserPlan(str, Enum):
    free = "free"
    premium = "premium"


# ── Auth ──────────────────────────────────────────────────────────────────────

class SignUpRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str = Field(min_length=1, max_length=100)


class SignInRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    plan: UserPlan


class SocialAuthRequest(BaseModel):
    provider_token: str  # ID token from Google / Apple
    provider: str        # "google" | "apple"


# ── Health Profile ────────────────────────────────────────────────────────────

class HealthProfileCreate(BaseModel):
    age: Optional[int] = None
    sex: Optional[str] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    goal: Optional[str] = None           # weight_loss | muscle_gain | maintenance | manage_condition
    diseases: List[str] = []             # ["Type 2 diabetes", "Hypertension"]
    allergies: List[str] = []            # ["Gluten", "Nuts", "Lactose"]
    diet_type: Optional[str] = None      # vegetarian | vegan | keto | none


class HealthProfileResponse(HealthProfileCreate):
    user_id: UUID
    updated_at: datetime


# ── Chat ──────────────────────────────────────────────────────────────────────

class MessageRole(str, Enum):
    user = "user"
    assistant = "assistant"


class ChatMessage(BaseModel):
    role: MessageRole
    content: str
    image_url: Optional[str] = None
    timestamp: Optional[datetime] = None


class ChatRequest(BaseModel):
    session_id: Optional[str] = None   # None = new session
    message: str
    image_url: Optional[str] = None    # Supabase Storage public URL


class ChatResponse(BaseModel):
    session_id: str
    session_title: str
    reply: str
    message_id: str


# ── Compare ───────────────────────────────────────────────────────────────────

class ProductInput(BaseModel):
    name: str
    image_url: str


class CompareRequest(BaseModel):
    products: List[ProductInput] = Field(min_length=2, max_length=5)


class CompareResponse(BaseModel):
    comparison_text: str
    winner: Optional[str] = None
    session_id: str


# ── History ───────────────────────────────────────────────────────────────────

class ConversationSummary(BaseModel):
    session_id: str
    title: str
    created_at: datetime
    message_count: int
    last_message_at: datetime


class ConversationDetail(BaseModel):
    session_id: str
    title: str
    messages: List[ChatMessage]
