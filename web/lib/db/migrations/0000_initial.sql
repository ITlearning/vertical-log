-- vertical-log initial schema
-- Generated to match web/lib/db/schema.ts. Run via `npm run db:push`
-- (drizzle-kit push) which will create or sync the schema. This file is
-- a hand-authored reference; drizzle-kit may regenerate it on first run.

-- Enums --------------------------------------------------------------

DO $$ BEGIN
  CREATE TYPE "compile_status" AS ENUM ('pending', 'processing', 'ready', 'failed');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE "member_role" AS ENUM ('owner', 'member');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Tables -------------------------------------------------------------

CREATE TABLE IF NOT EXISTS "users" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "apple_user_id" text NOT NULL,
  "display_name" text NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "deleted_at" timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS "users_apple_user_id_idx" ON "users" ("apple_user_id");

CREATE TABLE IF NOT EXISTS "rooms" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  "owner_id" uuid NOT NULL REFERENCES "users"("id"),
  "invite_code" text NOT NULL,
  "member_cap" integer NOT NULL DEFAULT 12,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "rooms_invite_code_idx" ON "rooms" ("invite_code");

CREATE TABLE IF NOT EXISTS "room_members" (
  "room_id" uuid NOT NULL REFERENCES "rooms"("id") ON DELETE CASCADE,
  "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "role" "member_role" NOT NULL DEFAULT 'member',
  "joined_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("room_id", "user_id")
);
CREATE INDEX IF NOT EXISTS "room_members_user_idx" ON "room_members" ("user_id");

CREATE TABLE IF NOT EXISTS "clips" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "room_id" uuid NOT NULL REFERENCES "rooms"("id") ON DELETE CASCADE,
  "author_id" uuid NOT NULL REFERENCES "users"("id"),
  "blob_url" text NOT NULL,
  "duration_ms" integer NOT NULL,
  "captured_at" timestamptz NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "clips_room_captured_idx" ON "clips" ("room_id", "captured_at");

CREATE TABLE IF NOT EXISTS "reactions" (
  "clip_id" uuid NOT NULL REFERENCES "clips"("id") ON DELETE CASCADE,
  "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "emoji" text NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("clip_id", "user_id", "emoji")
);

CREATE TABLE IF NOT EXISTS "compiles" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "room_id" uuid NOT NULL REFERENCES "rooms"("id") ON DELETE CASCADE,
  "date" date NOT NULL,
  "long_url" text,
  "share_ready_url" text,
  "status" "compile_status" NOT NULL DEFAULT 'pending',
  "created_at" timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "compiles_room_date_idx" ON "compiles" ("room_id", "date");

CREATE TABLE IF NOT EXISTS "messages" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "room_id" uuid NOT NULL REFERENCES "rooms"("id") ON DELETE CASCADE,
  "sender_id" uuid NOT NULL REFERENCES "users"("id"),
  "clip_id" uuid REFERENCES "clips"("id") ON DELETE SET NULL,
  "body" text,
  "created_at" timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "messages_room_created_idx" ON "messages" ("room_id", "created_at");
