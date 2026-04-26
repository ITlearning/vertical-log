import { NextResponse } from 'next/server';
import { z } from 'zod';
import { eq, and, count } from 'drizzle-orm';
import { db, rooms, roomMembers } from '@/lib/db';
import { authOr401 } from '@/lib/auth/session';
import { INVITE_CODE_LENGTH } from '@/lib/db/utils/inviteCode';

const JoinBody = z.object({
  code: z.string().min(1).max(32),
});

/**
 * POST /api/rooms/join { code: "ABC234" }
 *
 * Body-parameter form (originally /:code/join, but Next 16 forbids sibling
 * dynamic segment names under app/api/rooms/, so the code moved into the body).
 *
 * Idempotent: re-joining an already-member room returns 200.
 * Returns 404 if not found, 409 if room at member_cap.
 */
export async function POST(req: Request) {
  const guard = await authOr401(req);
  if (guard instanceof NextResponse) return guard;
  const { userId } = guard;

  let body: z.infer<typeof JoinBody>;
  try {
    body = JoinBody.parse(await req.json());
  } catch (error) {
    return NextResponse.json(
      { error: 'invalid_request', message: error instanceof Error ? error.message : 'invalid' },
      { status: 400 }
    );
  }

  const code = body.code.toUpperCase();
  if (code.length !== INVITE_CODE_LENGTH) {
    return NextResponse.json(
      { error: 'invalid_code_length', expected: INVITE_CODE_LENGTH },
      { status: 400 }
    );
  }

  const [room] = await db
    .select()
    .from(rooms)
    .where(eq(rooms.inviteCode, code))
    .limit(1);

  if (!room) {
    return NextResponse.json({ error: 'not_found' }, { status: 404 });
  }

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
