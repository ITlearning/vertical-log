import { NextResponse } from 'next/server';
import { z } from 'zod';
import { eq, and, desc, count } from 'drizzle-orm';
import { db, rooms, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';
import { generateUniqueInviteCode } from '@/lib/db/utils/inviteCode';

const CreateRoomBody = z.object({
  name: z.string().min(1).max(64),
});

/**
 * GET /api/rooms
 * Returns the rooms the authenticated user is a member of, with member counts.
 */
export async function GET(req: Request) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  const result = await db
    .select({
      id: rooms.id,
      name: rooms.name,
      inviteCode: rooms.inviteCode,
      memberCap: rooms.memberCap,
      createdAt: rooms.createdAt,
      memberCount: count(roomMembers.userId),
    })
    .from(rooms)
    .innerJoin(roomMembers, eq(roomMembers.roomId, rooms.id))
    .where(eq(roomMembers.userId, userId))
    .groupBy(rooms.id)
    .orderBy(desc(rooms.createdAt));

  return NextResponse.json({ rooms: result });
}

/**
 * POST /api/rooms
 * Create a new room with the authenticated user as owner. Generates a unique
 * 6-char invite code (with retry on collision).
 */
export async function POST(req: Request) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  let body: z.infer<typeof CreateRoomBody>;
  try {
    body = CreateRoomBody.parse(await req.json());
  } catch (error) {
    return NextResponse.json(
      { error: 'invalid_request', message: error instanceof Error ? error.message : 'invalid' },
      { status: 400 }
    );
  }

  const inviteCode = await generateUniqueInviteCode(async (code) => {
    const conflict = await db
      .select({ id: rooms.id })
      .from(rooms)
      .where(eq(rooms.inviteCode, code))
      .limit(1);
    return conflict.length === 0;
  });

  // Two-statement transaction: insert room, then add owner as member.
  // Drizzle's postgres-js driver supports db.transaction(tx => ...).
  const [room] = await db.transaction(async (tx) => {
    const inserted = await tx
      .insert(rooms)
      .values({ name: body.name, ownerId: userId, inviteCode })
      .returning();
    await tx.insert(roomMembers).values({
      roomId: inserted[0].id,
      userId,
      role: 'owner',
    });
    return inserted;
  });

  return NextResponse.json(
    {
      id: room.id,
      name: room.name,
      inviteCode: room.inviteCode,
      memberCap: room.memberCap,
      memberCount: 1,
      createdAt: room.createdAt,
    },
    { status: 201 }
  );
}
