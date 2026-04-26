import { NextResponse } from 'next/server';
import { eq, and, count } from 'drizzle-orm';
import { db, rooms, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';
import { INVITE_CODE_LENGTH } from '@/lib/db/utils/inviteCode';

/**
 * POST /api/rooms/:code/join
 *
 * Idempotent: re-joining an already-member room returns 200 (not 409).
 * Returns 410 if invite code expired (NOT IMPLEMENTED — V1+ feature).
 * Returns 409 if room is at member_cap.
 */
export async function POST(
  req: Request,
  ctx: { params: Promise<{ code: string }> }
) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  const { code: rawCode } = await ctx.params;
  const code = rawCode.toUpperCase();

  if (code.length !== INVITE_CODE_LENGTH) {
    return NextResponse.json(
      { error: 'invalid_code_length', expected: INVITE_CODE_LENGTH },
      { status: 400 }
    );
  }

  // Look up room
  const [room] = await db
    .select()
    .from(rooms)
    .where(eq(rooms.inviteCode, code))
    .limit(1);

  if (!room) {
    return NextResponse.json({ error: 'not_found' }, { status: 404 });
  }

  // Already a member? 200 idempotent
  const [existingMembership] = await db
    .select()
    .from(roomMembers)
    .where(and(eq(roomMembers.roomId, room.id), eq(roomMembers.userId, userId)))
    .limit(1);

  if (existingMembership) {
    const [{ value: memberCount }] = await db
      .select({ value: count() })
      .from(roomMembers)
      .where(eq(roomMembers.roomId, room.id));
    return NextResponse.json(
      {
        roomId: room.id,
        name: room.name,
        memberCount,
        alreadyMember: true,
      },
      { status: 200 }
    );
  }

  // Cap check
  const [{ value: currentCount }] = await db
    .select({ value: count() })
    .from(roomMembers)
    .where(eq(roomMembers.roomId, room.id));

  if (currentCount >= room.memberCap) {
    return NextResponse.json(
      { error: 'room_full', memberCount: currentCount, memberCap: room.memberCap },
      { status: 409 }
    );
  }

  // Insert membership
  await db.insert(roomMembers).values({
    roomId: room.id,
    userId,
    role: 'member',
  });

  return NextResponse.json(
    {
      roomId: room.id,
      name: room.name,
      memberCount: currentCount + 1,
      alreadyMember: false,
    },
    { status: 201 }
  );
}
