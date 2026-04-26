import { NextResponse } from 'next/server';
import { z } from 'zod';
import { eq, desc, count } from 'drizzle-orm';
import { db, rooms, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';
import { generateUniqueInviteCode } from '@/lib/db/utils/inviteCode';

const CreateRoomBody = z.object({
  name: z.string().min(1).max(64),
});

/**
 * GET /api/rooms — rooms the authenticated user is a member of (snake_case keys).
 */
export async function GET(req: Request) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  const result = await db
    .select({
      id: rooms.id,
      name: rooms.name,
      invite_code: rooms.inviteCode,
      member_cap: rooms.memberCap,
      created_at: rooms.createdAt,
      member_count: count(roomMembers.userId),
    })
    .from(rooms)
    .innerJoin(roomMembers, eq(roomMembers.roomId, rooms.id))
    .where(eq(roomMembers.userId, userId))
    .groupBy(rooms.id)
    .orderBy(desc(rooms.createdAt));

  return NextResponse.json({ rooms: result });
}

/**
 * POST /api/rooms { name } — create a room with the authenticated user as owner.
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
      invite_code: room.inviteCode,
      member_cap: room.memberCap,
      member_count: 1,
      created_at: room.createdAt,
    },
    { status: 201 }
  );
}
