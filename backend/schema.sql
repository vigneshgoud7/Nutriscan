-- =============================================================
-- NutriScan Database Schema
-- Run this entire file in the Supabase SQL Editor
--
-- IMPORTANT: If you get "column does not exist" or any other
-- error, it means a previous partial run left broken tables.
-- This script drops everything first so it always runs clean.
-- =============================================================

-- Drop everything in reverse dependency order (safe re-run)
DROP TRIGGER  IF EXISTS profiles_updated_at  ON health_profiles;
DROP TRIGGER  IF EXISTS users_updated_at     ON users;
DROP FUNCTION IF EXISTS update_updated_at();
DROP POLICY   IF EXISTS "messages_self"      ON messages;
DROP POLICY   IF EXISTS "conversations_self" ON conversations;
DROP POLICY   IF EXISTS "profiles_self"      ON health_profiles;
DROP POLICY   IF EXISTS "users_self"         ON users;
DROP TABLE    IF EXISTS messages        CASCADE;
DROP TABLE    IF EXISTS conversations   CASCADE;
DROP TABLE    IF EXISTS health_profiles CASCADE;
DROP TABLE    IF EXISTS users           CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Users ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id          UUID PRIMARY KEY,          -- matches Supabase auth.users.id
    email       TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL DEFAULT '',
    plan        TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'premium')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Health Profiles ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS health_profiles (
    user_id     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    age         INT,
    sex         TEXT,
    weight_kg   NUMERIC(5,2),
    height_cm   NUMERIC(5,2),
    goal        TEXT,
    diseases    TEXT[]  NOT NULL DEFAULT '{}',
    allergies   TEXT[]  NOT NULL DEFAULT '{}',
    diet_type   TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Conversations ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conversations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL DEFAULT 'New conversation',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Messages ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id  UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role        TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content     TEXT NOT NULL,
    image_url   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Indexes ────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_session_id   ON messages(session_id);
CREATE INDEX IF NOT EXISTS idx_messages_user_created ON messages(user_id, created_at DESC);

-- ── Row Level Security ─────────────────────────────────────────
ALTER TABLE users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations      ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages           ENABLE ROW LEVEL SECURITY;

-- Users: only the owner can read/write their row
CREATE POLICY "users_self" ON users
    FOR ALL USING (auth.uid() = id);

-- Health profiles: owner only
CREATE POLICY "profiles_self" ON health_profiles
    FOR ALL USING (auth.uid() = user_id);

-- Conversations: owner only
CREATE POLICY "conversations_self" ON conversations
    FOR ALL USING (auth.uid() = user_id);

-- Messages: owner only
CREATE POLICY "messages_self" ON messages
    FOR ALL USING (auth.uid() = user_id);

-- Service role bypasses RLS (used by FastAPI backend)
-- The service role key in .env grants full access regardless of RLS.

-- ── Supabase Storage bucket for food images ────────────────────
-- Run this separately in Supabase Dashboard → Storage → New bucket
-- Name: food-images | Public: true | File size limit: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/webp

-- ── Auto-update updated_at ─────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON health_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();