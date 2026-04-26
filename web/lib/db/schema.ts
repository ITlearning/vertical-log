import {
  pgTable,
  text,
  uuid,
  timestamp,
  integer,
  primaryKey,
  index,
  uniqueIndex,
  pgEnum,
} from 'drizzle-orm/pg-core';

// ============================================================
// Enums
// ============================================================

export const compileStatusEnum = pgEnum('compile_status', [
  'pending',
  'processing',
  'ready',
  'failed',
]);

export const memberRoleEnum = pgEnum('member_role', ['owner', 'member']);

// ============================================================
// users
// ============================================================

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    appleUserId: text('apple_user_id').notNull(),
    displayName: text('display_name').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [uniqueIndex('users_apple_user_id_idx').on(t.appleUserId)]
);

// ============================================================
// rooms
// ============================================================

export const rooms = pgTable(
  'rooms',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: text('name').notNull(),
    ownerId: uuid('owner_id')
      .notNull()
      .references(() => users.id),
    inviteCode: text('invite_code').notNull(),
    memberCap: integer('member_cap').notNull().default(12),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('rooms_invite_code_idx').on(t.inviteCode)]
);

// ============================================================
// room_members (many-to-many junction)
// ============================================================

export const roomMembers = pgTable(
  'room_members',
  {
    roomId: uuid('room_id')
      .notNull()
      .references(() => rooms.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    role: memberRoleEnum('role').notNull().default('member'),
    joinedAt: timestamp('joined_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    primaryKey({ columns: [t.roomId, t.userId] }),
    index('room_members_user_idx').on(t.userId),
  ]
);

// ============================================================
// clips
// ============================================================

export const clips = pgTable(
  'clips',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    roomId: uuid('room_id')
      .notNull()
      .references(() => rooms.id, { onDelete: 'cascade' }),
    authorId: uuid('author_id')
      .notNull()
      .references(() => users.id),
    blobUrl: text('blob_url').notNull(),
    durationMs: integer('duration_ms').notNull(),
    capturedAt: timestamp('captured_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('clips_room_captured_idx').on(t.roomId, t.capturedAt)]
);

// ============================================================
// reactions (emoji on clips)
// ============================================================

export const reactions = pgTable(
  'reactions',
  {
    clipId: uuid('clip_id')
      .notNull()
      .references(() => clips.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    emoji: text('emoji').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.clipId, t.userId, t.emoji] })]
);

// ============================================================
// compiles (daily vlog: long + CAGL share-ready)
// ============================================================

export const compiles = pgTable(
  'compiles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    roomId: uuid('room_id')
      .notNull()
      .references(() => rooms.id, { onDelete: 'cascade' }),
    date: timestamp('date', { mode: 'date' }).notNull(),
    longUrl: text('long_url'),
    shareReadyUrl: text('share_ready_url'),
    status: compileStatusEnum('status').notNull().default('pending'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('compiles_room_date_idx').on(t.roomId, t.date)]
);

// ============================================================
// messages (Sprint 3 chat)
// ============================================================

export const messages = pgTable(
  'messages',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    roomId: uuid('room_id')
      .notNull()
      .references(() => rooms.id, { onDelete: 'cascade' }),
    senderId: uuid('sender_id')
      .notNull()
      .references(() => users.id),
    clipId: uuid('clip_id').references(() => clips.id, { onDelete: 'set null' }),
    body: text('body'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('messages_room_created_idx').on(t.roomId, t.createdAt)]
);

// ============================================================
// Type inference helpers
// ============================================================

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;

export type Room = typeof rooms.$inferSelect;
export type NewRoom = typeof rooms.$inferInsert;

export type RoomMember = typeof roomMembers.$inferSelect;
export type NewRoomMember = typeof roomMembers.$inferInsert;

export type Clip = typeof clips.$inferSelect;
export type NewClip = typeof clips.$inferInsert;

export type Reaction = typeof reactions.$inferSelect;

export type DailyCompile = typeof compiles.$inferSelect;
export type NewDailyCompile = typeof compiles.$inferInsert;

export type Message = typeof messages.$inferSelect;
export type NewMessage = typeof messages.$inferInsert;
